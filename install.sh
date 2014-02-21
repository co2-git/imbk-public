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

sudo apt-get install curl libcurl4-openssl-dev g++

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

sudo su imbk -c "mkdir ~/var/data" || {
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

# ################################################### #
# Installing mongodb
# ################################################### #

printm 'Installing mongodb'

cd $_BASE/lib || {
  printe Could not cd lib
  exit
}

sudo su imbk -c 'wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.9.tgz' || {
  printe Could not download mongodb
  exit
}

printm 'Uncompressing mongodb'

sudo su imbk -c 'tar -xzf mongodb-linux-x86_64-2.4.9.tgz' || {
  printe Could not uncompress mongodb
  exit
}

sudo su imbk -c "ln -s ~/lib/mongodb-linux-x86_64-2.4.9/bin/mongo ~/bin/mongo" || {
  printe Could not create mongo daemon shortcut
  exit
}

sudo su imbk -c "ln -s ~/lib/mongodb-linux-x86_64-2.4.9/bin/mongod ~/bin/mongod" || {
  printe Could not create mongo shell shortcut
  exit
}

sudo su imbk -c 'touch /tmp/immomongo'

sudo su imbk -c "~/bin/mongod --dbpath ~/var/data/agent 1>/tmp/immomongo 2>/tmp/immomongo" &

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

sudo su imbk -c 'wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.15-debian6.0-x86_64.deb -O mysql-5.6.15-debian6.0-x86_64.deb' || {
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

sudo su imbk -c 'git clone https://github.com/creationix/nvm' || {
  printe Could not download nvm
  exit
}

printm 'Installling node';

sudo su imbk -c 'source ~/lib/nvm/nvm.sh; nvm install v0.10.25' || {
  printe Could not install node
  exit
}

# sudo su imbk -c nvm use v0.10.25 || {
#   printe Could not use node
#   exit
# }

printm 'Creating node shortcuts'

sudo su imbk -c "ln -s ~/lib/nvm/v0.10.25/bin/node ~/bin/node" || {
  printe 'Could not create node shortcut'
  exit
}

sudo su imbk -c "ln -s ~/lib/nvm/v0.10.25/bin/npm ~/bin/npm" || {
  printe Could not create npm shortcut
  exit
}

# Installing node modules

printm 'Creating package.json'

sudo su imbk -c 'touch ~/package.json'

sudo su imbk -c 'echo \{\"name\":\"imbk\",\"version\":\"0.0.0\",\"description\":\"\",\"author\":\"\",\"license\":\"BSD\",\"dependencies\":\{\"express\":\"~3.4.7\",\"bower\":\"~1.2.8\"\}\} > ~/package.json'

printm 'Installing node modules';

sudo su imbk -c 'cd ~; ~/bin/npm install' || {
  echo Could not install node modules
  exit
}

# ################################################### #
# Installing agent
# ################################################### #

printm 'Installing agent';


sudo git clone https://$github_user@github.com/$github_user/imbk-agent /home/imbk/apps/agent || {
  printe Could not clone agent
  exit
}

sudo chown -R imbk /home/imbk/apps/agent

sudo su imbk -c "cd ~/apps/agent; git remote add upstream https://$github_user@github.com/xvespa/imbk-agent" || {
  printe Could not add agent upstream
  exit
}

sudo su imbk -c "cd ~/apps/agent; git config user.name $github_user" || {
  printe Could not configure github user name
  exit
}

sudo su imbk -c "cd ~/apps/agent; git config user.email $github_email" || {
  printe COuld not configure github email
  exit
}

# Install agent dependencies

printm 'Installing agent node dependencies';

sudo su imbk -c 'cd ~/apps/agent; ~/bin/npm install' || {
  printe Could not install agent node dependencies
  exit
}

# ################################################### #
# Installing API
# ################################################### #

printm 'Installing API';

sudo git clone https://$github_user@github.com/$github_user/imbk-api /home/imbk/apps/api

sudo chown -R imbk /home/imbk/apps/api

sudo su imbk -c "cd ~/apps/api; git remote add upstream https://$github_user@github.com/xvespa/imbk-api" || {
  printe Could not add api upstream
  exit
}

sudo su imbk -c "cd ~/apps/api; git config user.name $github_user" || {
  printe Could not configure github user name
  exit
}

sudo su imbk -c "cd ~/apps/api; git config user.email $github_email" || {
  printe COuld not configure github email
  exit
}

# Install api dependencies

printm 'Installing API node dependencies';

sudo su imbk -c 'cd ~/apps/api; ~/bin/npm install' || {
  printe Could not install api node dependencies
  exit
}

# ################################################### #
# Installing modules
# ################################################### #

printm 'Installing modules';

sudo git clone https://$github_user@github.com/$github_user/imbk-modules /home/imbk/apps/modules

sudo chown -R imbk /home/imbk/apps/modules

sudo su imbk -c "cd ~/apps/modules; git remote add upstream https://$github_user@github.com/xvespa/imbk-modules" || {
  printe Could not add modules upstream
  exit
}

sudo su imbk -c "cd ~/apps/modules; git config user.name $github_user" || {
  printe Could not configure github user name
  exit
}

sudo su imbk -c "cd ~/apps/modules; git config user.email $github_email" || {
  printe COuld not configure github email
  exit
}

# Install modules dependencies

printm 'Installing Modules bower dependencies'

sudo su imbk -c "cd ~/apps/modules; ~/bin/node ~/node_modules/.bin/bower install"

# ################################################### #
# Installing App
# ################################################### #

printm 'Installing App';

sudo git clone https://$github_user@github.com/$github_user/imbk-app /home/imbk/apps/app

sudo chown -R imbk /home/imbk/apps/app

sudo su imbk -c "cd ~/apps/app; git remote add upstream https://$github_user@github.com/xvespa/imbk-app" || {
  printe Could not add app upstream
  exit
}

sudo su imbk -c "cd ~/apps/app; git config user.name $github_user" || {
  printe Could not configure github user name
  exit
}

sudo su imbk -c "cd ~/apps/app; git config user.email $github_email" || {
  printe COuld not configure github email
  exit
}

# Install app dependencies

printm 'Installing App node dependencies';

sudo su imbk -c 'cd ~/apps/app; ~/bin/npm install' || {
  printe Could not install app node dependencies
  exit
}

# Install modules dependencies

printm 'Installing App bower dependencies'

sudo su imbk -c "cd ~/apps/app/public; ~/bin/node ~/node_modules/.bin/bower install"

sudo su imbk -c "ln -s ~/apps/modules ~/apps/app/public/bower_components/imbk_modules"

# ################################################### #
# Installing Dashboard
# ################################################### #

printm 'Installing Dashboard';

sudo git clone https://$github_user@github.com/$github_user/imbk-dashboard /home/imbk/apps/dashboard

sudo chown -R imbk /home/imbk/apps/dashboard

sudo su imbk -c "cd ~/apps/dashboard; git remote add upstream https://$github_user@github.com/xvespa/imbk-dashboard" || {
  printe Could not add dashboard upstream
  exit
}

sudo su imbk -c "cd ~/apps/dashboard; git config user.name $github_user" || {
  printe Could not configure github user name
  exit
}

sudo su imbk -c "cd ~/apps/dashboard; git config user.email $github_email" || {
  printe COuld not configure github email
  exit
}

# Install dashboard dependencies

printm 'Installing Dashboard node dependencies';

sudo su imbk -c 'cd ~/apps/dashboard; ~/bin/npm install' || {
  printe Could not install dashboard node dependencies
  exit
}

# Install modules dependencies

printm 'Installing Dashboard bower dependencies'

sudo su imbk -c "cd ~/apps/dashboard/public; ~/bin/node ~/node_modules/.bin/bower install"

sudo su imbk -c "ln -s ~/apps/modules ~/apps/dashboard/public/bower_components/imbk_modules"

# ################################################### #
# Closing
# ################################################### #

# Copy start.sh to bin

sudo su imbk -c "ln -s ~/apps/agent/start.sh ~/bin/start"

printm 'closing mongodb'

sudo su imbk -c "~/bin/mongod --dbpath ~/var/data/agent --shutdown"

# ################################################### #
# Starting
# ################################################### #

echo 'Starting ecosystem';

sudo su imbk -c ~/bin/start || {
  echo Could not start ecosystem
  exit
}
