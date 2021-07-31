#!/bin/bash
WWROOT='/home'
BKPATH='/var/www/sites'
DRHTML='html'

if [[ $(id -u) -ne 0 ]]; then
  echo "Only root/sudo user allowed. Bye."
  exit 2
fi

for SHROOT in /home/*; do
  if [ -d "${SHROOT}/${DRHTML}" ]; then
    SHUSER=$(basename ${SHROOT})
    SHHTML="${SHROOT}/${DRHTML}"
    DBNAME=$(echo "${SHUSER}" | sed -e 's/\-/_/g')

    if [ -f "${SHHTML}/wp-config.php" ]; then
      DBNAME=`cat wp-config.php | grep DB_NAME | cut -d \' -f 4`
      DBUSER=`cat wp-config.php | grep DB_USER | cut -d \' -f 4`
      DBPASS=`cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

      plugins=$(sudo -u ${SHUSER} -i -- wp plugin list --path=${SHHTML} --status=active --format=csv --fields=name)

      for plugin in $plugins; do
        if [ ! "${plugin}" = 'name' ]; then
          echo "${plugin}"
        fi
      done
      
    fi

  fi
done
