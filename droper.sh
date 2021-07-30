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
DBROOT="${WWROOT}/.dbrootpass"

sudo awk '!a[$0]++' /etc/apt/sources.list

echo "\n Remove mysql ...\n"
systemctl stop mysql
apt purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
rm -rf /var/lib/mysql

echo "\n Remove litespeed ...\n"
/usr/local/lsws/admin/misc/uninstall.sh
apt purge -y openlitespeed lsphp74-common lsphp74-curl lsphp74-imap lsphp74-json \
lsphp74-mysql lsphp74-opcache lsphp74-imagick lsphp74-memcached lsphp74-redis

rm -rf ${LSPATH}

echo "\n Remove root passprd ...\n"
rm -rf ${WWROOT}/*

apt autoremove
apt autoclean