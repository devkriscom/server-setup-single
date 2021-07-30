#!/bin/bash
DOMAIN=$1
RECIPE=$2
WWROOT='/home'

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ "$DOMAIN" == "" ]; then
	echo $"command: {domain} {recipe:wp|phpmyadmin}"
	exit 1;
fi 

GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi

SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SHROOT="/home/${SHUSER}";
SHHTML="${SHROOT}/html";
SHTEMP="${SHROOT}/temp";

if [ -d "${SHHTML}" ] && [ "$(ls -A $SHHTML)" ]; then
	if [ ! -d "${SHTEMP}" ]; then
		mkdir -p ${SHTEMP}
	fi
	if [ "$RECIPE" == 'phpmyadmin' ]; then
		DBMNUM='5.1.1'
		wget -P ${SHTEMP} https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip
		unzip ${SHTEMP}/phpMyAdmin-${DBMNUM}-all-languages.zip -d ${SHTEMP}
		cp -r ${SHTEMP}/phpMyAdmin-${DBMNUM}-all-languages/* ${SHHTML}/
		rm -rf ${SHTEMP}/phpMyAdmin-${DBMNUM}-all-languages.zip
		rm -rf ${SHTEMP}/phpMyAdmin-${DBMNUM}-all-languages/*
		chown -R ${SHUSER}:${SHUSER} ${SHROOT}
	fi
else
	echo "install failed because html folder not exist or not empty"
fi



