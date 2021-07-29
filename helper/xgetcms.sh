#!/bin/bash
DOMAIN=$1
SYSTEM=$3
WWROOT='/home'

while [ "$DOMAIN" == "" ]; do
	echo $"command format: {install|remove} domain.com"
	exit 1;
done

#check if use www
USEWWW=''
GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
echo "domain www check: $GETWWW"
if [ "$GETWWW" == "www." ]; then
	USEWWW='TRUE'
	ORIGIN="${DOMAIN}"
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
	echo "$DOMAIN using www: $USEWWW" 
else
	echo "$DOMAIN without www"  
fi
USERNAME=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SITEROOT="${WWROOT}/${USERNAME}";
SITEHTML="${WWROOT}/${USERNAME}/html";

if [ ! -d "${SITEHTML}" ]; then
	echo $"Folder ${USERNAME}/html doesnt exists! bye"
	exit 1;
fi

if [ ! -d "/var/www/cms" ]; then
	mkdir -p /var/www/cms
fi

if [ "$ACTION" != 'phpmyadmin' ]; then
	DBMNUM='5.1.1'
	wget -P /var/www/cms https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip
	unzip /var/www/cms/phpMyAdmin-${DBMNUM}-all-languages.zip -d ${SITEHTML}/
	exit 1;
fi
