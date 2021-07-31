#!/bin/bash
DOMAIN=$1
ACTION=$2

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ "$DOMAIN" == "" ]; then
	echo $"command: {domain}"
	exit 1;
fi 

GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi

DBUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBNAME=$(echo "${DOMAIN}" | sed -e 's/\./_/g')
SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SHROOT="/home/${SHUSER}";
DBPASS=$(cat ${SHROOT}/.dbpass | head -n 1 | awk '{print}')
SHPASS=$(cat ${SHROOT}/.shpass | head -n 1 | awk '{print}')

echo "***********************************************************"
echo " SERVER STATUS																						 "
echo "***********************************************************"
echo ""
echo " SSH USER: ${SHUSER}"
echo " SSH PASS: ${SHPASS}"
echo " SQL USER: ${DBUSER}"
echo " SQL PASS: ${DBPASS}"
echo ""
echo " To manage your server visit: http://$IP"
echo " Default credentials are: administrator / 12345678"
echo ""
echo "***********************************************************"
echo "  DO NOT SHARE THIS DATA TO ANYONE                         "
echo "***********************************************************"