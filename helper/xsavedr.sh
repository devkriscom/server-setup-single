#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/files'

if [[ $(id -u) -ne 0 ]]; then
  echo "Only root/sudo user allowed. Bye."
  exit 2
fi

if [ ! -d "${BKPATH}" ]; then
  mkdir -p ${BKPATH}
fi
for SHROOT in /home/*; do
  if [ -d "${SHROOT}/html" ]; then
    SHUSER=$(basename ${SHROOT})
    tar -zcvpf ${BKPATH}/${SHUSER}-$(date +%Y-%m-%d-%H-%M).tar.gz -C ${SHROOT}/html/ .
  fi
done
