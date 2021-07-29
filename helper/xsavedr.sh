#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/backup'
FOLDER=${BKPATH}/file/$(date +%Y-%m-%d)
mkdir -p ${FOLDER}
for entry in "$WWROOT"/*; do
  if [ -d "${entry}/html" ]; then
    name=$(basename ${entry})
    tar -zcvpf $FOLDER/$name-$(date +%Y-%m-%d-%H-%M).tar.gz $entry/html
  fi
done
