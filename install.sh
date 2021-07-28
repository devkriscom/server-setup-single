#!/bin/sh
DOMAIN=$1
WWROOT='/home'
PHPNUM='7.4'
DBMNUM='5.1.1'
PHPVER=lsphp74
LSPATH='/usr/local/lsws'
BKPATH='/var/www/backup'
VHPATH="${LSPATH}/conf/vhosts"
LSCONF="${LSPATH}/conf/httpd_config.conf"
DBROOT="${WWROOT}/.mysql_root_password"

if [ $(id -u) -ne 0 ]; then
	echo "\nrun using root ...\n"
	exit 1
fi

# detect os, exit if not supported
OUTPUT=$(cat /etc/*release)
if echo $OUTPUT | grep -q "Ubuntu 20.04" ; then
	SERVER_OS="Ubuntu"
else
	echo "\nUnable to detect your OS...\n"
	exit 1
fi

echo "\n Update Ubuntu ...\n"
apt update

echo "\n Install basic toolkits ...\n"
apt install -y wget curl zip unzip git rsync

echo "\n Install litespeed ...\n"
wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | sudo bash
apt update
apt install -y openlitespeed
apt install -y lsphp74-common lsphp74-curl lsphp74-imap lsphp74-json \
lsphp74-mysql lsphp74-opcache lsphp74-imagick lsphp74-memcached lsphp74-redis

if [ ! -f /usr/bin/php ]; then
	echo "checking ${LSPATH}/${PHPVER}/bin/php"
	ls -l ${LSPATH}/${PHPVER}/bin
	if [ -e ${LSPATH}/${PHPVER}/bin/php ]; then
		ln -s ${LSPATH}/${PHPVER}/bin/php /usr/bin/php
	else
		echo "${LSPATH}/${PHPVER}/bin/php not exist, please check your PHP version!"
		exit 1 
	fi        
fi

echo "\n Install certbot ...\n"
apt install -y certbot

echo "\n Install memcached ...\n"
apt install -y memcached

echo "\n Install vsftpd ...\n"
apt install -y vsftpd

echo "\n Install mariadb ...\n"
apt install -y mariadb-server mariadb-client
DBUSERPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '');
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DBUSERPASS}') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"
echo "${DBUSERPASS}" > ${DBROOT}
systemctl restart mysql

echo "\n Install supervisor ...\n"
apt -y install supervisor
systemctl restart supervisor
systemctl enable supervisor

echo "\n Install elasticsearch ...\n"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install -y elasticsearch
systemctl start elasticsearch
systemctl enable elasticsearch

echo "\n Install wp-cli ...\n"
if [ ! -e /usr/local/bin/wp ]; then
	curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi  


echo "\n Install composer ...\n"
if [ ! -e /usr/local/bin/composer ]; then
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --force --filename=composer
fi

echo "\n Install virtualhost ...\n"
if [ ! -e /usr/local/bin/xdomain ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xdomain.sh
	chmod +x xdomain.sh
	mv xdomain.sh /usr/local/bin/xdomain
fi

echo "\n Install database backup ...\n"
if [ ! -e /usr/local/bin/xdbsave ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xdbsave.sh
	chmod +x xdbsave.sh
	mv xdbsave.sh /usr/local/bin/xdbsave
fi

echo "\n Install site file backup ...\n"
if [ ! -e /usr/local/bin/xdrsave ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xdrsave.sh
	chmod +x xdrsave.sh
	mv xdrsave.sh /usr/local/bin/xdrsave
fi

echo "\n Install remote backup ...\n"
if [ ! -e /usr/local/bin/xbackup ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xbackup.sh
	chmod +x xbackup.sh
	mv xbackup.sh /usr/local/bin/xbackup
fi

echo "\n Install remote cloner ...\n"
if [ ! -e /usr/local/bin/xcloner ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xcloner.sh
	chmod +x xcloner.sh
	mv xcloner.sh /usr/local/bin/xcloner
fi

echo "\n Install malware scanner ...\n"
if [ ! -e /usr/local/bin/xsecure ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/helper/xsecure.sh
	chmod +x xsecure.sh
	mv xsecure.sh /usr/local/bin/xsecure
fi

# Install Firewall
echo "Fireall setup..."
apt install -y ufw
ufw allow 22,53,80,443,7080,8088/tcp
ufw default reject
ufw enable

# create 80 listener
echo "
listener HTTP {
  address                 *:80
  secure                  0
}
listener HTTPS {
  address                 *:443
  secure                  1
} " >> ${LSCONF}

mkdir -p "${BKPATH%/*}"

echo "Optimize database"
if [ ! -e /etc/mysql/conf.d/optimy.cnf ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/config/mysql.cnf 
	mv mysql.cnf /etc/mysql/conf.d/optimy.cnf 
  systemctl restart mysql 
fi

if [ ! -e /etc/mysql/conf.d/optimy.cnf ]; then
	curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/config/mysql.cnf 
	mv mysql.cnf /etc/mysql/conf.d/optimy.cnf 
  systemctl restart mysql 
fi

echo "Optimize php configuration"
sed -i 's,^max_execution_time =.*$,post_max_size = 60,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^memory_limit =.*$,memory_limit = 2048M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^post_max_size =.*$,post_max_size = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini 

echo "Download phpmyadmin"
mkdir -p "${WWROOT}/managedb"
wget https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip -o ${WWROOT}/managedb/latest.zip
unzip ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages.zip
mv ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages html
rm ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages.zip

echo "Install postfix"
apt install -y postfix 
apt install -y mailutils
sed -i 's,^inet_interfaces =.*$,inet_interfaces = loopback-only,' /etc/postfix/main.cf
sudo systemctl restart postfix


# Clean up cache
apt clean


echo "Setup litespeed admin password"
sudo /usr/local/lsws/admin/misc/admpass.sh 

while [ "$DOMAIN" != "" ]; do
	xdomain create $DOMAIN auto
done