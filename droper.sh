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

echo "\n Remove mysql ...\n"
systemctl stop mysql
apt purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
rm -rf /var/lib/mysql

echo "\n Remove litespeed ...\n"
/usr/local/lsws/admin/misc/uninstall.sh
apt purge -y -qq openlitespeed lsphp74-common lsphp74-curl lsphp74-imap lsphp74-json \
lsphp74-mysql lsphp74-opcache lsphp74-imagick lsphp74-memcached lsphp74-redis

rm -rf ${LSPATH}



echo "\n Remove root passprd ...\n"
rm -rf ${WWROOT}/*

rm /usr/local/bin/xbackup
rm /usr/local/bin/xsecure
rm /usr/local/bin/xdbsave
rm /usr/local/bin/xdomain
rm /usr/local/bin/xdrsave
rm /usr/local/bin/xsecure

apt autoremove
apt autoclean