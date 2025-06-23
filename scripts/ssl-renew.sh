#!/bin/bash

# SSL Certificate Renewal Script
# Automatically renews Let's Encrypt certificates

set -e

echo "Starting SSL certificate renewal..."

# Renew certificates
certbot renew --quiet --no-self-upgrade

# Reload Apache to use new certificates
systemctl reload apache2

# Log renewal
echo "$(date): SSL certificates renewed" >> /var/log/ssl-renewal.log

echo "SSL certificate renewal completed"
