#!/bin/bash

# WordPress Installation Script for Control Panel
# This script automatically installs WordPress for new domains

set -e

DOMAIN=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4

if [ -z "$DOMAIN" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    echo "Usage: $0 <domain> <db_name> <db_user> <db_pass>"
    exit 1
fi

DOCUMENT_ROOT="/var/www/$DOMAIN"

echo "Installing WordPress for $DOMAIN..."

# Download WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Move WordPress files
sudo mv wordpress/* $DOCUMENT_ROOT/
sudo chown -R www-data:www-data $DOCUMENT_ROOT
sudo chmod -R 755 $DOCUMENT_ROOT

# Create wp-config.php
sudo cp $DOCUMENT_ROOT/wp-config-sample.php $DOCUMENT_ROOT/wp-config.php

# Configure database settings
sudo sed -i "s/database_name_here/$DB_NAME/" $DOCUMENT_ROOT/wp-config.php
sudo sed -i "s/username_here/$DB_USER/" $DOCUMENT_ROOT/wp-config.php
sudo sed -i "s/password_here/$DB_PASS/" $DOCUMENT_ROOT/wp-config.php

# Generate WordPress salts
SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sudo sed -i "/AUTH_KEY/,/NONCE_SALT/c\\$SALTS" $DOCUMENT_ROOT/wp-config.php

# Set proper permissions
sudo find $DOCUMENT_ROOT -type d -exec chmod 755 {} \;
sudo find $DOCUMENT_ROOT -type f -exec chmod 644 {} \;

echo "WordPress installed successfully for $DOMAIN"
echo "Visit http://$DOMAIN to complete the installation"
