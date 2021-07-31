#!/bin/bash
BKPATH='/var/www/datas'
DBUSER='root';
DBPASS=$(cat /home/.dbrootpass | head -n 1 | awk '{print}')

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ ! -d "${BKPATH}" ]; then
	mkdir -p ${BKPATH}
fi

dbs=`mysql -u root -p${DBPASS} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
for db in $dbs; do
	mysqldump -u root -p${DBPASS} ${db} | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > ${BKPATH}/$db-$(date +%Y-%m-%d-%H-%M).sql.gz
done