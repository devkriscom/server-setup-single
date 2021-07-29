#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/datas'
DBROOT="${WWROOT}/.mysql_root_password"
DBPASS=$(cat ${DBROOT} | head -n 1 | awk '{print}')

mkdir -p ${BKPATH}
databases=`mysql --user=root -pDBPASS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
for db in $databases; do
	mysqldump -u root -p${DBPASS} ${db} | gzip > ${BKPATH}/$db-$(date +%Y-%m-%d-%H-%M).sql.gz
done