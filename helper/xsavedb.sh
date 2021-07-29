#!/bin/bash
BKPATH='/var/www/datas'
DBUSER='root';
DBPASS=$(cat /home/.mysql_root_password | head -n 1 | awk '{print}')

if [ ! -d "${BKPATH}" ]; then
	mkdir -p ${BKPATH}
fi
dbs=`mysql -u root -p${DBPASS} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
for db in $dbs; do
	mysqldump -u root -p${DBPASS} ${db} | gzip > ${BKPATH}/$db-$(date +%Y-%m-%d-%H-%M).sql.gz
done