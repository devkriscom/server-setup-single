#!/bin/bash
ACTION=$1
DOMAIN=$2
SECURE=$3
WWROOT='/home'
PHPVER=lsphp74
LSPATH="/usr/local/lsws"
SSLDIR="/etc/letsencrypt/live"
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
if [ "$GETWWW" == "www." ]; then
	USEWWW='TRUE'
	ORIGIN="${DOMAIN}"
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-) 
fi

SHMAIL="admin@${DOMAIN}";
SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SHROOT="${WWROOT}/${SHUSER}";
SHHTML="${WWROOT}/${SHUSER}/html";
SHCONF="${VHPATH}/${DOMAIN}/vhconf.conf";

if [ "$ACTION" == 'create' ]; then
	if [ ! -d "${SHHTML}" ] || [ ! -f "$SHCONF" ]; then
		echo "${SHHTML} or ${SHCONF} not exists";
		exit;
	fi

	if [ "$USEWWW" == 'TRUE' ]; then
		certbot certonly --non-interactive --agree-tos -m ${SHMAIL} --webroot -w ${SHHTML} -d ${DOMAIN} -d www.${DOMAIN}
	else
		certbot certonly --non-interactive --agree-tos -m ${SHMAIL} --webroot -w ${SHHTML} -d ${DOMAIN}
	fi

	if [ ${?} -eq 0 ]; then
				echo "
vhssl  {
	certchain 1
	cacertpath ${SSLDIR}/${DOMAIN}/fullchain.pem
	cacertfile ${SSLDIR}/${DOMAIN}/fullchain.pem
	keyfile ${SSLDIR}/${DOMAIN}/privkey.pem
	certfile ${SSLDIR}/${DOMAIN}/fullchain.pem
}" >> ${SHCONF}
				chown -R lsadm:lsadm ${VHPATH}/*
				systemctl restart lsws
			else
					echo "Oops, cant create ssl configuration"
			fi
fi
