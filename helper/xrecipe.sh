#!/bin/bash
DOMAIN=$1
RECIPE=$2
FORCED=$3
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
SHREPO="${SHROOT}/repo";

if [ -d "${SHHTML}" ]; then
	ALLOW="NO"
	if [ ! "$(ls -A $SHHTML)" ]; then
		ALLOW="YES"
	else
		if [ "$FORCED" == "force" ]; then
			ALLOW="YES"
			sudo rm -rf ${SHHTML}/*
		else
			echo "html folder not empty"
		fi
	fi
	if [ "$ALLOW" == "YES" ]; then
		if [ ! -d "${SHREPO}" ]; then
			mkdir -p ${SHREPO}
		fi
		if [ "$RECIPE" == 'phpmyadmin' ]; then
			DBMNUM='5.1.1'
			wget -P ${SHREPO} https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip
			unzip ${SHREPO}/phpMyAdmin-${DBMNUM}-all-languages.zip -d ${SHREPO}
			cp -r ${SHREPO}/phpMyAdmin-${DBMNUM}-all-languages/* ${SHHTML}/
			rm -rf ${SHREPO}/phpMyAdmin-${DBMNUM}-all-languages.zip
			rm -rf ${SHREPO}/phpMyAdmin-${DBMNUM}-all-languages/*
			chown -R ${SHUSER}:${SHUSER} ${SHROOT}
		fi
	else
		echo "html folder not empty"
	fi
else
	echo "install failed because html folder not exist"
fi