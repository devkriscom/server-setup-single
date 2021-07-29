#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/sites'

for FULLPATH in "$WWROOT"/*; do
  if [ -d "${FULLPATH}/html" ]; then

    USERNAME=$(basename ${FULLPATH})
    BASEPATH=${BKPATH}/${USERNAME}/$(date +%Y-%m-%d-%H-%M)
    mkdir -p ${BASEPATH}
    tar -zcvpf ${BASEPATH}/file.tar.gz -C ${FULLPATH}/html/ .

    DBPASS=$(cat ${FULLPATH}/.datapass | head -n 1 | awk '{print}')
    if [ "$DBPASS" != '' ]; then
      mysqldump -u ${USERNAME} -p${DBPASS} ${USERNAME} | gzip > ${BASEPATH}/data.sql.gz
    fi
    
  fi
done
