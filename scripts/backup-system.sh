#!/bin/bash

# System Backup Script
# Creates comprehensive backups of the entire system

set -e

BACKUP_DIR="/var/backups/control-panel"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD /root/.mysql_credentials | cut -d'=' -f2)

echo "Starting system backup..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup MySQL databases
echo "Backing up MySQL databases..."
mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > $BACKUP_DIR/mysql_$DATE.sql
gzip $BACKUP_DIR/mysql_$DATE.sql

# Backup website files
echo "Backing up website files..."
tar -czf $BACKUP_DIR/websites_$DATE.tar.gz -C /var/www .

# Backup Apache configuration
echo "Backing up Apache configuration..."
tar -czf $BACKUP_DIR/apache_config_$DATE.tar.gz -C /etc apache2

# Backup mail configuration
echo "Backing up mail configuration..."
tar -czf $BACKUP_DIR/mail_config_$DATE.tar.gz -C /etc postfix dovecot

# Backup control panel
echo "Backing up control panel..."
tar -czf $BACKUP_DIR/control_panel_$DATE.tar.gz -C /opt control-panel

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "System backup completed successfully"
echo "Backup files saved to: $BACKUP_DIR"
