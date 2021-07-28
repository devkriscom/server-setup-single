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
rm -rf ${LSPATH}

echo "\n Remove root passprd ...\n"
/usr/local/lsws/admin/misc/uninstall.sh
rm -rf ${WWROOT}/*

apt autoremove
apt autoclean