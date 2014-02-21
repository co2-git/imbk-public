#! /bin/bash

function printm () {
  echo '##################################################'
  echo
  echo "$@"
  echo
  echo '##################################################'
}

function printe () {
  echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  echo
  echo "$@"
  echo
  echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
}

printm 'Installing Immobileaks SDK'

printm Installing low-level dependencies

sudo apt-get install curl  libcurl4-openssl-dev

_USER=imbk
_BASE=/home/$_USER;

# ################################################### #
# Creating user
# ################################################### #

printm Creating unix user $_USER

sudo adduser --disabled-password --gecos ',,,,' $_USER || {
  printe Could not create unix user
  exit
}

printm Setting unix user password

sudo passwd $_USER || {
  printe Could not set unix user password
  exit
}

# ################################################### #
# Installing git
# ################################################### #

read -p 'Please enter your github username: ' github_user
read -p 'Please enter your github email address: ' github_email

if [ -z "$github_user" ]; then
  printe 'Missing github username';
  exit
fi

if [ -z "$github_email" ]; then
  printe 'Missing github email';
  exit
fi

printm 'Installing latest git'

sudo add-apt-repository ppa:git-core/ppa || {
  printe 'Could not add git ppa';
  exit
}

sudo apt-get update || {
  printe 'Could not update apt'
  exit
}
sudo apt-get install git || {
  printe 'Could not install git'
  exit
}

# ################################################### #
# Creating folders
# ################################################### #

printm 'Creating imbk bin folder';

sudo su imbk -c "mkdir ~/bin" || {
  printe Could not create imbk/bin folder;
  exit 3
}

# create lib directory

printm 'Creating lib directory'

sudo su imbk -c "mkdir ~/lib" || {
  printe Could not create lib folder
  exit
}

# create var directory

printm 'Creating var directory'

sudo su imbk -c "mkdir ~/var" || {
  printe Could not create var directory
  exit
}

# create data directory

printm 'Creating data directory'

sudo su imbk -c "mkdir ~/data" || {
  printe Could not create data directory
  exit
}

# create agent data directory

printm 'Creating agent data directory'

sudo su imbk -c "mkdir ~/var/data/agent" || {
  printe COuld not create agent data directory
  exit
}

# apps directory

printm 'Creating apps directory'

sudo su imbk -c "mkdir ~/apps" || {
  printe Could not create apps directory
  exit
}

exit

# ################################################### #
# Installing mongodb
# ################################################### #

printm 'Installing mongodb'

cd $_BASE/lib || {
  printe Could not cd lib
  exit
}

sudo wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.9.tgz || {
  printe Could not download mongodb
  exit
}

printm 'Uncompressing mongodb'

sudo tar -xzf mongodb-linux-x86_64-2.4.9.tgz || {
  printe Could not uncompress mongodb
  exit
}

sudo ln -s $_BASE/lib/mongodb-linux-x86_64-2.4.9/bin/mongo $_BASE/bin/mongo || {
  printe Could not create mongo daemon shortcut
  exit
}

sudo ln -s $_BASE/lib/mongodb-linux-x86_64-2.4.9/bin/mongod $_BASE/bin/mongod || {
  printe Could not create mongo shell shortcut
  exit
}

touch /tmp/immomongo

sudo $_BASE/bin/mongod --dbpath $_BASE/var/data/agent 1>/tmp/immomongo 2>/tmp/immomongo &

printm 'Waiting for mongodb to be up'

mongod_started='no'
loopx=$((0))

while [ "$mongod_started" = no ]; do
  grep 2>/dev/null 1>/dev/null 'waiting for connections on port 27017' /tmp/immomongo && {
    printm mongodb is up
    
    mongod_started=yes
  } || {
    echo mongodb not up yet
    
    (( loopx ++ ))
    
    if [ $loopx -gt 50 ]; then
      printe 'Could not start mongod'
      exit
    else
      sleep 1
    fi
  }
done

sudo $_BASE/bin/mongo << MONGO
use agent;
db.services.insert({ "service": "Agent" });
db.services.insert({ "service": "API" });
db.services.insert({ "service": "Dashboard" });
db.services.insert({ "service": "App" });
MONGO

if [ $? -ne 0 ]; then
  printe Could not connect to mongo
  exit
fi

# ################################################### #
# Installing MySQL
# ################################################### #

printm 'Installing MySQL'

cd $_BASE/lib

sudo wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.15-debian6.0-x86_64.deb -O mysql-5.6.15-debian6.0-x86_64.deb || {
  printe Could not download MySQL
  exit
}
sudo dpkg -i  mysql-5.6.15-debian6.0-x86_64.deb || {
  printe Could not install MySQL
  exit
}

# ################################################### #
# Installing node
# ################################################### #

printm 'Installing nvm';

cd $_BASE/lib

sudo git clone https://github.com/creationix/nvm || {
  printe Could not download nvm
  exit
}

source $_BASE/lib/nvm/nvm.sh || {
  printe Could not source nvm
  exit
}

printm 'Installling node';

sudo nvm install v0.10.25 || {
  printe Could not install node
  exit
}

sudo nvm use v0.10.25 || {
  printe Could not use node
  exit
}

printm 'Creating node shortcuts'

sudo ln -s $_BASE/lib/nvm/v0.10.25/bin/node $_BASE/bin/node || {
  printe 'Could not create node shortcut'
  exit
}
sudo ln -s $_BASE/lib/nvm/v0.10.25/bin/npm $_BASE/bin/npm || {
  printe Could not create npm shortcut
  exit
}

# Installing node modules

# echo 'Creating package.json'

# cat <<DOC > $_BASE/package.json
# {
#   "name": "imbk",
#   "version": "0.0.0",
#   "description": "",
#   "scripts": {
#     "test": "echo \"Error: no test specified\" && exit 1"
#   },
#   "author": "",
#   "license": "BSD",
#   "dependencies": {
#     "express": "~3.4.7",
#     "bower": "~1.2.8"
#   }
# }
# DOC

# echo 'Installing node modules';

# cd $_BASE

# $_BASE/bin/npm install || {
#   echo Could not install node modules
#   exit
# }



# ################################################### #
# Installing agent
# ################################################### #

printm 'Installing agent';

cd $_BASE/apps

sudo git clone https://$github_user@github.com/$github_user/imbk-agent agent || {
  printe Could not clone agent
  exit
}

cd $_BASE/apps/agent || {
  printe Could not cd to agent
  exit
}

sudo git remote add upstream https://$github_user@github.com/xvespa/imbk-agent || {
  printe Could not add agent upstream
  exit
}

sudo git config user.name $github_user || {
  printe Could not configure github user name
  exit
}

sudo git config user.email $github_email || {
  printe COuld not configure github email
  exit
}

# Install agent dependencies

printm 'Installing agent node dependencies';

sudo $_BASE/bin/npm install

# ################################################### #
# Installing API
# ################################################### #

printm 'Installing API';

cd $_BASE/apps

sudo git clone https://$github_user@github.com/$github_user/imbk-api api

cd $_BASE/apps/api

sudo git remote add upstream https://$github_user@github.com/xvespa/imbk-api
sudo git config user.name $github_user
sudo git config user.email $github_email

# Install api dependencies

echo 'Installing API node dependencies';

sudo $_BASE/bin/npm install

# ################################################### #
# Installing modules
# ################################################### #

echo 'Installing modules';

cd $_BASE/apps

git clone https://$github_user@github.com/$github_user/imbk-modules modules

cd $_BASE/apps/modules

git remote add upstream https://$github_user@github.com/xvespa/imbk-modules
git config user.name $github_user
git config user.email $github_email

# Install mdoules dependencies

echo 'Installing Modules bower dependencies'

cd $_BASE/apps/modules

$_BASE/bin/node $_BASE/node_modules/.bin/bower install

# ################################################### #
# Installing App
# ################################################### #

echo 'Installing App';

cd $_BASE/apps

git clone https://$github_user@github.com/$github_user/imbk-app app

cd $_BASE/apps/app

git remote add upstream https://$github_user@github.com/xvespa/imbk-app
git config user.name $github_user
git config user.email $github_email

# Install app dependencies

echo 'Installing App node dependencies';

$_BASE/bin/npm install

echo 'Installing App bower dependencies'

cd $_BASE/apps/app/public

$_BASE/bin/node $_BASE/node_modules/.bin/bower install

ln -s $_BASE/apps/modules $_BASE/apps/app/public/bower_components/imbk_modules

# ################################################### #
# Installing Dashboard
# ################################################### #

echo 'Installing Dashboard';

cd $_BASE/apps

git clone https://$github_user@github.com/$github_user/imbk-dashboard dashboard

cd $_BASE/apps/dashboard

git remote add upstream https://$github_user@github.com/xvespa/imbk-dashboard
git config user.name $github_user
git config user.email $github_email

# Install dashboard dependencies

echo 'Installing Dashboard node dependencies';

$_BASE/bin/npm install

echo 'Installing Dashboard bower dependencies'

cd $_BASE/apps/dashboard/public

$_BASE/bin/node $_BASE/node_modules/.bin/bower install

ln -s $_BASE/apps/modules $_BASE/apps/dashboard/public/bower_components/imbk_modules

# ################################################### #
# Closing
# ################################################### #

# Copy start.sh to bin

cd $_BASE/bin
ln -s ../apps/agent/start.sh start

echo 'closing mongodb'

$_BASE/bin/mongod --dbpath $_BASE/var/data/agent --shutdown

# ################################################### #
# Starting
# ################################################### #

echo 'Starting ecosystem';

$_BASE/bin/start || {
  echo Could not start ecosystem
  exit
}
