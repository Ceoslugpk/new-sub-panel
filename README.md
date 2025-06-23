# VPS Control Panel - Complete Installation Guide

A comprehensive web hosting control panel that rivals cPanel and Plesk, designed specifically for VPS deployment with automated installation.

## 🚀 One-Command Installation

\`\`\`bash
# Download and run the installer
wget https://raw.githubusercontent.com/your-repo/vps-control-panel/main/install.sh
chmod +x install.sh
sudo ./install.sh
\`\`\`

**That's it!** The script will automatically install and configure everything needed for a complete hosting control panel.

## ✨ What Gets Installed

### Core Services
- **Apache Web Server** - Latest version with SSL support
- **MySQL/MariaDB** - Database server with phpMyAdmin
- **PHP 8.1** - With all required extensions
- **Postfix + Dovecot** - Complete email server (SMTP, POP3, IMAP)
- **ProFTPD** - FTP server for file transfers
- **BIND** - DNS server for domain management
- **Let's Encrypt** - Free SSL certificate automation
- **Fail2Ban** - Security and intrusion prevention

### Control Panel Features
- **Real-time System Monitoring** - CPU, Memory, Disk, Network
- **Service Management** - Start, stop, restart all services
- **Database Management** - Create databases, users, phpMyAdmin access
- **Email Management** - Create email accounts, forwarders, filters
- **Domain Management** - Add domains, subdomains, DNS configuration
- **SSL Certificate Management** - Automatic Let's Encrypt integration
- **File Management** - Web-based file manager
- **Security Management** - Firewall, IP blocking, 2FA
- **Backup System** - Automated daily backups
- **User Management** - Multi-user support with permissions

## 🖥️ System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+, Debian 10+, or CentOS 8+
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB (50GB recommended)
- **CPU**: 1 vCPU (2 vCPU recommended)

### Recommended Setup
- **OS**: Ubuntu 22.04 LTS
- **RAM**: 8GB
- **Storage**: 100GB SSD
- **CPU**: 4 vCPU

## 📋 Installation Process

The installation script automatically:

1. **System Updates** - Updates all packages to latest versions
2. **Service Installation** - Installs Apache, MySQL, PHP, Mail servers
3. **Security Setup** - Configures firewall, Fail2Ban, SSL
4. **Control Panel** - Installs and configures the web interface
5. **Database Setup** - Creates control panel database and users
6. **Automation** - Sets up cron jobs for backups and maintenance
7. **Configuration** - Optimizes all services for VPS environment

## 🌐 Access Your Control Panel

After installation, access your services at:

- **Control Panel**: `http://YOUR_SERVER_IP:3000`
- **phpMyAdmin**: `http://YOUR_SERVER_IP/phpmyadmin`
- **Welcome Page**: `http://YOUR_SERVER_IP`

### Default Login Credentials
- **Username**: `admin`
- **Password**: `admin123`
- **⚠️ IMPORTANT**: Change this password immediately after first login!

## 🔧 Post-Installation Setup

### 1. Secure Your Installation
\`\`\`bash
# Change admin password in control panel
# Update MySQL root password if needed
# Configure firewall rules for your needs
\`\`\`

### 2. Add Your First Domain
1. Go to "Domain Management" → "Addon Domains"
2. Enter your domain name
3. Set document root (e.g., `/var/www/yourdomain.com`)
4. Click "Create Domain"

### 3. Set Up SSL Certificate
1. Go to "Security" → "SSL/TLS Certificates"
2. Enter your domain and email
3. Click "Generate Certificate"
4. Certificate will be automatically installed

### 4. Create Email Accounts
1. Go to "Email Management" → "Email Accounts"
2. Enter email address and password
3. Set quota and options
4. Configure your email client with provided settings

## 📊 Features Overview

### System Monitoring
- Real-time CPU, memory, disk usage
- Network traffic monitoring
- Service status monitoring
- System load and uptime tracking

### Database Management
- MySQL database creation and management
- User management with permissions
- phpMyAdmin web interface
- Automated backups
- Remote access configuration

### Email Server
- **SMTP**: Port 587 (STARTTLS) or 465 (SSL)
- **IMAP**: Port 993 (SSL) or 143 (STARTTLS)
- **POP3**: Port 995 (SSL) or 110 (STARTTLS)
- Anti-spam protection with SpamAssassin
- Email forwarding and aliases

### Web Server Management
- Apache virtual host management
- PHP version management
- SSL certificate automation
- .htaccess support
- Custom error pages

### Security Features
- UFW/FirewallD firewall management
- Fail2Ban intrusion prevention
- SSL/TLS certificate management
- IP access control
- Security scanning and monitoring

## 🛠️ Management Commands

### Control Panel Service
\`\`\`bash
# Check status
sudo systemctl status control-panel

# Start/Stop/Restart
sudo systemctl start control-panel
sudo systemctl stop control-panel
sudo systemctl restart control-panel

# View logs
sudo journalctl -u control-panel -f
\`\`\`

### Other Services
\`\`\`bash
# Apache
sudo systemctl restart apache2

# MySQL
sudo systemctl restart mysql

# Email services
sudo systemctl restart postfix
sudo systemctl restart dovecot

# FTP
sudo systemctl restart proftpd
\`\`\`

## 💾 Backup System

### Automated Backups
- **Daily**: MySQL databases
- **Weekly**: Website files
- **Monthly**: Full system backup
- **Retention**: 7 days for daily, 4 weeks for weekly

### Manual Backup
\`\`\`bash
# Run backup script
sudo /opt/control-panel/scripts/backup-system.sh

# Backup location
ls -la /var/backups/control-panel/
\`\`\`

### Restore from Backup
\`\`\`bash
# Restore database
mysql -u root -p < /var/backups/control-panel/mysql_backup.sql

# Restore files
tar -xzf /var/backups/control-panel/websites_backup.tar.gz -C /var/www/
\`\`\`

## 🔍 Troubleshooting

### Control Panel Not Loading
\`\`\`bash
# Check if service is running
sudo systemctl status control-panel

# Check logs for errors
sudo journalctl -u control-panel -n 50

# Restart the service
sudo systemctl restart control-panel
\`\`\`

### Database Connection Issues
\`\`\`bash
# Check MySQL status
sudo systemctl status mysql

# Test connection
mysql -u root -p

# Check credentials
cat /root/.mysql_credentials
\`\`\`

### Email Not Working
\`\`\`bash
# Check mail services
sudo systemctl status postfix
sudo systemctl status dovecot

# Check mail logs
sudo tail -f /var/log/mail.log

# Test email sending
echo "Test" | mail -s "Test Email" user@domain.com
\`\`\`

### Apache Issues
\`\`\`bash
# Check Apache status
sudo systemctl status apache2

# Test configuration
sudo apache2ctl configtest

# Check error logs
sudo tail -f /var/log/apache2/error.log
\`\`\`

## 📁 Important File Locations

- **Control Panel**: `/opt/control-panel/`
- **Web Files**: `/var/www/html/`
- **MySQL Credentials**: `/root/.mysql_credentials`
- **Backups**: `/var/backups/control-panel/`
- **Apache Config**: `/etc/apache2/sites-available/`
- **PHP Config**: `/etc/php/8.1/apache2/php.ini`
- **Mail Config**: `/etc/postfix/` and `/etc/dovecot/`

## 🔒 Security Best Practices

### After Installation
1. **Change all default passwords**
2. **Configure SSH key authentication**
3. **Disable root SSH login**
4. **Set up automatic security updates**
5. **Configure backup retention**
6. **Monitor system logs regularly**

### Firewall Configuration
\`\`\`bash
# Check firewall status
sudo ufw status

# Allow specific ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
\`\`\`

## 🆘 Support

### Getting Help
1. **Check logs**: Most issues can be diagnosed from service logs
2. **Documentation**: This README covers most common scenarios
3. **Community**: Join our Discord/Forum for community support
4. **Issues**: Report bugs on GitHub

### Log Files
- **Control Panel**: `journalctl -u control-panel`
- **Apache**: `/var/log/apache2/error.log`
- **MySQL**: `/var/log/mysql/error.log`
- **Mail**: `/var/log/mail.log`
- **System**: `/var/log/syslog`

## 🔄 Updates

### Updating the Control Panel
\`\`\`bash
cd /opt/control-panel
git pull origin main
npm install
npm run build
sudo systemctl restart control-panel
\`\`\`

### System Updates
\`\`\`bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js if needed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
\`\`\`

## 🎯 Advanced Configuration

### Custom PHP Settings
Edit `/etc/php/8.1/apache2/php.ini`:
\`\`\`ini
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
\`\`\`

### MySQL Optimization
Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`:
\`\`\`ini
innodb_buffer_pool_size = 1G
max_connections = 200
query_cache_size = 64M
\`\`\`

### Apache Performance
Enable compression and caching:
\`\`\`bash
sudo a2enmod deflate
sudo a2enmod expires
sudo a2enmod headers
sudo systemctl restart apache2
\`\`\`

## 📈 Monitoring and Maintenance

### System Health Checks
The control panel provides real-time monitoring of:
- CPU usage and load average
- Memory utilization
- Disk space usage
- Network traffic
- Service status
- Security alerts

### Automated Maintenance
- **Daily**: System backups, log rotation
- **Weekly**: Security updates, cleanup
- **Monthly**: Full system health check

## 🌟 Features Roadmap

### Planned Features
- [ ] WordPress one-click installer
- [ ] Let's Encrypt wildcard certificates
- [ ] Advanced file manager with code editor
- [ ] Email webmail interface
- [ ] DNS cluster management
- [ ] Load balancer configuration
- [ ] Container management (Docker)
- [ ] Advanced monitoring and alerting

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

**VPS Control Panel** - Professional hosting management made simple.

For the latest updates and documentation, visit: https://github.com/your-repo/vps-control-panel
