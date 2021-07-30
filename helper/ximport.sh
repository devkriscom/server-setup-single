#!/bin/bash
DOMAIN=$1
ACTION=$2
FORCED=$3
WEBURL=$4
MYPASS=$5
DOHTML="NO"
DODATA="NO"
TAKEID=$(date +%Y-%m-%d-%H-%M)

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ "$DOMAIN" == "" ]; then
	echo "command: {domain} {all|db|file} {clean|backup} {WEBURL} {dbpass:optional}"
	exit 1;
fi

GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi
if [ "$WEBURL" == '' ]; then
	WEBURL="http://${DOMAIN}";
fi

SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBNAME=$(echo "${DOMAIN}" | sed -e 's/\./_/g')
SHROOT="/home/${SHUSER}";
SHHTML="${SHROOT}/html";

DBPASS=$(cat ${SHROOT}/.dbpass | head -n 1 | awk '{print}')
if [ "$MYPASS" != '' ]; then
	DBPASS="${MYPASS}";
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "file" ]; then
	sudo mkdir -p ${SHROOT}/data
	if [ -d "$SHHTML" ] && [ -f "${SHROOT}/file.tar.gz" ]; then
		if [ "$(ls -A $SHHTML)" ]; then
			echo "${SHHTML} not empty, checking.."
			if [ "$FORCED" == "clean" ]; then
				DOHTML="YES"
				sudo rm -rf ${SHHTML}
				sudo mkdir -p ${SHHTML}
			elif [ "$FORCED" == "backup" ]; then
				DOHTML="YES"
				sudo tar -zcvpf ${SHROOT}/data/${TAKEID}.tar.gz -C ${SHHTML}/ .
				sudo rm -rf ${SHHTML}
				sudo mkdir -p ${SHHTML}
			fi
		else
			DOHTML="YES"
			echo "${SHHTML} empty, continue.."
		fi
	fi

	if [ "$DOHTML" == "YES" ]; then
		echo "start extracting files"
		sudo tar -xvf ${SHROOT}/file.tar.gz -C ${SHROOT}/html

		if [ -f "${SHHTML}/wp-config.php" ]; then
			#sudo sed -i "/DB_HOST/s/'[^']*'/'${DBHOST}'/2" ${SHHTML}/wp-config.php
			sudo sed -i "/DB_NAME/s/'[^']*'/'${DBNAME}'/2" ${SHHTML}/wp-config.php
			sudo sed -i "/DB_USER/s/'[^']*'/'${DBUSER}'/2" ${SHHTML}/wp-config.php
			sudo sed -i "/DB_PASSWORD/s/'[^']*'/'${DBPASS}'/2" ${SHHTML}/wp-config.php
		fi

		if [ -f "${SHHTML}/index.php" ]; then
			if [ -f "${SHHTML}/index.html" ]; then
				sudo rm ${SHHTML}/index.html
			fi
			if [ -f "${SHHTML}/index.htm" ]; then
				sudo rm ${SHHTML}/index.htm
			fi
		fi

		sudo chown -R ${SHUSER}:${SHUSER} ${SHHTML}
	else
		echo "file import failed because conditions doesn't satisfy system"
	fi
fi

if [ "$ACTION" == "all" ] || [ "$ACTION" == "db" ]; then

	if [ -f "${SHROOT}/data.sql.gz" ]; then

		if ! mysql -u ${DBUSER} -p${DBPASS} -e "use ${DBNAME};"; then
			DODATA="YES"
		elif [ "$FORCED" == "clean" ]; then
			DODATA="YES"
			echo "database exists, drop it"
			sudo mysql -u ${DBUSER} -p${DBPASS} -e "DROP DATABASE ${DBNAME};"
		elif [ "$FORCED" == "backup" ]; then
			DODATA="YES"
			echo "database exists, drop it"
			sudo mysqldump -u ${DBUSER} -p${DBPASS} ${DBNAME} | gzip > ${SHROOT}/data/${TAKEID}.sql.gz
			sudo mysql -u ${DBUSER} -p${DBPASS} -e "DROP DATABASE ${DBNAME};"
		fi

		if [ "$DODATA" == "YES" ]; then
			sudo mysql -u ${DBUSER} -p${DBPASS} -e "CREATE DATABASE IF NOT EXISTS ${DBNAME};"
			sudo zcat ${SHROOT}/data.sql.gz | sudo mysql -u ${DBUSER} -p${DBPASS} ${DBNAME}

			if [ -f "${SHHTML}/wp-config.php" ]; then
				TBPREF=$(cat ${SHHTML}/wp-config.php | grep "\$table_prefix" | cut -d \' -f 2)
				sudo mysql -u ${DBUSER} -p${DBPASS} ${DBNAME} -e "UPDATE ${TBPREF}options SET option_value='${WEBURL}' WHERE option_name = 'home' OR option_name = 'siteurl';"
			fi

		else
			echo "database import failed because conditions doesn't satisfy system"
		fi
	fi
fi