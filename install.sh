#!/bin/bash

ERROR_MSG="An error has accoured during the installation" 
EMAIL="camharris1@gmail.com"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


#Check if we can curl the site
CODE=`curl -s -o /dev/null -I -w "%{http_code}" localhost:8000`
if [ $CODE == 200 ] 
  then 
    echo "It appears this script has already configured this machine"
  exit
fi

if [ -e /etc/debian_version ]  
  then

    # Check if ansible is installed
    if ! dpkg -l ansible > /dev/null 2>&1
    then
      aptitude update && aptitude -y install ansible curl || `echo $ERROR_MSG &&  echo $ERROR_MSG | mail -s "$(hostname) error" $EMAIL`
      echo "127.0.0.1" > /etc/ansible/hosts
    fi

elif [ -e /etc/redhat-release ]    
  then

     # make sure repositoriy is installed for ansible
     if ! rpm -q epel-release-6-8.noarch
      then
        rpm -ivh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
     fi

     # checj/install selinux control utils
     if ! rpm -q policycoreutils-python
     then
       yum -y install policycoreutils-python || `echo $ERROR_MSG &&  echo $ERROR_MSG | mail -s "$(hostname) error" $EMAIL`
     fi

     # see if selinux is enabled
     SESTAT=`sestatus | grep status | cut -d: -f2 | sed -e 's/ //g'`
     if [ $SESTAT == 'enabled' ]
     then
       setenforce 0
       echo "       SELinux has just been disabled temporarily to allow this too to work
       In order to make these changes permanet please manaully disable SELinux for good by editing
       /etc/selinux/config and then rebooting this machine"
       echo "hit return to continue"
       read
       setenforce 0
     fi


     # check/install ansible
     if ! rpm -q ansible
     then
       yum -y install ansible curl  || `echo $ERROR_MSG &&  echo $ERROR_MSG | mail -s "$(hostname) error" $EMAIL`
       echo "127.0.0.1" > /etc/ansible/hosts
     fi 
 
     REDHAT=1

  else
     echo "I'm not able to guess your OS, this script is meant for Redhat and Debian type systems"
   exit
fi

ansible-playbook deploy.yml --connection=local


if ! curl localhost:8000  
then
  echo "Something when wrong during the config process please contact your administrator"
fi

