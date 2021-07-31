#!/bin/bash
ACTION=$1
GITHUB="https://raw.githubusercontent.com/wordspec/server-setup-single/master"

if [[ $(id -u) -ne 0 ]]; then
	echo "Only root/sudo user allowed. Bye."
	exit 2
fi

if [ "$ACTION" == 'self-update' ]; then
	curl -sO ${GITHUB}/helper.sh
	chmod +x helper.sh
	rm /usr/local/bin/xmaster
	mv helper.sh /usr/local/bin/xmaster
	exit 1
fi

if [ "$ACTION" == 'update' ]; then

	echo "create command: xdomain"
	if [ -f "/usr/local/bin/xdomain" ]; then 
		rm /usr/local/bin/xdomain
	fi
	curl -sO ${GITHUB}/helper/xdomain.sh
	chmod +x xdomain.sh
	mv xdomain.sh /usr/local/bin/xdomain
	
	echo "create command: xsavefx"
	if [ -f "/usr/local/bin/xsavefx" ]; then 
		rm /usr/local/bin/xsavefx
	fi
	curl -sO ${GITHUB}/helper/xsavefx.sh
	chmod +x xsavefx.sh
	mv xsavefx.sh /usr/local/bin/xsavefx

	echo "create command: xsavedb"
	if [ -f "/usr/local/bin/xsavedb" ]; then 
		rm /usr/local/bin/xsavedb
	fi
	curl -sO ${GITHUB}/helper/xsavedb.sh
	chmod +x xsavedb.sh
	mv xsavedb.sh /usr/local/bin/xsavedb

	echo "create command: xsavedr"
	if [ -f "/usr/local/bin/xsavedr" ]; then 
		rm /usr/local/bin/xsavedr
	fi
	curl -sO ${GITHUB}/helper/xsavedr.sh
	chmod +x xsavedr.sh
	mv xsavedr.sh /usr/local/bin/xsavedr

	echo "create command: ximport"
	if [ -f "/usr/local/bin/ximport" ]; then 
		rm /usr/local/bin/ximport
	fi
	curl -sO ${GITHUB}/helper/ximport.sh
	chmod +x ximport.sh
	mv ximport.sh /usr/local/bin/ximport
	
	echo "create command: xgetssl"
	if [ -f "/usr/local/bin/xgetssl" ]; then 
		rm /usr/local/bin/xgetssl
	fi
	curl -sO ${GITHUB}/helper/xgetssl.sh
	chmod +x xgetssl.sh
	mv xgetssl.sh /usr/local/bin/xgetssl

	echo "create command: xrecipe"
	if [ -f "/usr/local/bin/xrecipe" ]; then 
		rm /usr/local/bin/xrecipe
	fi
	curl -sO ${GITHUB}/helper/xrecipe.sh
	chmod +x xrecipe.sh
	mv xrecipe.sh /usr/local/bin/xrecipe

	echo "create command: xscaner"
	if [ -f "/usr/local/bin/xscaner" ]; then 
		rm /usr/local/bin/xscaner
	fi
	curl -sO ${GITHUB}/helper/xscaner.sh
	chmod +x xscaner.sh
	mv xscaner.sh /usr/local/bin/xscaner

	echo "create command: xstatus"
	if [ -f "/usr/local/bin/xstatus" ]; then 
		rm /usr/local/bin/xstatus
	fi
	curl -sO ${GITHUB}/helper/xstatus.sh
	chmod +x xstatus.sh
	mv xstatus.sh /usr/local/bin/xstatus

	echo "create command: xreport"
	if [ -f "/usr/local/bin/xreport" ]; then 
		rm /usr/local/bin/xreport
	fi
	curl -sO ${GITHUB}/helper/xreport.sh
	chmod +x xreport.sh
	mv xreport.sh /usr/local/bin/xreport
	exit 1;
fi

