#!/bin/bash
DOMAIN=$1
DBNAME=$2
DBUSER=$3
DBPASS=$4
SOURCE=$5
IPADDR=$6

if [ "$DOMAIN" == "" ] || [ "$DBNAME" == "" ] || [ "$DBUSER" == "" ] || [ "$DBPASS" == "" ] || [ "$SOURCE" == "" ]; then
	echo $"command: {domain} {dbname} {dbuser} {dbpass} {filedir} {host}"
	exit 1;
fi

GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi
SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SHCOPY="/home/cloner/${SHUSER}"
if [ ! -d "${SHCOPY}" ]; then
	mkdir -p ${SHCOPY}
else
	rm -rf ${SHCOPY}/*
fi

REMOTE="${DOMAIN}";
if [ "$IPADDR" != '' ]; then
	REMOTE="${IPADDR}";
fi
SERVER="${SHUSER}@${REMOTE}:/home/${SHUSER}/import/"

tar -zcvpf $SHCOPY/file.tar.gz -C ${SOURCE} .
mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} | gzip > ${SHCOPY}/data.sql.gz
scp -r ${SHCOPY}/* ${SERVER}
rm -rf ${SHCOPY}/*
