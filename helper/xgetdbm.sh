echo "Download phpmyadmin"
mkdir -p ${WWROOT}/managedb
wget -P ${WWROOT}/managedb https://files.phpmyadmin.net/phpMyAdmin/${DBMNUM}/phpMyAdmin-${DBMNUM}-all-languages.zip
unzip ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages.zip -d ${WWROOT}/managedb/
mv ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages ${WWROOT}/managedb/html
rm ${WWROOT}/managedb/phpMyAdmin-${DBMNUM}-all-languages.zip