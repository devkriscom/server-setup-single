#!/bin/sh
DOMAIN=$1
WWROOT='/home'
PHPNUM='7.4'
DBMNUM='5.1.1'
PHPVER=lsphp74
LSPATH='/usr/local/lsws'
DBCRED="/home/.dbrootpass"
VHPATH="${LSPATH}/conf/vhosts"
SSLDIR="/etc/letsencrypt/live"
LSCONF="${LSPATH}/conf/httpd_config.conf"
GITHUB="https://raw.githubusercontent.com/wordspec/server-setup-single/master"

if [ $(id -u) -ne 0 ]; then
	echo "run using root"
	exit 1
fi

if [ "$DOMAIN" == "" ]; then
	echo "please provide name: bash ./create.sh www?.domain.com"
	exit 1;
fi

# detect os, exit if not supported
OUTPUT=$(cat /etc/*release)
if echo $OUTPUT | grep -q "Ubuntu 20.04" ; then
	SERVER_OS="Ubuntu"
else
	echo "Unable to detect your OS..."
	exit 1
fi

sudo apt update
sudo apt install -y wget curl zip unzip git rsync certbot memcached vsftpd net-tools

echo "Install litespeed"
sudo wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | sudo bash
sudo apt update
sudo apt install -y openlitespeed
sudo apt install -y lsphp74-common lsphp74-curl lsphp74-imap lsphp74-json \
lsphp74-mysql lsphp74-opcache lsphp74-imagick lsphp74-memcached lsphp74-redis

if [ ! -f /usr/bin/php ]; then
	echo "checking ${LSPATH}/${PHPVER}/bin/php"
	sudo ls -l ${LSPATH}/${PHPVER}/bin
	if [ -e ${LSPATH}/${PHPVER}/bin/php ]; then
		sudo ln -s ${LSPATH}/${PHPVER}/bin/php /usr/bin/php
	else
		echo "${LSPATH}/${PHPVER}/bin/php not exist, please check your PHP version!"
		exit 1 
	fi        
fi

echo "Install mariadb"
sudo apt install -y mariadb-server mariadb-client
DBPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '');
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DBPASS}') WHERE User = 'root'"
sudo mysql -e "DROP USER ''@'localhost'"
sudo mysql -e "DROP USER ''@'$(hostname)'"
sudo mysql -e "DROP DATABASE test"
sudo mysql -e "FLUSH PRIVILEGES"
echo "${DBPASS}" > ${DBCRED}
sudo systemctl restart mysql

echo "Install elasticsearch"
sudo curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt -key add -
echo "deb https://artifacts.elastic.co/packages/7.x/sudo apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y elasticsearch
sudo systemctl enable elasticsearch

echo "Install wp-cli"
if [ ! -e /usr/local/bin/wp ]; then
	sudo curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	sudo chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
fi  

echo "Install composer"
if [ ! -e /usr/local/bin/composer ]; then
	sudo curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --force --filename=composer
fi

echo "Optimize database"
if [ ! -e /etc/mysql/conf.d/optimy.cnf ]; then
	sudo curl -sO ${GITHUB}/config/mysql.cnf 
	sudo mv mysql.cnf /etc/mysql/conf.d/optimy.cnf 
	sudo systemctl restart mysql 
fi

echo "Optimize php.ini"
sudo sed -i 's,^max_execution_time =.*$,post_max_size = 60,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^memory_limit =.*$,memory_limit = 512M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^post_max_size =.*$,post_max_size = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini 

echo "Install postfix"
sudo apt install -y postfix 
sudo apt install -y mailutils
sudo systemctl restart postfix
sudo apt clean

echo "Install manager"
if [ ! -e /usr/local/bin/xmaster ]; then
	sudo curl -sO ${GITHUB}/helper.sh
	sudo chmod +x helper.sh
	sudo mv helper.sh /usr/local/bin/xmaster
	sudo xmaster update
fi

echo "Litespeed Listener"
WEBURL="${DOMAIN}"
GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	USEWWW='TRUE'
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi

sudo echo "
listener HTTP {
	address                 *:80
	secure                  0
}
listener HTTPS {
	address                 *:443
	secure                  1
	keyFile                 ${SSLDIR}/${DOMAIN}/privkey.pem
  certFile                ${SSLDIR}/${DOMAIN}/fullchain.pem
  certChain               1
} " >> ${LSCONF}
sudo chown -R lsadm:lsadm ${VHPATH}/*
sudo systemctl restart lsws
sudo xdomain create ${WEBURL} auto

echo "Enable firewall =>"
sudo apt install -y ufw
sudo ufw allow 22
sudo ufw allow 53
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 7080
sudo ufw allow 8088
sudo ufw default reject
sudo ufw enable

echo "Litespeed admin password =>"
sudo /usr/local/lsws/admin/misc/admpass.sh 