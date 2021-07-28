#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/backup'
DBROOT="${WWROOT}/.mysql_root_password"
DBPASS=$(cat ${DBROOT} | head -n 1 | awk '{print}')
FOLDER=${BKPATH}/database/$(date +%Y-%m-%d)

mkdir -p ${FOLDER}
databases=`mysql --user=root -pDBPASS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
for db in $databases; do
	echo "backup $db now";
	mysqldump $db | gzip > $FOLDER/$db-$(date +%Y-%m-%d-%H-%M).sql.gz
done