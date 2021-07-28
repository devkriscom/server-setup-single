#!/bin/sh
pass="s3cr3t"
for db in $(mysql -u root -p$pass -e 'show databases' -s --skip-column-names); do
    mysqldump $db | gzip > /home/backups/$db_$(date +%Y-%m-%d@%H:%M).sql.gz
done

DATETIME=$(date +"%F")
BACUP_PATH="/backup/$DATETIME"
USER="backup"
MYSQL=/usr/bin/mysql
PASSWORD="password"
MYSQLDUMP=/usr/bin/mysqldump
 
mkdir -p "$BACUP_PATH/mysql"
 
databases=`$MYSQL --user=$USER -p$PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
 
for db in $databases; do
 $MYSQLDUMP --force --opt --user=$USER -p$PASSWORD --databases $db | gzip > "$BACUP_PATH/mysql/$db.gz"
done