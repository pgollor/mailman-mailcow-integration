#!/bin/bash

#set -o pipefail

# check of existing mailcow config file
if [ ! -f mailcow.conf ]; then
	echo "No mailcow.conf exists. Please configure mailcow before."
	exit 1
fi

# check for existing mailman configuration in mailcow.conf
if grep -q '# mailman configuration' mailcow.conf; then
	echo "A mailman configuration already exists in mailcow.conf"
	exit 1
fi


echo "I need to ask you some questions of your server configuration. Please enter the needed information or press enter if a default value is present."
# ask for domain
DETECTED_DOMAIN=$(grep MAILCOW_HOSTNAME mailcow.conf)
DETECTED_DOMAIN=$(expr ${DETECTED_DOMAIN} : '^MAILCOW_HOSTNAME=[^.]\+\.\(.*\..*$\)')
while [ -z "${MAILMAN_DOMAIN}" ]; do
	read -p "Mail domain like example.com [${DETECTED_DOMAIN}]: " -e MAILMAN_DOMAIN
	[ -z "${MAILMAN_DOMAIN}" ] && MAILMAN_DOMAIN="${DETECTED_DOMAIN}"
	DOTS=${MAILMAN_DOMAIN//[^.]};
	if [ ${#DOTS} -lt 1 ] && [ ! -z ${MAILMAN_DOMAIN} ]; then
		echo "${MAILMAN_DOMAIN} seems not to be a vaild mail domain"
		MAILMAN_DOMAIN=
	fi
done

# ask for mailinglist domain
while [ -z "${MAILMAN_LIST_DOMAIN}" ]; do
	read -p "Mailman list domain [list.${MAILMAN_DOMAIN}]: " -e MAILMAN_LIST_DOMAIN
	[ -z "${MAILMAN_LIST_DOMAIN}" ] && MAILMAN_LIST_DOMAIN="list.${MAILMAN_DOMAIN}" # replace with default if is empty
	DOTS=${MAILMAN_LIST_DOMAIN//[^.]};
	if [ ${#DOTS} -lt 1 ] && [ ! -z ${MAILMAN_LIST_DOMAIN} ]; then
		echo "${MAILMAN_LIST_DOMAIN} seems not to be a vaild mail domain"
		MAILMAN_LIST_DOMAIN=
	fi
done

# ask for admin email address
while [ -z "${MAILMAN_ADMIN_EMAIL}" ]; do
	read -p "Email address for the mailman admin user [listadmin@${MAILMAN_DOMAIN}]: " -e MAILMAN_ADMIN_EMAIL
	[ -z "${MAILMAN_ADMIN_EMAIL}" ] && MAILMAN_ADMIN_EMAIL="listadmin@${MAILMAN_DOMAIN}" # replace with default if is empty
	AT=${MAILMAN_ADMIN_EMAIL//[^@]};
	if [ ${#AT} -ne 1 ] && [ ! -z ${MAILMAN_ADMIN_EMAIL} ]; then
		echo "Invalid email detected"
		MAILMAN_ADMIN_EMAIL=
	fi
done

# ask for mailman smtp user email address
while [ -z "${MAILMAN_SMTP_USER}" ]; do
	read -p "SMTP user for mailman [mailman@${MAILMAN_DOMAIN}]: " -e MAILMAN_SMTP_USER
	[ -z "${MAILMAN_SMTP_USER}" ] && MAILMAN_SMTP_USER="mailman@${MAILMAN_DOMAIN}" # replace with default if is empty
	AT=${MAILMAN_SMTP_USER//[^@]};
	if [ ${#AT} -ne 1 ] && [ ! -z ${MAILMAN_SMTP_USER} ]; then
		echo "Invalid email detected"
		MAILMAN_SMTP_USER=
	fi
done

read -s -p "Password for ${MAILMAN_SMTP_USER}: " -e MAILMAN_SMTP_PASSWORD1

echo "Mailman list domain: ${MAILMAN_LIST_DOMAIN}"
echo "Mailman admin user email address: ${MAILMAN_ADMIN_EMAIL}"
echo "SMTP user for mailman: ${MAILMAN_SMTP_USER}"


# copy and prepare mailcow configuration
cat << EOF >> mailcow.conf

# mailman configuration
MAILMAN_WEB_PORT=127.0.0.1:8080
MAILMAN_SECRET_KEY=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 30)
MAILMAN_HYPERKITTY_API_KEY=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 30)
MAILMAN_SERVE_FROM_DOMAIN=${MAILMAN_LIST_DOMAIN}
MAILMAN_DB_PASSWORD=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 28)
MAILMAN_ADMIN_USER=admin
MAILMAN_ADMIN_EMAIL=${MAILMAN_ADMIN_EMAIL}
MAILMAN_SMTP_PORT=587
MAILMAN_SMTP_HOST_USER=${MAILMAN_SMTP_USER}
MAILMAN_SMTP_HOST_PASSWORD=${MAILMAN_SMTP_PASSWORD}
MAILMAN_SMTP_USE_TLS=true

EOF


# some replace in mailman config files
sed -i "/^site_owner:/c\\\site_owner:${MAILMAN_SMTP_USER}" data/mailman/core/mailman-extra.cfg
sed -i "/^DEFAULT_FROM_EMAIL/c\\\DEFAULT_FROM_EMAIL='${MAILMAN_SMTP_USER}'" data/mailman/web/settings_local.py
