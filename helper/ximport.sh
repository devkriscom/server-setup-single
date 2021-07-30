#!/bin/bash
DOMAIN=$1
ACTION=$2
FORCED=$3
MYPASS=$4
DOHTML="NO"
DODATA="NO"

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

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
SHROOT="/home/${SHUSER}";

DBPASS=$(cat ${SHROOT}/.dbpass | head -n 1 | awk '{print}')
if [ "$MYPASS" != '' ]; then
	DBPASS="${MYPASS}";
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "file" ]; then

	if [ -d "$SHROOT/html" ] && [ -f "${SHROOT}/file.tar.gz" ]; then
		if [ ! "$(ls -A $SHROOT/html)" ]; then
			if [ "$FORCED" == "force" ]; then
				DOHTML="YES"
				rm -rf ${SHROOT}/html/*
			fi
		else
			DOHTML="YES"
		fi
	fi

	if [ "$DOHTML" == "YES" ]; then
		tar -xvf ${SHROOT}/file.tar.gz -C ${SHROOT}/html
		if [ -f "$SHROOT/html/wp-config.php" ]; then
			sed "/DB_HOST/s/'[^']*'/'${DBPASS}'/2" ${SHROOT}/html/wp-config.php
			sed "/DB_NAME/s/'[^']*'/'${DBNAME}'/2" ${SHROOT}/html/wp-config.php
			sed "/DB_USER/s/'[^']*'/'${DBUSER}'/2" ${SHROOT}/html/wp-config.php
			sed "/DB_PASSWORD/s/'[^']*'/'${DBPASS}'/2" ${SHROOT}/html/wp-config.php
		fi
		chown -R ${SHUSER}:${SHUSER} /home/${SHUSER}/html
	else
		echo "file import failed because conditions doesn't satisfy system"
	fi
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "db" ]; then
 
	if [ -f "${SHROOT}/data.sql.gz" ]; then

		if ! mysql -u ${DBUSER} -p${DBPASS} -e "use ${DBNAME};"; then
			DODATA="YES"
		elif [ "$FORCED" == "force" ]; then
			DODATA="YES"
			mkdir -p ${SHROOT}/data
			mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} | gzip > ${SHROOT}/data/drop-$(date +%Y-%m-%d-%H-%M).sql.gz
			mysql -u ${DBUSER} -p${DBPASS} -e "DROP DATABASE ${DBNAME};"
		fi

		if [ "$DODATA" == "YES" ]; then
			mysql -u ${DBUSER} -p${DBPASS} -e "CREATE DATABASE ${DBNAME};"
			zcat ${SHROOT}/data.sql.gz | mysql -u ${DBUSER} -p${DBPASS} ${DBNAME}
		else
			echo "database import failed because conditions doesn't satisfy system"
		fi
	fi
fi







