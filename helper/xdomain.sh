#!/bin/bash

ACTION=$1
DOMAIN=$2
SECURE=$3
WWROOT='/home'
PHPVER=lsphp74
LSPATH='/usr/local/lsws'
VHPATH="${LSPATH}/conf/vhosts"
LSCONF="${LSPATH}/conf/httpd_config.conf"
DBROOT="${WWROOT}/.mysql_root_password"
DBPASS=$(cat ${DBROOT} | head -n 1 | awk '{print}')

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


if [ $(id -u) -eq 0 ]; then
	echo "You have sudo, processing...."
else
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

line_insert(){
    LINENUM=$(grep -n "${1}" ${2} | cut -d: -f 1)
    ADDNUM=${4:-0} 
    if [ -n "$LINENUM" ] && [ "$LINENUM" -eq "$LINENUM" ] 2>/dev/null; then
        LINENUM=$((${LINENUM}+${4}))
        sed -i "${LINENUM}i${3}" ${2}
    fi  
}

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

DATAUSER=$(echo "${DOMAIN}" | sed -e 's/\./-/g')
DATABASE=$(echo "${DOMAIN}" | sed -e 's/\./_/g')
DATAPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '')
USERPASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20; echo '')

SITEROOT="${WWROOT}/${USERNAME}";
SITEHTML="${WWROOT}/${USERNAME}/html";
SITECONF="${VHPATH}/${DOMAIN}/vhconf.conf";

if [ "$ACTION" == 'create' ]; then
	sed -i "/$DOMAIN/d"  ${WWROOT}/.domains
	sed -i "/$USERNAME/d" ${WWROOT}/.usernames
fi

if [ "$ACTION" == 'create' ]; then
	ALLOW="NO"
	# verify if user alreay exist
	egrep "^$USERNAME" /etc/passwd > /dev/null
	if [ $? -eq 0 ]; then
		if [ -d "${SITEROOT}" ]; then
			echo "$USERNAME exists! please create using another user"
			exit 1
		else
			ALLOW="YES"
			usermod -d $SITEROOT $USERNAME
		fi
	else
		useradd -m -p "$USERPASS" "$USERNAME" -d "$SITEROOT"
		if [ $? -eq 0 ]; then
			ALLOW="YES"
		fi
	fi

	if [ "$ALLOW" == 'YES' ]; then
		mkdir -p $SITEHTML
		if [ ! -f "${SITEHTML}/index.php" ]; then
			echo "<?php echo phpinfo(); ?>" > $SITEHTML/index.php
		fi
		chown -R $USERNAME:$USERNAME $SITEROOT
	
		echo "${DOMAIN}" >> ${WWROOT}/.domains
		echo "${USERNAME}" >> ${WWROOT}/.usernames
		echo "${USERPASS}" > ${SITEROOT}/.userpass
		echo "${DATAPASS}" > ${SITEROOT}/.datapass

		echo "\n SFTPD username: $USERNAME";
		echo "\n SFTPD password: $USERPASS";
		echo "\n MySQL rootpass: $DBPASS";
		echo "\n MySQL database: $DATABASE";
		echo "\n MySQL username: $DATAUSER";
		echo "\n MySQL password: $DATAPASS";

		# create database
		if [ -e ${DBROOT} ]; then
			if ! mysql -u root -p${DBPASS} -e "use ${DATABASE};"; then
				mysql -u root -p${DBPASS} -e "create database ${DATABASE};"
				if [ ${?} = 0 ]; then
					mysql -u root -p${DBPASS} -e "CREATE USER '${DATAUSER}'@'%' IDENTIFIED BY '${DATAPASS}';"
					mysql -u root -p${DBPASS} -e "GRANT ALL PRIVILEGES ON * . * TO '${DATAUSER}'@'%';"
					mysql -u root -p${DBPASS} -e "FLUSH PRIVILEGES;"
					mysql -u root -p${DBPASS} -e "SHOW GRANTS FOR '${DATAUSER}'@'%';"
				else
					echo "something went wrong when create new database, please proceed to manual installtion."
				fi
			else
				mysql -u root -p${DBPASS} -e "ALTER USER '${DATAUSER}'@'%' IDENTIFIED BY '${DATAPASS}';"
				mysql -u root -p${DBPASS} -e "FLUSH PRIVILEGES;"
			fi
		else
			echo "Doesnt have ${DBROOT}, skip creating database!" 
		fi  

		#create virtual hosts
		if [ ! -f "${SITECONF}" ]; then
			mkdir -p "${SITECONF%/*}" && touch "$SITECONF"
			cat > ${SITECONF} << EOF
docRoot                   \$VH_ROOT/html
vhDomain                  $DOMAIN
vhAliases                 www.$DOMAIN
adminEmails               $SITEMAIL
enableGzip                1

errorlog \$SITEROOT/logs/error_log {
	useServer               0
	logLevel                ERROR
	rollingSize             10M
}

accesslog \$SITEROOT/logs/access_log {
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
	address                 uds://tmp/lshttpd/${USERNAME}.sock
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
	extUser                 ${USERNAME}
	extGroup                ${USERNAME}
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
vhRoot                  ${SITEROOT}
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
	      certbot certonly --non-interactive --agree-tos -m ${SITEMAIL} --webroot -w ${SITEHTML} -d ${DOMAIN} -d www.${DOMAIN}
	    else
	      certbot certonly --non-interactive --agree-tos -m ${SITEMAIL} --webroot -w ${SITEHTML} -d ${DOMAIN}
	    fi

			if [ ${?} -eq 0 ]; then
				echo "
vhssl  {
	certchain 1
	cacertpath /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
	cacertfile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
	keyfile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
	certfile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
}" >> ${SITECONF}

				echo "\ncertificate has been successfully installed..."  
				systemctl restart lsws
			else
					echo "Oops, cant create ssl configuration"
			fi
		fi
	fi
fi