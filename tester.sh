#!/bin/sh
WWROOT='/home'
PHPNUM='7.4'
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
sed -i 's,^max_execution_time =.*$,post_max_size = 60,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^memory_limit =.*$,memory_limit = 2048M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^post_max_size =.*$,post_max_size = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini  
sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 128M,' ${LSPATH}/${PHPVER}/etc/php/${PHPNUM}/litespeed/php.ini 

# Clean up cache
apt clean