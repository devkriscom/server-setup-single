#!/bin/bash
DOMAIN=$1
DBNAME=$2
DBUSER=$3
DBPASS=$4
SOURCE=$5
IPADDR=$6


if [ "$DOMAIN" == "" ] || [ "$DBNAME" == "" ] || [ "$DBUSER" == "" ] || [ "$DBPASS" == "" ] || [ "$SOURCE" == "" ]; then
	echo $"command: {domain} {dbname} {dbuser} {dbpass} {filedir} {ip:optional}"
	exit 1;
fi

SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
TARGET="/home/cloner/${SHUSER}"

echo "\n cleanup backup directory before starting...\n"
rm -rf ${TARGET}/*

REMOTE="${DOMAIN}";
if [ "$IPADDR" != '' ]; then
	REMOTE="${IPADDR}";
fi

SERVER="${SHUSER}@${REMOTE}:/home/${SHUSER}/"

mkdir -p ${TARGET}
mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} | gzip > ${TARGET}/data.sql.gz
tar -zcvpf $TARGET/file.tar.gz -C ${SOURCE} .

echo "scp to: ${SERVER}"
scp -r ${TARGET}/* ${SERVER}

echo "\n completed, cleanup backup directory...\n"
rm -rf ${TARGET}/*
