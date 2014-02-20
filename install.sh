#! /bin/bash

echo 'Installing Immobileaks SDK'

_USER=imbk
_BASE=/home/$_USER;

# ################################################### #
# Creating user
# ################################################### #

echo Creating unix user $_USER
sudo adduser --disabled-password --gecos ',,,,' $_USER || {
  echo Could not create unix user
  exit
}
echo Setting unix user password
sudo passwd $_USER || {
  echo Could not set unix user password
  exit
}

# ################################################### #
# Installing git
# ################################################### #

read -p 'Please enter your github username: ' github_user
read -p 'Please enter your github email address: ' github_email

if [ -z "$github_user" ]; then
  echo 'Missing github username';
  exit
fi

if [ -z "$github_email" ]; then
  echo 'Missing github email';
  exit
fi

echo 'Installing latest git'

sudo add-apt-repository ppa:git-core/ppa || {
  echo 'Could not add git ppa';
  exit
}
sudo apt-get update || {
  echo 'Could not update apt'
  exit
}
sudo apt-get install git || {
  echo 'Could not install git'
  exit
}

# ################################################### #
# Creating folders
# ################################################### #

echo 'Creating imbk bin folder';

sudo mkdir $_BASE/bin || {
  echo Could not create imbk/bin folder;
  exit 3
}

# create lib directory

echo 'Creating lib directory'

sudo mkdir $_BASE/lib || {
  echo Could not create lib folder
  exit
}

# create var directory

echo 'Creating var directory'

sudo mkdir $_BASE/var || {
  echo Could not create var directory
  exit
}

# create data directory

echo 'Creating data directory'

sudo mkdir $_BASE/var/data || {
  echo Could not create data directory
  exit
}

# create agent data directory

echo 'Creating agent data directory'

sudo mkdir $_BASE/var/data/agent || {
  echo COuld not create agent data directory
  exit
}

# apps directory

echo 'Creating apps directory'

sudo mkdir $_BASE/apps || {
  echo Could not create apps directory
  exit
}

# ################################################### #
# Installing mongodb
# ################################################### #

echo 'Installing mongodb'

cd $_BASE/lib || {
  echo Could not cd lib
  exit
}

sudo wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.9.tgz || {
  echo Could not download mongodb
  exit
}

echo 'Uncompressing mongodb'

sudo tar -xzf mongodb-linux-x86_64-2.4.9.tgz || {
  echo Could not uncompress mongodb
  exit
}
sudo ln -s $_BASE/lib/mongodb-linux-x86_64-2.4.9/bin/mongo $_BASE/bin/mongo || {
  echo Could not create mongo daemon shortcut
  exit
}
sudo ln -s $_BASE/lib/mongodb-linux-x86_64-2.4.9/bin/mongod $_BASE/bin/mongod || {
  echo Could not create mongo shell shortcut
  exit
}

sudo touch /tmp/immomongo

sudo $_BASE/bin/mongod --dbpath $_BASE/var/data/agent 1>/tmp/immomongo 2>/tmp/immomongo &
echo 'Waiting for mongodb to be up'

mongod_started='no'
loopx=$((0))

while [ "$mongod_started" = no ]; do
  grep 2>/dev/null 1>/dev/null 'waiting for connections on port 27017' /tmp/immomongo && {
    echo mongodb is up
    mongod_started=yes
  } || {
    echo mongodb not up yet
    (( loopx ++ ))
    if [ $loopx -gt 50 ]; then
      echo 'Could not start mongod'
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
  echo Could not connect to mongo
  exit
fi

# ################################################### #
# Installing MySQL
# ################################################### #

echo 'Installing MySQL'

cd $_BASE/lib

sudo wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.15-debian6.0-x86_64.deb -O mysql-5.6.15-debian6.0-x86_64.deb || {
  echo Could not download MySQL
  exit
}
sudo dpkg -i  mysql-5.6.15-debian6.0-x86_64.deb || {
  echo Could not install MySQL
  exit
}

# ################################################### #
# Installing node
# ################################################### #

echo 'Installing nvm';

cd $_BASE/lib

sudo git clone https://github.com/creationix/nvm || {
  echo Could not download nvm
  exit
}
. $_BASE/lib/nvm/nvm.sh || {
  echo Could not source nvm
  exit
}

echo 'Installling node';

nvm install v0.10.25 || {
  echo Could not install node
  exit
}

nvm use v0.10.25 || {
  echo Could not use node
  exit
}

echo 'Creating node shortcuts'

sudo ln -s $_BASE/lib/nvm/v0.10.25/bin/node $_BASE/bin/node || {
  echo 'Could not create node shortcut'
  exit
}
sudo ln -s $_BASE/lib/nvm/v0.10.25/bin/npm $_BASE/bin/npm || {
  echo Could not create npm shortcut
  exit
}

# Installing node modules

echo 'Creating package.json'

cat <<DOC > $_BASE/package.json
{
  "name": "imbk",
  "version": "0.0.0",
  "description": "",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "BSD",
  "dependencies": {
    "express": "~3.4.7",
    "bower": "~1.2.8"
  }
}
DOC

echo 'Installing node modules';

cd $_BASE

$_BASE/bin/npm install || {
  echo Could not install node modules
  exit
}



# ################################################### #
# Installing agent
# ################################################### #

echo 'Installing agent';

cd $_BASE/apps

git clone https://$github_user@github.com/$github_user/imbk-agent agent || {
  echo Could not clone agent
  exit
}

cd $_BASE/apps/agent || {
  echo Could not cd to agent
  exit
}

git remote add upstream https://$github_user@github.com/xvespa/imbk-agent || {
  echo Could not add agent upstream
  exit
}
git config user.name $github_user || {
  echo Could not configure github user name
  exit
}
git config user.email $github_email || {
  echo COuld not configure github email
  exit
}

# Install agent dependencies

echo 'Installing agent node dependencies';

$_BASE/bin/npm install

# ################################################### #
# Installing API
# ################################################### #

echo 'Installing API';

cd $_BASE/apps

git clone https://$github_user@github.com/$github_user/imbk-api api

cd $_BASE/apps/api

git remote add upstream https://$github_user@github.com/xvespa/imbk-api
git config user.name $github_user
git config user.email $github_email

# Install api dependencies

echo 'Installing API node dependencies';

$_BASE/bin/npm install

echo 'Installing modules';

cd $_BASE/apps

# ################################################### #
# Installing modules
# ################################################### #

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
