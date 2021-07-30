#!/bin/bash
ACTION=$1
DOMAIN=$2
SECURE=$3
WWROOT="/home"
PHPVER=lsphp74
LSPATH="/usr/local/lsws"
SSLDIR="/etc/letsencrypt/live"
VHPATH="${LSPATH}/conf/vhosts"
LSCONF="${LSPATH}/conf/httpd_config.conf"
DBROOT=$(cat /home/.dbrootpass | head -n 1 | awk '{print}')

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi


if [ "$ACTION" != 'create' ] && [ "$ACTION" != 'delete' ]; then
	echo $"You need to select ACTION (create or delete) -- Lower-case only"
	exit 1;
fi

while [ "$DOMAIN" == "" ]; do
	echo $"You need provide DOMAIN eg: create DOMAIN.com"
	exit 1;
done

while [ "$SECURE" == "" ]; do
	echo -e $"SSL (auto|none):"
	read SECURE
done




line_insert(){
    LINENUM=$(grep -n "${1}" ${2} | cut -d: -f 1)
    ADDNUM=${4:-0} 
    if [ -n "$LINENUM" ] && [ "$LINENUM" -eq "$LINENUM" ] 2>/dev/null; then
        LINENUM=$((${LINENUM}+${4}))
        sed -i "${LINENUM}i${3}" ${2}
    fi  
}

USEWWW=''
GETWWW=$(echo "${DOMAIN}" | cut -c 1-4)
if [ "$GETWWW" == "www." ]; then
	USEWWW='TRUE'
	ORIGIN="${DOMAIN}"
	DOMAIN=$(echo "${DOMAIN}" | cut -c 5-)
fi

SHMAIL="admin@${DOMAIN}";
SHUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
SHROOT="/home/${SHUSER}";
SHHTML="${SHROOT}/html";
SHLOGS="${SHROOT}/logs";
SHCONF="${VHPATH}/${DOMAIN}/vhconf.conf";
SHPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '')

DBNAME=$(echo "${DOMAIN}" | sed -e 's/\./_/g')
DBUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DBPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '')

if [ "$ACTION" == 'create' ]; then
	ALLOW="NO"
	# verify if user alreay exist
	egrep "^$SHUSER" /etc/passwd > /dev/null
	if [ $? -eq 0 ]; then
		if [ ! -f "${SHCONF}" ]; then
			ALLOW="YES"
			# if user exists but doesn't have site, then reassign
			if [ ! -d "${SHROOT}" ]; then
				mkdir -p $SHROOT
			fi
			usermod -d $SHROOT $SHUSER
		fi
	else
		useradd -m -p $(perl -e 'print crypt($ARGV[0], "password")' ${SHPASS}) "$SHUSER" -d "$SHROOT"
		if [ $? -eq 0 ]; then
			ALLOW="YES"
		fi
	fi

	if [ "$ALLOW" == 'YES' ]; then
		if [ ! -d "${SHHTML}" ]; then
			mkdir -p $SHHTML
		fi

		if [ ! -d "${SHLOGS}" ]; then
			mkdir -p ${SHLOGS}
		fi

		if [ ! -f "${SHLOGS}/error_log" ]; then
			touch ${SHLOGS}/error_log
		fi

		if [ ! -f "${SHLOGS}/access_log" ]; then
			touch ${SHLOGS}/access_log
		fi

		chown -R $SHUSER:$SHUSER $SHROOT
	
		echo "${SHPASS}" > ${SHROOT}/.shpass
		echo "${DBPASS}" > ${SHROOT}/.dbpass

		echo "\n MySQL rootpass: $DBROOT";
		echo "\n MySQL database: $DBNAME";
		echo "\n MySQL username: $DBUSER";
		echo "\n MySQL password: $DBPASS";
		echo "\n SFTPD username: $SHUSER";
		echo "\n SFTPD password: $SHPASS";

		# create database
		if [ "${DBROOT}" != "" ]; then
			if ! mysql -u root -p${DBROOT} -e "use ${DBNAME};"; then
				mysql -u root -p${DBROOT} -e "CREATE DATABASE ${DBNAME};"
				mysql -u root -p${DBROOT} -e "CREATE USER '${DBUSER}'@'%' IDENTIFIED BY '${DBPASS}';"
				mysql -u root -p${DBROOT} -e "GRANT ALL PRIVILEGES ON * . * TO '${DBUSER}'@'%';"
			else
				mysql -u root -p${DBROOT} -e "ALTER USER '${DBUSER}'@'%' IDENTIFIED BY '${DBPASS}';"
			fi
			mysql -u root -p${DBROOT} -e "FLUSH PRIVILEGES;"
			mysql -u root -p${DBROOT} -e "SHOW GRANTS FOR '${DBUSER}'@'%';" 
		fi  

		#create virtual hosts
		if [ ! -f "${SHCONF}" ]; then
			mkdir -p "${SHCONF%/*}" && touch "$SHCONF"
			cat > ${SHCONF} << EOF
docRoot                   \$VH_ROOT/html
vhDomain                  $DOMAIN
vhAliases                 www.$DOMAIN
adminEmails               $SHMAIL
enableGzip                1

errorlog \$SHROOT/logs/error_log {
	useServer               0
	logLevel                ERROR
	rollingSize             10M
}

accesslog \$SHROOT/logs/access_log {
	useServer               0
	logFormat               "%v %h %l %u %t "%r" %>s %b"
	logHeaders              5
	rollingSize             10M
	keepDays                10
}

index  {
	useServer               1
	indexFiles              index.php, index.html
}

scripthandler  {
	add                     lsapi:${PHPVER} php
}

extprocessor ${PHPVER} {
	type                    lsapi
	address                 uds://tmp/lshttpd/${SHUSER}.sock
	maxConns                35
	env                     PHP_LSAPI_CHILDREN=35
	initTimeout             60
	retryTimeout            0
	persistConn             1
	respBuffer              0
	autoStart               1
	path                    ${LSPATH}/${PHPVER}/bin/lsphp
	backlog                 100
	instances               1
	extUser                 ${SHUSER}
	extGroup                ${SHUSER}
	runOnStartUp            1
	priority                0
	memSoftLimit            2047M
	memHardLimit            2047M
	procSoftLimit           400
	procHardLimit           500
}

rewrite  {
	enable                  1
	autoLoadHtaccess        1
}
EOF

			echo "
virtualhost ${DOMAIN} {
vhRoot                  ${SHROOT}
configFile              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/vhconf.conf
allowSymbolLink         1
enableScript            1
restrained              1
}" >> ${LSCONF}

			if [ "$USEWWW" == 'TRUE' ]; then
		        MAPPER="map                    ${DOMAIN} ${ORIGIN}, ${DOMAIN}"
		    else
		        MAPPER="map                    ${DOMAIN} ${DOMAIN}" 
		    fi

		    PORT_ARR=$(grep "address.*:[0-9]"  ${LSCONF} | awk '{print substr($2,3)}')
		    if [  ${#PORT_ARR[@]} != 0 ]; then
		        for PORT in ${PORT_ARR[@]}; do 
		            line_insert ":${PORT}$"  ${LSCONF} "${MAPPER}" 2
		        done
		    else
		        echo 'No listener port detected, listener setup skip!'    
		    fi

			echo "Updating ${LSCONF} with new virtuals host record" 
			chown -R lsadm:lsadm ${VHPATH}/*
			systemctl restart lsws
		else
			echo "Targeted file already exist, skip!"
		fi

		# create ssl cerfiticate
		if [ "$SECURE" == 'auto' ]; then

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
	fi
fi