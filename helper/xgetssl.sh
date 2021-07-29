#!/bin/bash

ACTION=$1
DOMAIN=$2
SECURE=$3
WWROOT='/home'
PHPVER=lsphp74
LSPATH='/usr/local/lsws'
VHPATH="${LSPATH}/conf/vhosts"
LSCONF="${LSPATH}/conf/httpd_config.conf"

if [ "$ACTION" != 'create' ] && [ "$ACTION" != 'delete' ]; then
	echo $"You need to select ACTION (create or delete) -- Lower-case only"
	exit 1;
fi

while [ "$DOMAIN" == "" ]; do
	echo $"You need provide DOMAIN eg: create DOMAIN.com"
	exit 1;
done

if [ $(id -u) -eq 0 ]; then
	echo "You have sudo, processing...."
else
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

#check if use www
USEWWW=''
GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
echo "domain www check: $GETWWW"
if [ "$GETWWW" == "www." ]; then
	USEWWW='TRUE'
	ORIGIN="${DOMAIN}"
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
	echo "$DOMAIN using www: $USEWWW" 
else
	echo "$DOMAIN without www"  
fi

SITEMAIL="admin@${DOMAIN}";
USERNAME=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SITEROOT="${WWROOT}/${USERNAME}";
SITEHTML="${WWROOT}/${USERNAME}/html";

if [ "$ACTION" == 'create' ]; then
	if [ "$USEWWW" == 'TRUE' ]; then
		certbot certonly --non-interactive --agree-tos -m ${SITEMAIL} --webroot -w ${SITEHTML} -d ${DOMAIN} -d www.${DOMAIN}
	else
		certbot certonly --non-interactive --agree-tos -m ${SITEMAIL} --webroot -w ${SITEHTML} -d ${DOMAIN}
	fi
fi
