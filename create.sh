#!/bin/sh
DOMAIN=$1
WWROOT='/home'
PHPNUM='7.4'
DBMNUM='5.1.1'
PHPVER=lsphp74
LSPATH='/usr/local/lsws'
VHPATH="${LSPATH}/conf/vhosts"
LSCONF="${LSPATH}/conf/httpd_config.conf"
DBCRED="/home/.dbrootpass"

if [ $(id -u) -ne 0 ]; then
	echo "run using root"
	exit 1
fi

# detect os, exit if not supported
OUTPUT=$(cat /etc/*release)
if echo $OUTPUT | grep -q "Ubuntu 20.04" ; then
	SERVER_OS="Ubuntu"
else
	echo "Unable to detect your OS..."
	exit 1
fi

sudo aptupdate
sudo aptinstall -y wget curl zip unzip git rsync certbot memcached vsftpd

echo "Install litespeed"
sudo wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | sudo bash
sudo aptupdate
sudo aptinstall -y openlitespeed
sudo aptinstall -y lsphp74-common lsphp74-curl lsphp74-imap lsphp74-json \
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
sudo aptinstall -y mariadb-server mariadb-client
DBPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '');
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DBPASS}') WHERE User = 'root'"
sudo mysql -e "DROP USER ''@'localhost'"
sudo mysql -e "DROP USER ''@'$(hostname)'"
sudo mysql -e "DROP DATABASE test"
sudo mysql -e "FLUSH PRIVILEGES"
echo "${DBPASS}" > ${DBCRED}
sudo systemctl restart mysql

echo "Install elasticsearch"
sudo curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/sudo aptstable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo aptupdate
sudo aptinstall -y elasticsearch
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

echo "Install virtualhost"
if [ ! -e /usr/local/bin/xdomain ]; then
	sudo curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xdomain.sh
	sudo chmod +x xdomain.sh
	sudo mv xdomain.sh /usr/local/bin/xdomain
fi


# create 80 listener
sudo echo "
listener HTTP {
  address                 *:80
  secure                  0
}
listener HTTPS {
  address                 *:443
  secure                  1
} " >> ${LSCONF}

echo "Optimize database"
if [ ! -e /etc/mysql/conf.d/optimy.cnf ]; then
	sudo curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/config/mysql.cnf 
	sudo mv mysql.cnf /etc/mysql/conf.d/optimy.cnf 
  sudo systemctl restart mysql 
fi

echo "Optimize php.ini"
sudo sed -i 's,^max_execution_time =.*$,post_max_size = 60,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^memory_limit =.*$,memory_limit = 512M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^post_max_size =.*$,post_max_size = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sudo sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini 

echo "Install postfix"
sudo aptinstall -y postfix 
sudo aptinstall -y mailutils
sudo systemctl restart postfix
sudo aptclean

echo "Setup litespeed admin password"
sudo /usr/local/lsws/admin/misc/admpass.sh 

while [ "$DOMAIN" != "" ]; do
	xdomain create $DOMAIN auto
done

echo "Fireall setup..."
sudo aptinstall -y ufw
sudo ufw allow 22,53,80,443,7080,8088/tcp
sudo ufw default reject
sudo ufw enable