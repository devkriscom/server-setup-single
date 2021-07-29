#!/bin/bash
DOMAIN=$1
ACTION=$2
FORCED=$3
MYPASS=$4
DOHTML="NO"
DODATA="NO"

if [ "$DOMAIN" == "" ]; then
	echo "command: {domain} {all|db|file} {force} {dbpass:optional}"
	exit 1;
fi

GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi

SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBNAME=$(echo "${DOMAIN}" | sed -e 's/\./_/g')
FOLDER="/home/${SHUSER}";

DBPASS=$(cat ${FOLDER}/.datapass | head -n 1 | awk '{print}')
if [ "$MYPASS" != '' ]; then
	DBPASS="${MYPASS}";
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "file" ]; then

	if [ -d "$FOLDER/html" ] && [ -f "${FOLDER}/file.tar.gz" ]; then
		if [ "$(ls -A $FOLDER/html)" ]; then
			if [ "$FORCED" == "force" ]; then
				DOHTML="YES"
				rm -rf ${FOLDER}/html/*
			fi
		else
			DOHTML="YES"
		fi
	fi

	if [ "$DOHTML" == "YES" ]; then
		tar -xvf ${FOLDER}/file.tar.gz -C ${FOLDER}/html
		if [ -f "$FOLDER/html/wp-config.php" ]; then
			sed "/DB_HOST/s/'[^']*'/'${DBPASS}'/2" ${FOLDER}/html/wp-config.php
			sed "/DB_NAME/s/'[^']*'/'${DBNAME}'/2" ${FOLDER}/html/wp-config.php
			sed "/DB_USER/s/'[^']*'/'${DBUSER}'/2" ${FOLDER}/html/wp-config.php
			sed "/DB_PASSWORD/s/'[^']*'/'${DBPASS}'/2" ${FOLDER}/html/wp-config.php
		fi
		chown -R ${SHUSER}:${SHUSER} /home/${SHUSER}/html
	else
		echo "file import failed because conditions doesn't satisfy system"
	fi
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "db" ]; then

	if [ -f "${FOLDER}/data.sql.gz" ]; then

		if ! mysql -u root -p${MYPASS} -e "use ${DATABASE};"; then
			DODATA="YES"
		elif [ "$FORCED" == "force" ]; then
			DODATA="YES"
			mkdir -p ${FOLDER}/data
			mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} | gzip > ${FOLDER}/data/drop-$(date +%Y-%m-%d-%H-%M).sql.gz
			mysql -u ${DBUSER} -p${DBPASS} -e "DROP DATABASE ${DBNAME};"
		fi

		if [ "$DODATA" == "YES" ]; then
			mysql -u ${DBUSER} -p${DBPASS} -e "CREATE DATABASE ${DBNAME};"
			zcat ${FOLDER}/data.sql.gz | mysql -u ${DBUSER} -p${DBPASS} ${DBNAME}
		else
			echo "database import failed because conditions doesn't satisfy system"
		fi
	fi
fi







