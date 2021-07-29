#!/bin/bash
DOMAIN=$1
SYSTEM=$2
WWROOT='/home'

while [ "$DOMAIN" == "" ]; do
	echo $"command format: {domain} {phpmyadmin}"
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
fi

USERNAME=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SITEROOT="${WWROOT}/${USERNAME}";
SITEHTML="${WWROOT}/${USERNAME}/html";

if [ ! -d "${SITEHTML}" ]; then
	echo "Folder ${USERNAME}/html doesnt exists! bye"
	exit 1;
fi

if [ ! -d "/var/www/cms" ]; then
	mkdir -p /var/www/cms
fi

if [ "$SYSTEM" == 'phpmyadmin' ]; then
	echo "install ${SYSTEM} on ${DOMAIN}: ${SITEHTML}"

	DBMNUM='5.1.1'
	wget -P /var/www/cms https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip
	unzip /var/www/cms/phpMyAdmin-${DBMNUM}-all-languages.zip -d ${SITEHTML}/
	cp -r ${SITEHTML}/phpMyAdmin-${DBMNUM}-all-languages/* ${SITEHTML}/
	rm -rf ${SITEHTML}/phpMyAdmin-${DBMNUM}-all-languages/*
	exit 1;
fi
