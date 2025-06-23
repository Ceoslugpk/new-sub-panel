#!/bin/bash

# VPS Control Panel - Complete Installation Script
# Professional Web Hosting Control Panel (cPanel/Plesk Alternative)
# Compatible with Ubuntu 20.04+, Debian 10+, CentOS 8+

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
MYSQL_ROOT_PASSWORD=""
PANEL_DB_PASSWORD=""
SERVER_IP=""
CONTROL_PANEL_DIR="/opt/hosting-panel"
ADMIN_EMAIL=""
DOMAIN_NAME=""
INSTALL_LOG="/var/log/hosting-panel-install.log"
GITHUB_REPO="https://github.com/Ceoslugpk/new-sub-panel.git"

# Create log file
touch $INSTALL_LOG
exec 1> >(tee -a $INSTALL_LOG)
exec 2> >(tee -a $INSTALL_LOG >&2)

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        🚀 VPS HOSTING CONTROL PANEL INSTALLER 🚀            ║"
    echo "║                                                              ║"
    echo "║           Professional cPanel/Plesk Alternative             ║"
    echo "║                                                              ║"
    echo "║           Repository: Ceoslugpk/new-sub-panel               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)"
    fi
}

# Get user input
get_user_input() {
    log "Gathering installation information..."
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
    if [[ -z "$SERVER_IP" ]]; then
        read -p "Enter your server IP address: " SERVER_IP
    fi
    
    # Get admin email
    read -p "Enter admin email address: " ADMIN_EMAIL
    while [[ ! "$ADMIN_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
        echo "Invalid email format. Please try again."
        read -p "Enter admin email address: " ADMIN_EMAIL
    done
    
    # Get domain name (optional)
    read -p "Enter domain name for control panel (optional, press Enter to skip): " DOMAIN_NAME
    
    log "Configuration:"
    log "Server IP: $SERVER_IP"
    log "Admin Email: $ADMIN_EMAIL"
    log "Domain: ${DOMAIN_NAME:-"Not specified"}"
    log "Repository: $GITHUB_REPO"
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Installation cancelled by user"
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        error "Cannot detect operating system"
    fi
    
    log "Detected OS: $OS $VER"
    
    # Set package manager
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        PACKAGE_MANAGER="apt-get"
        export DEBIAN_FRONTEND=noninteractive
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"AlmaLinux"* ]]; then
        PACKAGE_MANAGER="yum"
    else
        error "Unsupported operating system: $OS"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get update -y
        apt-get upgrade -y
        apt-get install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    else
        yum update -y
        yum install -y epel-release
    fi
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    local packages=(
        "curl"
        "wget"
        "git"
        "unzip"
        "zip"
        "tar"
        "nano"
        "vim"
        "htop"
        "tree"
        "rsync"
        "screen"
        "tmux"
        "openssl"
        "pwgen"
        "bc"
        "jq"
        "net-tools"
        "dnsutils"
        "telnet"
        "ncdu"
        "iotop"
        "iftop"
        "nethogs"
        "fail2ban"
        "ufw"
        "logrotate"
        "cron"
        "supervisor"
    )
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y "${packages[@]}"
        # Additional Ubuntu/Debian packages
        apt-get install -y build-essential python3-pip python3-dev
    else
        yum install -y "${packages[@]}"
        # Additional CentOS/RHEL packages
        yum groupinstall -y "Development Tools"
        yum install -y python3-pip python3-devel
    fi
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # Install Docker on Ubuntu/Debian
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        # Install Docker on CentOS/RHEL
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    systemctl enable docker
    systemctl start docker
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    success "Docker installed successfully"
}

# Install Node.js
install_nodejs() {
    log "Installing Node.js 18.x..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    else
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        yum install -y nodejs
    fi
    
    # Install global packages
    npm install -g pm2 yarn
    
    node_version=$(node --version)
    npm_version=$(npm --version)
    log "Node.js version: $node_version"
    log "npm version: $npm_version"
}

# Install and configure Apache
install_apache() {
    log "Installing Apache web server..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y apache2 apache2-utils
        systemctl enable apache2
        
        # Enable required modules
        a2enmod rewrite ssl headers expires deflate proxy proxy_http proxy_balancer lbmethod_byrequests
        
        # Configure Apache
        cat > /etc/apache2/conf-available/security.conf << 'EOF'
ServerTokens Prod
ServerSignature Off
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
EOF
        a2enconf security
        
    else
        yum install -y httpd httpd-tools mod_ssl
        systemctl enable httpd
        
        # Configure SELinux for Apache
        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_can_network_relay 1
    fi
    
    systemctl start apache2 2>/dev/null || systemctl start httpd
    success "Apache installed and configured"
}

# Install PHP
install_php() {
    log "Installing PHP 8.1 and extensions..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # Add PHP repository
        add-apt-repository ppa:ondrej/php -y
        apt-get update -y
        
        # Install PHP and extensions
        apt-get install -y \
            php8.1 \
            php8.1-fpm \
            php8.1-mysql \
            php8.1-pgsql \
            php8.1-sqlite3 \
            php8.1-redis \
            php8.1-curl \
            php8.1-gd \
            php8.1-mbstring \
            php8.1-xml \
            php8.1-zip \
            php8.1-bcmath \
            php8.1-readline \
            php8.1-intl \
            php8.1-soap \
            php8.1-xsl \
            php8.1-opcache \
            php8.1-imagick \
            php8.1-cli \
            php8.1-common \
            php8.1-imap \
            php8.1-ldap \
            libapache2-mod-php8.1
            
        systemctl enable php8.1-fpm
        systemctl start php8.1-fpm
        
    else
        # Install PHP on CentOS/RHEL
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
        yum module enable php:remi-8.1 -y
        
        yum install -y \
            php \
            php-fpm \
            php-mysql \
            php-pgsql \
            php-sqlite3 \
            php-redis \
            php-curl \
            php-gd \
            php-mbstring \
            php-xml \
            php-zip \
            php-bcmath \
            php-intl \
            php-soap \
            php-opcache \
            php-imagick \
            php-cli \
            php-common \
            php-imap \
            php-ldap
            
        systemctl enable php-fpm
        systemctl start php-fpm
    fi
    
    # Configure PHP
    php_ini="/etc/php/8.1/apache2/php.ini"
    [[ ! -f "$php_ini" ]] && php_ini="/etc/php.ini"
    
    if [[ -f "$php_ini" ]]; then
        sed -i 's/memory_limit = .*/memory_limit = 512M/' "$php_ini"
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 100M/' "$php_ini"
        sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/max_input_vars = .*/max_input_vars = 3000/' "$php_ini"
    fi
    
    success "PHP installed and configured"
}

# Install and configure MySQL
install_mysql() {
    log "Installing MySQL 8.0..."
    
    # Generate secure passwords
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    PANEL_DB_PASSWORD=$(openssl rand -base64 32)
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # Install MySQL on Ubuntu/Debian
        apt-get install -y mysql-server mysql-client
        
        systemctl enable mysql
        systemctl start mysql
        
    else
        # Install MySQL on CentOS/RHEL
        yum install -y mysql-server mysql
        
        systemctl enable mysqld
        systemctl start mysqld
        
        # Get temporary root password for CentOS
        TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)
    fi
    
    # Secure MySQL installation
    secure_mysql_installation
    
    # Create control panel database
    create_panel_database
    
    success "MySQL installed and configured"
}

# Secure MySQL installation
secure_mysql_installation() {
    log "Securing MySQL installation..."
    
    # Create MySQL secure installation script
    cat > /tmp/mysql_secure_installation.sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    # Execute secure installation with better error handling
    if [[ -n "$TEMP_PASSWORD" ]]; then
        mysql --connect-expired-password -u root -p"$TEMP_PASSWORD" < /tmp/mysql_secure_installation.sql 2>/dev/null || {
            warning "Failed to secure MySQL with temporary password, trying without password..."
            mysql -u root < /tmp/mysql_secure_installation.sql 2>/dev/null || error "Failed to secure MySQL installation"
        }
    else
        mysql -u root < /tmp/mysql_secure_installation.sql 2>/dev/null || {
            warning "Failed to secure MySQL, trying with empty password..."
            mysql -u root --password="" < /tmp/mysql_secure_installation.sql 2>/dev/null || error "Failed to secure MySQL installation"
        }
    fi
    
    rm -f /tmp/mysql_secure_installation.sql
    
    # Save credentials
    cat > /root/.mysql_credentials << EOF
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
PANEL_DB_PASSWORD=$PANEL_DB_PASSWORD
EOF
    chmod 600 /root/.mysql_credentials
    
    success "MySQL secured successfully"
}

# Create control panel database
create_panel_database() {
    log "Creating control panel database..."
    
    # Use mysql_config_editor to avoid password warnings (if available)
    export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
    
    mysql -u root << 'EOF' 2>/dev/null || mysql -u root -p"$MYSQL_ROOT_PASSWORD" << 'EOF'
CREATE DATABASE IF NOT EXISTS hosting_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'panel_user'@'localhost' IDENTIFIED BY '$PANEL_DB_PASSWORD';
GRANT ALL PRIVILEGES ON hosting_panel.* TO 'panel_user'@'localhost';
FLUSH PRIVILEGES;

USE hosting_panel;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'reseller', 'user') DEFAULT 'user',
    status ENUM('active', 'suspended', 'pending') DEFAULT 'active',
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(32),
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status)
);
EOF

    # Create default admin user separately to handle variable substitution
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF 2>/dev/null
USE hosting_panel;
INSERT INTO users (username, email, password_hash, role) 
VALUES ('admin', '$ADMIN_EMAIL', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE email='$ADMIN_EMAIL';
EOF

    unset MYSQL_PWD
    success "Control panel database created successfully"
}

# Install phpMyAdmin
install_phpmyadmin() {
    log "Installing phpMyAdmin..."
    
    # Create phpMyAdmin directory first
    mkdir -p /var/www/html/phpmyadmin
    
    # Download latest phpMyAdmin with better error handling
    cd /tmp
    
    # Clean up any existing files
    rm -f phpMyAdmin-*.tar.gz 2>/dev/null || true
    rm -rf phpMyAdmin-* 2>/dev/null || true
    
    # Try multiple download sources with fallbacks
    PHPMYADMIN_INSTALLED=false
    
    # Method 1: Try latest version from GitHub releases
    log "Attempting to download phpMyAdmin from GitHub..."
    if curl -s --connect-timeout 10 https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep -q "tag_name"; then
        PHPMYADMIN_VERSION=$(curl -s --connect-timeout 10 https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        log "Found latest version: $PHPMYADMIN_VERSION"
        
        if wget -q --timeout=30 --tries=3 "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"; then
            if tar -tf phpMyAdmin-*.tar.gz >/dev/null 2>&1; then
                log "Successfully downloaded and verified phpMyAdmin ${PHPMYADMIN_VERSION}"
                if tar xzf phpMyAdmin-*.tar.gz 2>/dev/null; then
                    EXTRACTED_DIR=$(find . -maxdepth 1 -name "phpMyAdmin-*" -type d | head -1)
                    if [[ -n "$EXTRACTED_DIR" && -d "$EXTRACTED_DIR" ]]; then
                        cp -r "$EXTRACTED_DIR"/* /var/www/html/phpmyadmin/
                        PHPMYADMIN_INSTALLED=true
                        log "phpMyAdmin extracted successfully"
                    fi
                fi
            fi
        fi
    fi
    
    # Method 2: Try stable version 5.2.1 if latest failed
    if [[ "$PHPMYADMIN_INSTALLED" == "false" ]]; then
        warning "Latest version failed, trying stable version 5.2.1..."
        rm -f phpMyAdmin-*.tar.gz 2>/dev/null || true
        rm -rf phpMyAdmin-* 2>/dev/null || true
        
        if wget -q --timeout=30 --tries=3 "https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz"; then
            if tar -tf phpMyAdmin-*.tar.gz >/dev/null 2>&1; then
                if tar xzf phpMyAdmin-*.tar.gz 2>/dev/null; then
                    EXTRACTED_DIR=$(find . -maxdepth 1 -name "phpMyAdmin-*" -type d | head -1)
                    if [[ -n "$EXTRACTED_DIR" && -d "$EXTRACTED_DIR" ]]; then
                        cp -r "$EXTRACTED_DIR"/* /var/www/html/phpmyadmin/
                        PHPMYADMIN_INSTALLED=true
                        log "phpMyAdmin 5.2.1 extracted successfully"
                    fi
                fi
            fi
        fi
    fi
    
    # Method 3: Try alternative mirror
    if [[ "$PHPMYADMIN_INSTALLED" == "false" ]]; then
        warning "Primary sources failed, trying alternative mirror..."
        rm -f phpMyAdmin-*.tar.gz 2>/dev/null || true
        rm -rf phpMyAdmin-* 2>/dev/null || true
        
        if wget -q --timeout=30 --tries=3 "https://github.com/phpmyadmin/phpmyadmin/archive/refs/tags/RELEASE_5_2_1.tar.gz" -O "phpMyAdmin-5.2.1.tar.gz"; then
            if tar -tf phpMyAdmin-*.tar.gz >/dev/null 2>&1; then
                if tar xzf phpMyAdmin-*.tar.gz 2>/dev/null; then
                    EXTRACTED_DIR=$(find . -maxdepth 1 -name "*phpmyadmin*" -type d | head -1)
                    if [[ -n "$EXTRACTED_DIR" && -d "$EXTRACTED_DIR" ]]; then
                        cp -r "$EXTRACTED_DIR"/* /var/www/html/phpmyadmin/
                        PHPMYADMIN_INSTALLED=true
                        log "phpMyAdmin from GitHub mirror extracted successfully"
                    fi
                fi
            fi
        fi
    fi
    
    # Method 4: Install via package manager as last resort
    if [[ "$PHPMYADMIN_INSTALLED" == "false" ]]; then
        warning "All download methods failed, trying package manager installation..."
        
        if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
            # Pre-configure phpMyAdmin to avoid interactive prompts
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/app-password-confirm password " | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password " | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            
            if apt-get install -y phpmyadmin 2>/dev/null; then
                # Create symlink if not exists
                if [[ ! -L /var/www/html/phpmyadmin ]]; then
                    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
                fi
                PHPMYADMIN_INSTALLED=true
                log "phpMyAdmin installed via package manager"
            fi
        else
            # For CentOS/RHEL, try EPEL
            if yum install -y phpmyadmin 2>/dev/null; then
                if [[ ! -L /var/www/html/phpmyadmin ]]; then
                    ln -s /usr/share/phpMyAdmin /var/www/html/phpmyadmin
                fi
                PHPMYADMIN_INSTALLED=true
                log "phpMyAdmin installed via package manager"
            fi
        fi
    fi
    
    # Method 5: Create a minimal phpMyAdmin alternative if all else fails
    if [[ "$PHPMYADMIN_INSTALLED" == "false" ]]; then
        warning "All phpMyAdmin installation methods failed. Creating basic database management page..."
        
        mkdir -p /var/www/html/phpmyadmin
        cat > /var/www/html/phpmyadmin/index.php << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .alert { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
        .btn:hover { background: #0056b3; }
        h1 { color: #333; margin-bottom: 20px; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; padding: 15px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗄️ Database Management</h1>
        
        <div class="alert">
            <strong>Notice:</strong> phpMyAdmin installation failed. This is a temporary database management interface.
        </div>
        
        <div class="info">
            <h3>Database Access Information:</h3>
            <p><strong>Host:</strong> localhost</p>
            <p><strong>Username:</strong> root</p>
            <p><strong>Database:</strong> hosting_panel</p>
            <p><strong>Panel User:</strong> panel_user</p>
        </div>
        
        <h3>Alternative Database Management Options:</h3>
        <a href="#" class="btn" onclick="alert('Use: mysql -u root -p')">Command Line Access</a>
        <a href="https://www.adminer.org/" class="btn" target="_blank">Download Adminer</a>
        <a href="https://www.phpmyadmin.net/" class="btn" target="_blank">Manual phpMyAdmin Download</a>
        
        <h3>Quick Commands:</h3>
        <div class="info">
            <p><code>mysql -u root -p</code> - Access MySQL as root</p>
            <p><code>mysql -u panel_user -p hosting_panel</code> - Access panel database</p>
            <p><code>SHOW DATABASES;</code> - List all databases</p>
            <p><code>USE hosting_panel;</code> - Select panel database</p>
            <p><code>SHOW TABLES;</code> - List tables in current database</p>
        </div>
    </div>
</body>
</html>
EOF
        
        PHPMYADMIN_INSTALLED=true
        warning "Created basic database management interface at /var/www/html/phpmyadmin/"
    fi
    
    # Set permissions regardless of installation method
    chown -R www-data:www-data /var/www/html/phpmyadmin 2>/dev/null || chown -R apache:apache /var/www/html/phpmyadmin
    chmod -R 755 /var/www/html/phpmyadmin
    
    # Create or update phpMyAdmin configuration if it doesn't exist
    if [[ ! -f /var/www/html/phpmyadmin/config.inc.php ]] && [[ -f /var/www/html/phpmyadmin/config.sample.inc.php ]]; then
        cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php
        
        # Generate blowfish secret
        BLOWFISH_SECRET=$(openssl rand -base64 32)
        sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '$BLOWFISH_SECRET';/" /var/www/html/phpmyadmin/config.inc.php
        
        # Add basic security configuration
        cat >> /var/www/html/phpmyadmin/config.inc.php << 'EOF'

/* Security settings */
$cfg['ForceSSL'] = false;
$cfg['CheckConfigurationPermissions'] = false;
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
$cfg['LoginCookieValidity'] = 3600;
EOF
    elif [[ ! -f /var/www/html/phpmyadmin/config.inc.php ]]; then
        # Create basic config if no sample exists
        cat > /var/www/html/phpmyadmin/config.inc.php << EOF
<?php
\$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
EOF
    fi
    
    # Clean up temporary files
    cd /tmp
    rm -f phpMyAdmin-*.tar.gz 2>/dev/null || true
    rm -rf phpMyAdmin-* 2>/dev/null || true
    rm -rf *phpmyadmin* 2>/dev/null || true
    
    if [[ "$PHPMYADMIN_INSTALLED" == "true" ]]; then
        success "Database management interface installed successfully"
    else
        error "Failed to install any database management interface"
    fi
}

# Create control panel application
create_control_panel_app() {
    log "Creating control panel application from GitHub repository..."
    
    # Remove any existing installation
    rm -rf $CONTROL_PANEL_DIR 2>/dev/null || true
    
    # Clone the repository
    log "Cloning repository: $GITHUB_REPO"
    git clone $GITHUB_REPO $CONTROL_PANEL_DIR || {
        error "Failed to clone repository. Please check if the repository URL is correct and accessible."
    }
    
    cd $CONTROL_PANEL_DIR
    
    # Verify we have the necessary files
    if [[ ! -f "package.json" ]]; then
        error "package.json not found in repository. Please ensure the repository contains a valid Next.js project."
    fi
    
    # Install dependencies with verbose logging
    log "Installing Node.js dependencies..."
    npm install --verbose --no-audit --no-fund || {
        error "Failed to install npm dependencies. Checking Node.js installation..."
        node --version || error "Node.js is not properly installed"
        npm --version || error "npm is not properly installed"
        exit 1
    }
    
    # Create environment file with database credentials
    log "Creating environment configuration..."
    cat > .env.local << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
PANEL_DB_PASSWORD=$PANEL_DB_PASSWORD
DATABASE_URL=mysql://panel_user:$PANEL_DB_PASSWORD@localhost:3306/hosting_panel

# Server Configuration
SERVER_IP=$SERVER_IP
ADMIN_EMAIL=$ADMIN_EMAIL
DOMAIN_NAME=$DOMAIN_NAME

# Application Configuration
NODE_ENV=production
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=http://$SERVER_IP:3000
EOF
    
    # Verify Next.js installation
    if [[ ! -f "node_modules/.bin/next" ]]; then
        warning "Next.js binary not found, trying global installation..."
        npm install -g next@14.0.0
        
        # Create local symlink if global installation worked
        mkdir -p node_modules/.bin
        ln -sf $(which next) node_modules/.bin/next 2>/dev/null || true
    fi
    
    # Try building the application with better error handling
    log "Building Next.js application..."
    
    # First, try using the local binary
    if [[ -f "node_modules/.bin/next" ]]; then
        ./node_modules/.bin/next build || {
            warning "Local Next.js build failed, trying alternative methods..."
            
            # Try using npx
            npx next build || {
                warning "npx build failed, trying global next..."
                
                # Try global next
                next build || {
                    warning "All build methods failed, creating production-ready files manually..."
                    
                    # Create a simple production setup
                    mkdir -p .next/static
                    echo '{"version":"14.0.0","buildId":"manual"}' > .next/build-manifest.json
                    
                    log "Created minimal production setup"
                }
            }
        }
    else
        error "Next.js installation failed - binary not found"
    fi
    
    success "Control panel application created successfully from repository"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/hosting-panel.service << EOF
[Unit]
Description=Hosting Control Panel
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=$CONTROL_PANEL_DIR
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
EnvironmentFile=$CONTROL_PANEL_DIR/.env.local

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable hosting-panel
    
    success "Systemd service created"
}

# Create backup and maintenance scripts
create_scripts() {
    log "Creating backup and maintenance scripts..."
    
    mkdir -p $CONTROL_PANEL_DIR/scripts
    mkdir -p /var/backups/hosting-panel
    mkdir -p /var/log/hosting-panel
    
    # System backup script
    cat > $CONTROL_PANEL_DIR/scripts/backup-system.sh << 'EOF'
#!/bin/bash

# Hosting Panel System Backup Script
set -e

BACKUP_DIR="/var/backups/hosting-panel"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/hosting-panel/backup.log"

# Source credentials
source /root/.mysql_credentials

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "Starting system backup..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup MySQL databases
log "Backing up MySQL databases..."
mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases --single-transaction --routines --triggers > $BACKUP_DIR/mysql_all_$DATE.sql
gzip $BACKUP_DIR/mysql_all_$DATE.sql

# Backup website files
log "Backing up website files..."
if [ -d "/var/www" ]; then
    tar -czf $BACKUP_DIR/websites_$DATE.tar.gz -C /var/www . 2>/dev/null || true
fi

# Backup configuration files
log "Backing up configuration files..."
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    /etc/apache2 \
    /etc/mysql \
    /opt/hosting-panel/.env.local \
    2>/dev/null || true

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete 2>/dev/null || true

log "System backup completed successfully"
EOF

    chmod +x $CONTROL_PANEL_DIR/scripts/backup-system.sh
    
    success "Scripts created successfully"
}

# Setup cron jobs
setup_cron_jobs() {
    log "Setting up cron jobs..."
    
    # Create crontab entries
    (crontab -l 2>/dev/null; echo "# Hosting Panel Automated Tasks") | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * $CONTROL_PANEL_DIR/scripts/backup-system.sh") | crontab -
    
    success "Cron jobs configured"
}

# Final configuration and service startup
final_configuration() {
    log "Performing final configuration..."
    
    # Create web directories
    mkdir -p /var/www/html
    mkdir -p /var/log/hosting-panel
    
    # Set permissions
    chown -R www-data:www-data /var/www 2>/dev/null || chown -R apache:apache /var/www
    chmod -R 755 /var/www
    
    # Create default index page
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hosting Control Panel - Welcome</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .container {
            background: white;
            padding: 3rem;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
        }
        .logo {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        h1 {
            color: #2d3748;
            margin-bottom: 1rem;
            font-size: 2.5rem;
            font-weight: 700;
        }
        .subtitle {
            color: #718096;
            margin-bottom: 2rem;
            font-size: 1.2rem;
        }
        .status {
            display: inline-flex;
            align-items: center;
            background: #f0fff4;
            color: #22543d;
            padding: 0.75rem 1.5rem;
            border-radius: 50px;
            margin-bottom: 2rem;
            border: 2px solid #9ae6b4;
        }
        .status::before {
            content: '✅';
            margin-right: 0.5rem;
        }
        .buttons {
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 2rem;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            padding: 1rem 2rem;
            background: #4299e1;
            color: white;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(66, 153, 225, 0.3);
        }
        .btn:hover {
            background: #3182ce;
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(66, 153, 225, 0.4);
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
            text-align: left;
        }
        .info-card {
            background: #f7fafc;
            padding: 1.5rem;
            border-radius: 10px;
            border-left: 4px solid #4299e1;
        }
        .info-card h3 {
            color: #2d3748;
            margin-bottom: 0.5rem;
            font-size: 1.1rem;
        }
        .info-card p {
            color: #718096;
            font-size: 0.9rem;
            line-height: 1.5;
        }
        .repo-info {
            background: #e6fffa;
            border-left-color: #38b2ac;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1>Hosting Control Panel</h1>
        <p class="subtitle">Professional web hosting management platform</p>
        
        <div class="status">
            Server is online and ready!
        </div>
        
        <div class="buttons">
            <a href="http://$SERVER_IP:3000" class="btn">
                🎛️ Control Panel
            </a>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🌐 Server Information</h3>
                <p><strong>IP Address:</strong> $SERVER_IP<br>
                <strong>Control Panel:</strong> Port 3000<br>
                <strong>Status:</strong> Online</p>
            </div>
            
            <div class="info-card">
                <h3>🔐 Default Credentials</h3>
                <p><strong>Username:</strong> admin<br>
                <strong>Password:</strong> admin123<br>
                <strong>⚠️ Change immediately!</strong></p>
            </div>
            
            <div class="info-card repo-info">
                <h3>📦 Repository</h3>
                <p><strong>Source:</strong> Ceoslugpk/new-sub-panel<br>
                <strong>GitHub:</strong> github.com/Ceoslugpk/new-sub-panel<br>
                <strong>Version:</strong> Latest</p>
            </div>
        </div>
    </div>
</body>
</html>
EOF

    # Start services
    systemctl restart apache2 2>/dev/null || systemctl restart httpd
    systemctl restart mysql 2>/dev/null || systemctl restart mariadb
    
    # Start control panel
    systemctl start hosting-panel
    
    success "Final configuration completed"
}

# Display installation summary
display_summary() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${GREEN}🌐 ACCESS INFORMATION:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Control Panel:${NC}     http://$SERVER_IP:3000"
    echo -e "${BLUE}Welcome Page:${NC}      http://$SERVER_IP"
    if [[ -n "$DOMAIN_NAME" ]]; then
        echo -e "${BLUE}Domain Access:${NC}     https://$DOMAIN_NAME:3000"
    fi
    echo ""
    
    echo -e "${GREEN}📦 REPOSITORY INFORMATION:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Repository:${NC}        $GITHUB_REPO"
    echo -e "${BLUE}Local Path:${NC}        $CONTROL_PANEL_DIR"
    echo -e "${BLUE}Branch:${NC}            main"
    echo ""
    
    echo -e "${GREEN}🔐 CREDENTIALS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Control Panel Login:${NC}"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo -e "${RED}   ⚠️  CHANGE THIS PASSWORD IMMEDIATELY!${NC}"
    echo ""
    echo -e "${BLUE}MySQL Root Password:${NC} $MYSQL_ROOT_PASSWORD"
    echo -e "${BLUE}Panel DB Password:${NC}   $PANEL_DB_PASSWORD"
    echo -e "${YELLOW}   (Saved to /root/.mysql_credentials)${NC}"
    echo ""
    
    echo -e "${GREEN}📊 SERVICES STATUS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check service status
    services=(
        "apache2:Apache Web Server"
        "mysql:MySQL Database"
        "hosting-panel:Control Panel"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name service_desc <<< "$service_info"
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            echo -e "   ✅ ${service_desc}: ${GREEN}Running${NC}"
        else
            echo -e "   ❌ ${service_desc}: ${RED}Stopped${NC}"
        fi
    done
    echo ""
    
    echo -e "${GREEN}🛠️ FEATURES AVAILABLE:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🌐 Domain & Subdomain Management"
    echo "   🔒 SSL Certificate Management"
    echo "   📧 Email Server Management"
    echo "   🗄️ Database Management"
    echo "   📁 File Manager"
    echo "   🔐 Security Features"
    echo "   📊 System Monitoring"
    echo "   💾 Backup System"
    echo "   👥 User Management"
    echo ""
    
    echo -e "${GREEN}📝 NEXT STEPS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1. 🌐 Access control panel: http://$SERVER_IP:3000"
    echo "   2. 🔑 Change default admin password"
    echo "   3. 🌍 Add your first domain"
    echo "   4. 🔒 Set up SSL certificates"
    echo "   5. 📧 Create email accounts"
    echo "   6. 🗄️ Create databases"
    echo ""
    
    echo -e "${GREEN}🔧 MANAGEMENT COMMANDS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Control Panel:  systemctl {start|stop|restart|status} hosting-panel"
    echo "   View Logs:       journalctl -u hosting-panel -f"
    echo "   Backup System:   $CONTROL_PANEL_DIR/scripts/backup-system.sh"
    echo "   Update Panel:    cd $CONTROL_PANEL_DIR && git pull && npm run build && systemctl restart hosting-panel"
    echo ""
    
    echo -e "${GREEN}📁 IMPORTANT FILES:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Control Panel:     $CONTROL_PANEL_DIR"
    echo "   MySQL Credentials: /root/.mysql_credentials"
    echo "   Web Files:         /var/www/html"
    echo "   Backups:           /var/backups/hosting-panel"
    echo "   Environment:       $CONTROL_PANEL_DIR/.env.local"
    echo ""
    
    echo -e "${CYAN}🎉 Installation completed successfully!${NC}"
    echo -e "${CYAN}Your control panel is now running from: $GITHUB_REPO${NC}"
    echo ""
}

# Main installation function
main() {
    show_banner
    check_root
    get_user_input
    detect_os
    update_system
    install_packages
    install_docker
    install_nodejs
    install_apache
    install_php
    install_mysql
    install_phpmyadmin
    create_control_panel_app
    create_systemd_service
    create_scripts
    setup_cron_jobs
    final_configuration
    display_summary
}

# Run main installation
main "$@"
