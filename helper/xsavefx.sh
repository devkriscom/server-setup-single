#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/sites'

for SHROOT in /home/*; do
  if [ -d "${SHROOT}/html" ]; then

    SHUSER=$(basename ${SHROOT})
    DBNAME=$(echo "${SHUSER}" | sed -e 's/\-/_/g')

    BASEPATH=${BKPATH}/${SHUSER}/$(date +%Y-%m-%d-%H-%M)

    if [ ! -d "${BASEPATH}" ]; then
      mkdir -p ${BASEPATH}
    fi

    tar -zcvpf ${BASEPATH}/file.tar.gz -C ${SHROOT}/html/ .
    
    DBPASS=$(cat ${SHROOT}/.datapass | head -n 1 | awk '{print}')
    if [ "$DBPASS" != '' ]; then
      mysqldump -u ${SHUSER} -p${DBPASS} ${DBNAME} | gzip > ${BASEPATH}/data.sql.gz
    fi
    
  fi
done
