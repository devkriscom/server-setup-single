#!/bin/bash
DOMAIN=$1
DBPASS=$2

if [ "$DOMAIN" == "" ]; then
	echo $"command: {domain} {dbpass:optional}"
	exit 1;
fi

SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')

FOLDER="/home/${SHUSER}";
DBUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBNAME=$(echo "${DOMAIN}" | sed -e 's/\./_/g')

PASSWD=$(cat ${FOLDER}/.datapass | head -n 1 | awk '{print}')
if [ "$DBPASS" != '' ]; then
	PASSWD="${DBPASS}";
fi

echo "import $FOLDER with dbpass $PASSWD"

tar -xvf ${FOLDER}/file.tar.gz -C html
zcat ${FOLDER}/data.sql.gz | mysql -u ${DBUSER} -p${PASSWD} ${DBNAME}
chown -R ${SHUSER}:${SHUSER} /home/${SHUSER}/html