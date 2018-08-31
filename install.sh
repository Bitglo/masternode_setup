#!/bin/bash

##################################################
# Script by François YoYae GINESTE - 03/04/2018
# Updated and optimized by BitgloBill - 08/30/2018
# https://get.bitglo.io/
##################################################

LOG_FILE=/tmp/install.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

clear

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

# Check for systemd
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run with \033[1msudo\033[0m"
	exit 1
fi

#print variable on a screen
decho "Please make sure you double check before pressing enter!!"

read -e -p "User that will run Bitglo !CaSe SeNsItIvE! : " whoami
if [[ "$whoami" == "" ]]; then
	decho "WARNING: No user entered. Exit."
	exit 3
fi
if [[ "$whoami" == "root" ]]; then
	decho "WARNING: Please do not use root to run this script! Exit."
	exit 3
fi
read -e -p "Server IP Address: " ip
if [[ "$ip" == "" ]]; then
	decho "WARNING: No IP address entered! Exit."
	exit 3
fi
read -e -p "Masternode Private Key (e.g. 7fjm9Yfdx9DD4J42r7rytMnbKUG1AzVB4fYZ71z4MVWRT9Nisty) : " key
if [[ "$key" == "" ]]; then
	decho "WARNING: No masternode private key entered. Exit."
	exit 3
fi
read -e -p "[Optional] Install Fail2ban? (Recommended) [Y/n]: " install_fail2ban
read -e -p "[Optional] Install UFW and configure ports? (Recommended) [Y/n]: " UFW

decho "Updating VPS and installing required software."

# update package and upgrade Ubuntu
apt-get -y update >> $LOG_FILE 2>&1
# Add Berkely PPA
decho "Installing Dependencies..."

apt-get -y install software-properties-common >> $LOG_FILE 2>&1
add-apt-repository ppa:bitcoin/bitcoin -y >> $LOG_FILE 2>&1
apt-get -y update >> $LOG_FILE 2>&1
sudo apt-get install automake libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common python-software-properties g++ bsdmainutils libevent-dev -y >> $LOG_FILE 2>&1
apt-get install libdb4.8-dev libdb4.8++-dev -y >> $LOG_FILE 2>&1

decho "Downloading Bitglo Core..."

git clone https://github.com/Bitglo/bitglo.git /home/$whoami/bitglo >> $LOG_FILE 2>&1
cd /home/$whoami/bitglo >> $LOG_FILE 2>&1

decho "Preparing to Build..."

sudo chmod +x autogen.sh && sudo ./autogen.sh >> $LOG_FILE 2>&1

decho "Configuring build options..."
./configure >> $LOG_FILE 2>&1

decho "Installing Bitglo Core..."
sudo chmod +x share/genbuild.sh
sudo make install -j4
cd /home/$whoami/

# Install required packages
decho "Installing masternode packages and dependencies..."

apt-get -y install sudo >> $LOG_FILE 2>&1
apt-get -y install wget >> $LOG_FILE 2>&1
apt-get -y install git >> $LOG_FILE 2>&1
apt-get -y install unzip >> $LOG_FILE 2>&1
apt-get -y install virtualenv >> $LOG_FILE 2>&1
apt-get -y install python-virtualenv >> $LOG_FILE 2>&1
apt-get -y install pwgen >> $LOG_FILE 2>&1

if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
	decho "Optional installs : fail2ban"
	cd ~
	apt-get -y install fail2ban >> $LOG_FILE 2>&1
	systemctl enable fail2ban >> $LOG_FILE 2>&1
	systemctl start fail2ban >> $LOG_FILE 2>&1
fi

if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
	decho "Optional installs : ufw"
	apt-get -y install ufw >> $LOG_FILE 2>&1
	ufw allow ssh/tcp >> $LOG_FILE 2>&1
	ufw allow sftp/tcp >> $LOG_FILE 2>&1
	ufw allow 12755/tcp >> $LOG_FILE 2>&1
	ufw allow 12756/tcp >> $LOG_FILE 2>&1
	ufw default deny incoming >> $LOG_FILE 2>&1
	ufw default allow outgoing >> $LOG_FILE 2>&1
	ufw logging on >> $LOG_FILE 2>&1
	ufw --force enable >> $LOG_FILE 2>&1
fi

decho "Create user $whoami (if necessary)"
#desactivate trap only for this command
trap '' ERR
getent passwd $whoami > /dev/null 2&>1

if [ $? -ne 0 ]; then
	trap 'error ${LINENO}' ERR
	adduser --disabled-password --gecos "" $whoami >> $LOG_FILE 2>&1
else
	trap 'error ${LINENO}' ERR
fi

#Create bitglo.conf
decho "Setting up Bitglo Core..."
#Generating Random Passwords
user=`pwgen -s 16 1`
password=`pwgen -s 64 1`

echo 'Creating bitglo.conf...'
mkdir -p /home/$whoami/.bitglocore/
cat << EOF > /home/$whoami/.bitglocore/bitglo.conf
rpcuser=$user
rpcpassword=$password
rpcallowip=127.0.0.1
rpcport=12756
listen=1
server=1
daemon=1
maxconnections=24
masternode=1
masternodeprivkey=$key
externalip=$ip
addnode=203.100.213.137
addnode=45.76.228.136
addnode=125.237.193.176
addnode=174.113.85.30
addnode=118.243.28.238
addnode=217.182.173.104
addnode=5.53.155.66
addnode=93.152.193.106
addnode=37.171.193.191
addnode=41.104.53.147
addnode=81.89.113.153
addnode=84.232.245.208
addnode=60.179.234.39
addnode=81.132.226.245
addnode=68.3.44.30
addnode=72.53.139.146
EOF
chown -R $whoami:$whoami /home/$whoami

#Run bitglod as selected user
sudo -H -u $whoami bash -c 'bitglod' >> $LOG_FILE 2>&1

echo 'Bitglo Core prepared, finished and launched!'

sleep 10

#Setting up coin

decho "Setting up masternode sentinel"

echo 'Downloading sentinel...'
#Install Sentinel
git clone https://github.com/bitglo/sentinel.git /home/$whoami/sentinel >> $LOG_FILE 2>&1
chown -R $whoami:$whoami /home/$whoami/sentinel >> $LOG_FILE 2>&1

cd /home/$whoami/sentinel
echo 'Setting up sentinel dependencies...'
sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

#Setup crontab
echo "@reboot sleep 30 && bitglod" >> newCrontab
echo "* * * * * cd /home/$whoami/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> newCrontab
crontab -u $whoami newCrontab >> $LOG_FILE 2>&1
rm newCrontab >> $LOG_FILE 2>&1

decho "Success! Starting up your Masternode."
echo ""
echo "Now, you need to do these final steps in the following order: "
echo "1- Go to your Windows or MacOS wallet and modify masternode.conf as required, then restart your wallet."
echo "2- Select the newly created masternode and then click on start-alias."
echo "3- Once completed, please return to VPS and wait for the wallet to be synced."
echo "4- Then you can try the command 'bitglo-cli masternode status' to get the masternode status."

su $whoami
