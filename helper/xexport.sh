#!/bin/bash
ORIGIN=$1
TARGET=$2
FORCED=$3
HOSTIP=$4


if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ "$ORIGIN" == "" ] || [ "$TARGET" == "" ] ; then
	echo "command: {domain_origin} {domain_target} {host:ip|domain}"
	exit 1;
fi

ORSHUSER=$(echo "${ORIGIN}" | sed -e 's/\./-/g')
ORDBUSER=$(echo "${ORIGIN}" | sed -e 's/\./-/g')
ORDBNAME=$(echo "${ORIGIN}" | sed -e 's/\./_/g')
ORSHROOT="/home/${ORSHUSER}";
ORSHHTML="${ORSHROOT}/html";
ORDBPASS=$(cat ${ORSHROOT}/.dbpass | head -n 1 | awk '{print}')

TOSHUSER=$(echo "${TARGET}" | sed -e 's/\./-/g')
TOSHROOT="/home/${TOSHUSER}";

if [ ! -d "${ORSHROOT}/export" ]; then
	mkdir -p ${ORSHROOT}/export
fi

DOFILE="NO"
if [ -f "${ORSHROOT}/export/file.tar.gz" ]; then
	if [ "$FORCED" == "force" ]; then
		DOFILE="YES"
		rm ${ORSHROOT}/export/file.tar.gz
	fi
else
	DOFILE="YES"
fi
if [ "$DOFILE" == "YES" ]; then
	tar -zcvpf ${ORSHROOT}/export/file.tar.gz -C ${ORSHROOT}/html .
fi


DODATA="NO"
if [ -f "${ORSHROOT}/export/data.sql.gz" ]; then
	if [ "$FORCED" == "force" ]; then
		DODATA="YES"
		rm ${ORSHROOT}/export/data.sql.gz
	fi
else
	DODATA="YES"
fi

if [ "$DODATA" == "YES" ]; then
	mysqldump -u ${ORDBUSER} -p${ORDBPASS} ${ORDBNAME} | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > ${ORSHROOT}/export/data.sql.gz
fi

if [ "$HOSTIP" != "" ]; then
	scp -r ${ORSHROOT}/export/* ${TOSHUSER}@${HOSTIP}:/home/${TOSHUSER}/import/
	rm -rf ${ORSHROOT}/export/*
else
	rm -rf ${TOSHROOT}/import/*
	cp -r ${ORSHROOT}/export/* ${TOSHROOT}/import/
	rm -rf ${ORSHROOT}/export/*
fi