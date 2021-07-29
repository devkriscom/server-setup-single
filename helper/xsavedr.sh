#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/files'

mkdir -p ${BKPATH}
for FULLPATH in "$WWROOT"/*; do
  if [ -d "${FULLPATH}/html" ]; then
    USERNAME=$(basename ${FULLPATH})
    tar -zcvpf ${BKPATH}/${USERNAME}-$(date +%Y-%m-%d-%H-%M).tar.gz -C ${FULLPATH}/html/ .
  fi
done
