#!/bin/bash

function mkrep () {
  cd ~;
  
  bigecho Creating directories
  
  mkdir lib;
  mkdir -p var/log/actions;
  mkdir bin
  mkdir apps

  bigecho Updating bashrc and sourcing it

  cat << BASH >> ~/.bashrc
export PATH="$PWD/bin:$PATH";
BASH
  
  . ~/.bashrc
}

function install_git () {
  sudo add-apt-repository ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install git
}

function install_node () {
  sudo apt-get install wget g++;
  cd ~/lib
  wget http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz
  tar xzf node-v0.10.26-linux-x64.tar.gz
  cd node-v0.10.26-linux-x64/
  cat << BASH >> ~/.bashrc
export PATH="$PWD/bin:$PATH";
BASH
  . ~/.bashrc

  bigecho Installing dependencies

  sudo ln -s $PWD/bin/node /usr/bin/node

  if npm install -g bower browserify colors emit.js co2-git/hop node-sass async request socket.io express jade aws-sdk; then
    bigecho dependencies installed!
  else
    echo Could not npm dependencies
    return 1
  fi
}

function install_mongodb () {
  cd ~/lib/;
  bigecho Downloading MongoDB
  wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.9.tgz;
  tar -xzf mongodb-linux-x86_64-2.4.9.tgz;

  bigecho Updating bashrc and sourcing it

  cat << BASH >> ~/.bashrc
export PATH="$PWD/mongodb-linux-x86_64-2.4.9/bin:$PATH";
BASH
  
  . ~/.bashrc
}


function install_mysql () {
  sudo su;
  apt-get install libaio1;
  /etc/init.d/apparmor stop
  update-rc.d -f apparmor remove
  apt-get remove apparmor apparmor-utils
  groupadd mysql
  useradd -r -g mysql mysql
  cd /usr/local
  wget -O mysql-5.6.17.tar.gz http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.17-linux-glibc2.5-x86_64.tar.gz;
  tar xfz mysql-5.6.17.tar.gz
  mv mysql-5.6.17-linux-glibc2.5-x86_64/ mysql
  cd mysql
  chown -R mysql .
  chgrp -R mysql .
  scripts/mysql_install_db --user=mysql
  chown -R root .
  chown -R mysql data
  cp support-files/mysql.server /etc/init.d/mysql.server 
  /etc/init.d/mysql.server start
  update-rc.d mysql.server defaults
  ln -s /usr/local/mysql/bin/* /usr/local/bin/
  mysql_secure_installation;
  mysql -u root -p "CREATE DATABASE";
  mysql -u root -p < share/innodb_memcached_config.sql
  mysql -u root -p "INSTALL PLUGIN daemon_memcached SONAME 'libmemcached.so'"
  exit
}



function install_apps () {
  cd ~/apps;

  git clone https://github.com/xvespa/imbk-modules modules;
  cd modules;
  bower install;
  cd ..

  git clone https://github.com/xvespa/imbk-dashboard dashboard;
  cd dashboard;
  npm run-script preinstall;
  cd ..
  cd ~
  ln -s $PWD/apps/dashboard/bin/robot.js $PWD/bin/robot
  cd apps

  git clone https://github.com/xvespa/imbk-app app;
  cd app;
  npm run-script preinstall;
  cd ..

  git clone https://github.com/xvespa/imbk-api api;
  cd api;
  npm run-script preinstall;
  cd ..

}

function install_mongodb_db () {
  robot install-dashboard-database;
}

function bigecho () {
  echo
  echo ====================================================
  echo ====================================================
  echo "$@"
  echo ====================================================
  echo ====================================================
  echo
  echo
}

bigecho Making repository

mkrep;

bigecho Installing git

install_git;

bigecho Installing node

if ! install_node; then
  echo 'Could not install node';
  exit;
fi

bigecho Installing apps

install_apps;
