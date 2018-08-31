#!/bin/bash

##################################################
# Script by François YoYae GINESTE - 03/04/2018
# Updated and optimized by BitgloBill - 08/30/2018
# https://get.bitglo.io/
##################################################

LOG_FILE=/tmp/update.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

cat <<'FIG'
______ _ _        _        _       
| ___ (_) |      | |      (_)      
| |_/ /_| |_ __ _| | ___   _  ___  
| ___ \ | __/ _` | |/ _ \ | |/ _ \ 
| |_/ / | || (_| | | (_) || | (_) |
\____/|_|\__\__, |_|\___(_)_|\___/ 
             __/ |                 
            |___/                  
FIG

echo -e "\nStarting Bitglo Masternode update. This will take a few minutes...\n"

if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1msudo\033[0m"
	exit 1
fi


read -e -p "Please enter the user name that runs Bitglo Core !CaSe SeNsItIvE! : " whoami


getent passwd $whoami > /dev/null 2&>1
if [ $? -ne 0 ]; then
	echo "$whoami User does not exist!"
	exit 3
fi


decho "Stopping open Bitglo Core..."
pkill -f bitglod  >> $LOG_FILE 2>&1

sleep 5

decho "Updating and installing Dependencies......"

apt-get -y update >> $LOG_FILE 2>&1
decho "Installing Bitgo updates..."

apt-get -y install software-properties-common >> $LOG_FILE 2>&1
apt-get -y update >> $LOG_FILE 2>&1

cd /home/$whoami/bitglo >> $LOG_FILE 2>&1
sudo git pull
sudo make install -j4
cd /home/$whoami/

decho "Checking and installing dependencies..."

apt-get -y install sudo >> $LOG_FILE 2>&1
apt-get -y install wget >> $LOG_FILE 2>&1
apt-get -y install git >> $LOG_FILE 2>&1
apt-get -y install unzip >> $LOG_FILE 2>&1
apt-get -y install virtualenv >> $LOG_FILE 2>&1
apt-get -y install python-virtualenv >> $LOG_FILE 2>&1
apt-get -y install pwgen >> $LOG_FILE 2>&1


decho "Backup configuration file"

if [ "$whoami" != "root" ]; then
	path=/home/$whoami
else
	path=/root
fi

cd $path

decho "Relaunching Bitglo Core"
sudo -H -u $whoami bash -c 'bitglod' >> $LOG_FILE 2>&1

decho "Checking for Sentinel..."

if [ ! -d "/home/$whoami/sentinel" ]; then
  decho 'Sentinel is not installed.'
  decho 'Downloading sentinel...'

  git clone https://github.com/Bitglo/sentinel.git /home/$whoami/sentinel >> $LOG_FILE 2>&1
  chown -R $whoami:$whoami /home/$whoami/sentinel >> $LOG_FILE 2>&1

  cd /home/$whoami/sentinel
  decho 'Setting up sentinel dependencies...'
  sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
  sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1


  echo "@reboot sleep 30 && bitglod" >> newCrontab
  echo "* * * * * cd /home/$whoami/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> newCrontab
  crontab -u $whoami newCrontab >> $LOG_FILE 2>&1
  rm newCrontab >> $LOG_FILE 2>&1
  decho 'Sentinel Installed.'
else
  decho "Sentinel is installed and updated.";
fi

decho "Bitglo and your Masternodes have been updated!"
echo "Now, you need to finally restart your masternode in the following order: "
echo "Go to your Windows or MacOS wallet on the Masternode tab."
echo "Select the updated masternode and then click on start-alias."
echo "Once completed please return to VPS and wait for the wallet to be synced."
echo "Then you can try the command 'bitglo-cli masternode status' to get the masternode status."

su $whoami
