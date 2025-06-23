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

# Install and configure Nginx (as reverse proxy)
install_nginx() {
    log "Installing Nginx as reverse proxy..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y nginx
    else
        yum install -y nginx
    fi
    
    systemctl enable nginx
    systemctl start nginx
    
    success "Nginx installed successfully"
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
            php8.1-json \
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
            php-json \
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

    # Execute secure installation
    if [[ -n "$TEMP_PASSWORD" ]]; then
        mysql --connect-expired-password -u root -p"$TEMP_PASSWORD" < /tmp/mysql_secure_installation.sql
    else
        mysql -u root < /tmp/mysql_secure_installation.sql
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
    
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
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

-- Domains table
CREATE TABLE IF NOT EXISTS domains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    domain_name VARCHAR(255) UNIQUE NOT NULL,
    document_root VARCHAR(500) NOT NULL,
    status ENUM('active', 'suspended', 'pending') DEFAULT 'active',
    ssl_enabled BOOLEAN DEFAULT FALSE,
    ssl_cert_path VARCHAR(500),
    ssl_key_path VARCHAR(500),
    ssl_ca_path VARCHAR(500),
    ssl_auto_renew BOOLEAN DEFAULT TRUE,
    php_version VARCHAR(10) DEFAULT '8.1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_domain_name (domain_name),
    INDEX idx_status (status)
);

-- Subdomains table
CREATE TABLE IF NOT EXISTS subdomains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    subdomain_name VARCHAR(100) NOT NULL,
    document_root VARCHAR(500) NOT NULL,
    status ENUM('active', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    UNIQUE KEY unique_subdomain (domain_id, subdomain_name),
    INDEX idx_domain_id (domain_id)
);

-- DNS zones table
CREATE TABLE IF NOT EXISTS dns_zones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    record_type ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'PTR', 'SRV') NOT NULL,
    name VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    ttl INT DEFAULT 3600,
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    INDEX idx_domain_id (domain_id),
    INDEX idx_record_type (record_type)
);

-- Email accounts table
CREATE TABLE IF NOT EXISTS email_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    email_address VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    quota_mb INT DEFAULT 1000,
    used_mb INT DEFAULT 0,
    status ENUM('active', 'suspended') DEFAULT 'active',
    forward_to VARCHAR(255),
    auto_responder BOOLEAN DEFAULT FALSE,
    auto_responder_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    INDEX idx_domain_id (domain_id),
    INDEX idx_email_address (email_address)
);

-- Email forwarders table
CREATE TABLE IF NOT EXISTS email_forwarders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    source_email VARCHAR(255) NOT NULL,
    destination_email VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    INDEX idx_domain_id (domain_id)
);

-- Databases table
CREATE TABLE IF NOT EXISTS databases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    database_name VARCHAR(64) NOT NULL,
    database_user VARCHAR(32) NOT NULL,
    database_type ENUM('mysql', 'postgresql') DEFAULT 'mysql',
    size_mb DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_database_name (database_name)
);

-- FTP accounts table
CREATE TABLE IF NOT EXISTS ftp_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    home_directory VARCHAR(500) NOT NULL,
    quota_mb INT DEFAULT 1000,
    status ENUM('active', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_username (username)
);

-- SSL certificates table
CREATE TABLE IF NOT EXISTS ssl_certificates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    certificate_type ENUM('letsencrypt', 'custom', 'self-signed') DEFAULT 'letsencrypt',
    certificate_data TEXT,
    private_key_data TEXT,
    ca_bundle_data TEXT,
    expires_at TIMESTAMP,
    auto_renew BOOLEAN DEFAULT TRUE,
    status ENUM('active', 'expired', 'pending') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    INDEX idx_domain_id (domain_id),
    INDEX idx_expires_at (expires_at)
);

-- Backups table
CREATE TABLE IF NOT EXISTS backups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    backup_type ENUM('full', 'database', 'files', 'email') NOT NULL,
    backup_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT DEFAULT 0,
    compression_type ENUM('gzip', 'zip', 'tar') DEFAULT 'gzip',
    status ENUM('completed', 'failed', 'in_progress') DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_backup_type (backup_type),
    INDEX idx_created_at (created_at)
);

-- System logs table
CREATE TABLE IF NOT EXISTS system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    log_level ENUM('info', 'warning', 'error', 'critical') NOT NULL,
    component VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_log_level (log_level),
    INDEX idx_component (component),
    INDEX idx_created_at (created_at)
);

-- Cron jobs table
CREATE TABLE IF NOT EXISTS cron_jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    command TEXT NOT NULL,
    schedule VARCHAR(100) NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    last_run TIMESTAMP NULL,
    next_run TIMESTAMP NULL,
    output TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- File manager sessions table
CREATE TABLE IF NOT EXISTS file_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(64) UNIQUE NOT NULL,
    current_path VARCHAR(500) DEFAULT '/',
    permissions JSON,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token)
);

-- Application installations table
CREATE TABLE IF NOT EXISTS app_installations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    domain_id INT NOT NULL,
    app_name VARCHAR(50) NOT NULL,
    app_version VARCHAR(20),
    install_path VARCHAR(500) NOT NULL,
    database_name VARCHAR(64),
    admin_username VARCHAR(50),
    admin_email VARCHAR(100),
    status ENUM('installed', 'failed', 'updating') DEFAULT 'installed',
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_domain_id (domain_id),
    INDEX idx_app_name (app_name)
);

-- Security settings table
CREATE TABLE IF NOT EXISTS security_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    setting_name VARCHAR(50) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_setting (user_id, setting_name),
    INDEX idx_user_id (user_id)
);

-- Create default admin user (password: admin123 - change immediately!)
INSERT INTO users (username, email, password_hash, role) 
VALUES ('admin', '$ADMIN_EMAIL', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE email='$ADMIN_EMAIL';
EOF

    success "Control panel database created successfully"
}

# Install PostgreSQL
install_postgresql() {
    log "Installing PostgreSQL..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y postgresql postgresql-contrib
    else
        yum install -y postgresql-server postgresql-contrib
        postgresql-setup initdb
    fi
    
    systemctl enable postgresql
    systemctl start postgresql
    
    # Create panel user for PostgreSQL
    sudo -u postgres createuser --createdb --createrole --login panel_pg_user
    sudo -u postgres psql -c "ALTER USER panel_pg_user PASSWORD '$PANEL_DB_PASSWORD';"
    
    success "PostgreSQL installed successfully"
}

# Install phpMyAdmin
install_phpmyadmin() {
    log "Installing phpMyAdmin..."
    
    # Download latest phpMyAdmin
    cd /tmp
    PHPMYADMIN_VERSION=$(curl -s https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | jq -r .tag_name)
    wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"
    
    # Extract and install
    tar xzf phpMyAdmin-*.tar.gz
    rm -rf /var/www/html/phpmyadmin 2>/dev/null || true
    mv phpMyAdmin-*-all-languages /var/www/html/phpmyadmin
    
    # Set permissions
    chown -R www-data:www-data /var/www/html/phpmyadmin 2>/dev/null || chown -R apache:apache /var/www/html/phpmyadmin
    chmod -R 755 /var/www/html/phpmyadmin
    
    # Create phpMyAdmin configuration
    cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php
    
    # Generate blowfish secret
    BLOWFISH_SECRET=$(openssl rand -base64 32)
    sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '$BLOWFISH_SECRET';/" /var/www/html/phpmyadmin/config.inc.php
    
    # Configure phpMyAdmin
    cat >> /var/www/html/phpmyadmin/config.inc.php << 'EOF'

/* Advanced phpMyAdmin features */
$cfg['Servers'][$i]['controluser'] = 'pma';
$cfg['Servers'][$i]['controlpass'] = 'pmapass';
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';
$cfg['Servers'][$i]['relation'] = 'pma__relation';
$cfg['Servers'][$i]['table_info'] = 'pma__table_info';
$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';
$cfg['Servers'][$i]['column_info'] = 'pma__column_info';
$cfg['Servers'][$i]['history'] = 'pma__history';
$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';
$cfg['Servers'][$i]['tracking'] = 'pma__tracking';
$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';
$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';
$cfg['Servers'][$i]['users'] = 'pma__users';
$cfg['Servers'][$i]['usergroups'] = 'pma__usergroups';
$cfg['Servers'][$i]['navigationhiding'] = 'pma__navigationhiding';
$cfg['Servers'][$i]['savedsearches'] = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns'] = 'pma__central_columns';
$cfg['Servers'][$i]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][$i]['export_templates'] = 'pma__export_templates';

/* Security settings */
$cfg['ForceSSL'] = false;
$cfg['CheckConfigurationPermissions'] = false;
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
EOF

    # Create phpMyAdmin database and user
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" << 'EOF'
CREATE DATABASE IF NOT EXISTS phpmyadmin;
CREATE USER IF NOT EXISTS 'pma'@'localhost' IDENTIFIED BY 'pmapass';
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Import phpMyAdmin tables
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" phpmyadmin < /var/www/html/phpmyadmin/sql/create_tables.sql 2>/dev/null || true
    
    # Clean up
    rm -f /tmp/phpMyAdmin-*.tar.gz
    
    success "phpMyAdmin installed successfully"
}

# Install mail server (Postfix + Dovecot)
install_mail_server() {
    log "Installing mail server (Postfix + Dovecot)..."
    
    # Preconfigure Postfix
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
        echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
        
        apt-get install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql
        apt-get install -y mailutils opendkim opendkim-tools spamassassin sieve-connect
    else
        yum install -y postfix dovecot dovecot-mysql dovecot-pigeonhole
        yum install -y mailx opendkim spamassassin
    fi
    
    # Configure Postfix
    configure_postfix
    
    # Configure Dovecot
    configure_dovecot
    
    # Configure OpenDKIM
    configure_opendkim
    
    # Configure SpamAssassin
    configure_spamassassin
    
    systemctl enable postfix dovecot opendkim spamassassin
    systemctl start postfix dovecot opendkim spamassassin
    
    success "Mail server installed and configured"
}

# Configure Postfix
configure_postfix() {
    log "Configuring Postfix..."
    
    # Backup original configuration
    cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
    
    # Create main Postfix configuration
    cat > /etc/postfix/main.cf << EOF
# Basic settings
myhostname = $(hostname -f)
mydomain = $(hostname -d)
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = all
mydestination = localhost

# Network settings
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

# Virtual domains and users
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp

# TLS settings
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls = yes
smtpd_tls_auth_only = yes
smtp_tls_security_level = may
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3

# SASL authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

# Security settings
smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname
smtpd_sender_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_sender, reject_unknown_sender_domain
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unauth_destination

# Message size limits
message_size_limit = 52428800
mailbox_size_limit = 1073741824

# OpenDKIM
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOF

    # Create MySQL configuration files for Postfix
    cat > /etc/postfix/mysql-virtual-mailbox-domains.cf << EOF
user = panel_user
password = $PANEL_DB_PASSWORD
hosts = 127.0.0.1
dbname = hosting_panel
query = SELECT 1 FROM domains WHERE domain_name='%s' AND status='active'
EOF

    cat > /etc/postfix/mysql-virtual-mailbox-maps.cf << EOF
user = panel_user
password = $PANEL_DB_PASSWORD
hosts = 127.0.0.1
dbname = hosting_panel
query = SELECT 1 FROM email_accounts WHERE email_address='%s' AND status='active'
EOF

    cat > /etc/postfix/mysql-virtual-alias-maps.cf << EOF
user = panel_user
password = $PANEL_DB_PASSWORD
hosts = 127.0.0.1
dbname = hosting_panel
query = SELECT destination_email FROM email_forwarders WHERE source_email='%s' AND status='active'
EOF

    # Set permissions
    chmod 640 /etc/postfix/mysql-*.cf
    chown root:postfix /etc/postfix/mysql-*.cf
}

# Configure Dovecot
configure_dovecot() {
    log "Configuring Dovecot..."
    
    # Main Dovecot configuration
    cat > /etc/dovecot/dovecot.conf << 'EOF'
protocols = imap pop3 lmtp
listen = *, ::
base_dir = /var/run/dovecot/
instance_name = dovecot

# Logging
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log
debug_log_path = /var/log/dovecot-debug.log

# SSL settings
ssl = required
ssl_cert = </etc/ssl/certs/ssl-cert-snakeoil.pem
ssl_key = </etc/ssl/private/ssl-cert-snakeoil.key
ssl_protocols = !SSLv2 !SSLv3

# Authentication
disable_plaintext_auth = yes
auth_mechanisms = plain login

# Mail location
mail_location = maildir:/var/mail/vhosts/%d/%n
mail_privileged_group = mail

# User database
userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

# Password database
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

# LMTP service
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    group = postfix
    mode = 0600
    user = postfix
  }
}

# Auth service
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
  unix_listener auth-userdb {
    group = mail
    mode = 0600
    user = vmail
  }
  user = dovecot
}

# IMAP service
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

# POP3 service
service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}
EOF

    # Dovecot SQL configuration
    cat > /etc/dovecot/dovecot-sql.conf.ext << EOF
driver = mysql
connect = host=localhost dbname=hosting_panel user=panel_user password=$PANEL_DB_PASSWORD
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email_address as user, password_hash as password FROM email_accounts WHERE email_address='%u' AND status='active'
user_query = SELECT '/var/mail/vhosts/%d/%n' as home, 'maildir:/var/mail/vhosts/%d/%n' as mail, 5000 AS uid, 5000 AS gid FROM email_accounts WHERE email_address='%u' AND status='active'
EOF

    # Create vmail user
    groupadd -g 5000 vmail 2>/dev/null || true
    useradd -g vmail -u 5000 vmail -d /var/mail 2>/dev/null || true
    
    # Create mail directories
    mkdir -p /var/mail/vhosts
    chown -R vmail:vmail /var/mail/vhosts
    chmod -R 770 /var/mail/vhosts
    
    # Set permissions
    chown -R vmail:dovecot /etc/dovecot
    chmod -R o-rwx /etc/dovecot
}

# Configure OpenDKIM
configure_opendkim() {
    log "Configuring OpenDKIM..."
    
    # Create OpenDKIM directories
    mkdir -p /etc/opendkim/keys
    
    # OpenDKIM configuration
    cat > /etc/opendkim.conf << 'EOF'
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:8891@localhost
EOF

    # Create trusted hosts
    cat > /etc/opendkim/TrustedHosts << 'EOF'
127.0.0.1
localhost
192.168.0.1/24
*.localhost
EOF

    # Create key and signing tables (will be populated by control panel)
    touch /etc/opendkim/KeyTable
    touch /etc/opendkim/SigningTable
    
    # Set permissions
    chown -R opendkim:opendkim /etc/opendkim
    chmod -R 700 /etc/opendkim/keys
}

# Configure SpamAssassin
configure_spamassassin() {
    log "Configuring SpamAssassin..."
    
    # Enable SpamAssassin
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin 2>/dev/null || true
    
    # Update SpamAssassin rules
    sa-update || true
}

# Install FTP server (ProFTPD)
install_ftp_server() {
    log "Installing FTP server (ProFTPD)..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y proftpd-basic proftpd-mod-mysql
    else
        yum install -y proftpd proftpd-mysql
    fi
    
    # Configure ProFTPD
    configure_proftpd
    
    systemctl enable proftpd
    systemctl start proftpd
    
    success "FTP server installed and configured"
}

# Configure ProFTPD
configure_proftpd() {
    log "Configuring ProFTPD..."
    
    # Backup original configuration
    cp /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf.backup
    
    # Create ProFTPD configuration
    cat > /etc/proftpd/proftpd.conf << EOF
Include /etc/proftpd/modules.conf
UseIPv6 on
IdentLookups off
ServerName "Hosting Panel FTP Server"
ServerType standalone
DeferWelcome off
MultilineRFC2228 on
DefaultServer on
ShowSymlinks on
TimeoutNoTransfer 600
TimeoutStalled 600
TimeoutIdle 1200
DisplayLogin welcome.msg
DisplayChdir .message true
ListOptions "-l"
DenyFilter \*.*/
DefaultRoot ~
Port 21
MaxInstances 30
User proftpd
Group nogroup
Umask 022 022
AllowOverwrite on
TransferLog /var/log/proftpd/xferlog
SystemLog /var/log/proftpd/proftpd.log

# MySQL authentication
AuthOrder mod_sql.c
SQLBackend mysql
SQLConnectInfo hosting_panel@localhost panel_user $PANEL_DB_PASSWORD
SQLUserInfo ftp_accounts username password_hash uid gid home_directory
SQLGroupInfo groups groupname gid members
SQLMinUserUID 500
SQLMinUserGID 100

# TLS configuration
<IfModule mod_tls.c>
TLSEngine on
TLSLog /var/log/proftpd/tls.log
TLSProtocol SSLv23
TLSCipherSuite HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3:!aNULL:!eNULL:!3DES:@STRENGTH
TLSOptions NoCertRequest EnableDiags NoSessionReuseRequired
TLSVerifyClient off
TLSRSACertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
TLSRSACertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</IfModule>

# Passive mode configuration
PassivePorts 49152 65534

<Directory />
  AllowOverwrite on
</Directory>
EOF

    # Create log directory
    mkdir -p /var/log/proftpd
    chown proftpd:adm /var/log/proftpd
}

# Install DNS server (BIND)
install_dns_server() {
    log "Installing DNS server (BIND)..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y bind9 bind9utils bind9-doc
    else
        yum install -y bind bind-utils
    fi
    
    # Configure BIND
    configure_bind
    
    systemctl enable bind9 2>/dev/null || systemctl enable named
    systemctl start bind9 2>/dev/null || systemctl start named
    
    success "DNS server installed and configured"
}

# Configure BIND
configure_bind() {
    log "Configuring BIND..."
    
    # Create BIND configuration directory
    mkdir -p /etc/bind/zones
    
    # Main BIND configuration
    cat > /etc/bind/named.conf << 'EOF'
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF

    # BIND options
    cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    recursion yes;
    allow-recursion { localhost; 127.0.0.1; $SERVER_IP; };
    
    listen-on port 53 { localhost; $SERVER_IP; };
    listen-on-v6 port 53 { ::1; };
    
    allow-transfer { none; };
    
    dnssec-validation auto;
    
    auth-nxdomain no;
    listen-on-v6 { any; };
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
        1.0.0.1;
    };
};
EOF

    # Local zones configuration (will be managed by control panel)
    cat > /etc/bind/named.conf.local << 'EOF'
// Local zones will be added here by the control panel
EOF

    # Default zones
    cat > /etc/bind/named.conf.default-zones << 'EOF'
zone "." {
    type hint;
    file "/etc/bind/db.root";
};

zone "localhost" {
    type master;
    file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
    type master;
    file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
    type master;
    file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
    type master;
    file "/etc/bind/db.255";
};
EOF

    # Set permissions
    chown -R bind:bind /etc/bind
    chmod -R 755 /etc/bind
}

# Install Let's Encrypt Certbot
install_certbot() {
    log "Installing Let's Encrypt Certbot..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        apt-get install -y certbot python3-certbot-apache python3-certbot-nginx
    else
        yum install -y certbot python3-certbot-apache python3-certbot-nginx
    fi
    
    # Create renewal hook script
    mkdir -p /etc/letsencrypt/renewal-hooks/deploy
    cat > /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh << 'EOF'
#!/bin/bash
systemctl reload apache2 2>/dev/null || systemctl reload httpd
systemctl reload nginx 2>/dev/null || true
systemctl reload postfix
systemctl reload dovecot
EOF
    chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-services.sh
    
    success "Certbot installed successfully"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # Configure UFW
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow essential services
        ufw allow ssh
        ufw allow 80/tcp    # HTTP
        ufw allow 443/tcp   # HTTPS
        ufw allow 21/tcp    # FTP
        ufw allow 22/tcp    # SSH
        ufw allow 25/tcp    # SMTP
        ufw allow 110/tcp   # POP3
        ufw allow 143/tcp   # IMAP
        ufw allow 993/tcp   # IMAPS
        ufw allow 995/tcp   # POP3S
        ufw allow 587/tcp   # SMTP Submission
        ufw allow 53        # DNS
        ufw allow 3000/tcp  # Control Panel
        ufw allow 49152:65534/tcp # FTP Passive
        
        ufw --force enable
        
    else
        # Configure firewalld
        systemctl enable firewalld
        systemctl start firewalld
        
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-service=ftp
        firewall-cmd --permanent --add-service=smtp
        firewall-cmd --permanent --add-service=pop3
        firewall-cmd --permanent --add-service=imap
        firewall-cmd --permanent --add-service=imaps
        firewall-cmd --permanent --add-service=pop3s
        firewall-cmd --permanent --add-service=dns
        firewall-cmd --permanent --add-port=587/tcp
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --permanent --add-port=49152-65534/tcp
        
        firewall-cmd --reload
    fi
    
    success "Firewall configured"
}

# Configure Fail2Ban
configure_fail2ban() {
    log "Configuring Fail2Ban..."
    
    # Create custom Fail2Ban configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
enabled = false
mode = normal
filter = %(__name__)s[mode=%(mode)s]

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[apache-auth]
enabled = true
port = http,https
logpath = %(apache_error_log)s

[apache-badbots]
enabled = true
port = http,https
logpath = %(apache_access_log)s
bantime = 86400
maxretry = 1

[apache-noscript]
enabled = true
port = http,https
logpath = %(apache_access_log)s
maxretry = 6

[apache-overflows]
enabled = true
port = http,https
logpath = %(apache_error_log)s
maxretry = 2

[postfix]
enabled = true
port = smtp,465,submission
logpath = %(postfix_log)s
backend = %(postfix_backend)s

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s

[proftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
logpath = %(proftpd_log)s
backend = %(proftpd_backend)s
EOF

    systemctl enable fail2ban
    systemctl start fail2ban
    
    success "Fail2Ban configured"
}

# Create control panel application
create_control_panel_app() {
    log "Creating control panel application..."
    
    # Create application directory
    mkdir -p $CONTROL_PANEL_DIR
    cd $CONTROL_PANEL_DIR
    
    # Initialize Node.js project
    npm init -y
    
    # Install dependencies
    npm install next@14.0.0 react@^18 react-dom@^18 typescript@^5 @types/node@^20 @types/react@^18 @types/react-dom@^18
    npm install mysql2@^3.6.0 bcryptjs@^2.4.3 jsonwebtoken@^9.0.0 speakeasy@^2.0.0 qrcode@^1.5.0
    npm install @radix-ui/react-accordion@^1.1.2 @radix-ui/react-alert-dialog@^1.0.5 @radix-ui/react-avatar@^1.0.4
    npm install @radix-ui/react-checkbox@^1.0.4 @radix-ui/react-dialog@^1.0.5 @radix-ui/react-dropdown-menu@^2.0.6
    npm install @radix-ui/react-label@^2.0.2 @radix-ui/react-progress@^1.0.3 @radix-ui/react-select@^2.0.0
    npm install @radix-ui/react-separator@^1.0.3 @radix-ui/react-slider@^1.1.2 @radix-ui/react-slot@^1.0.2
    npm install @radix-ui/react-switch@^1.0.3 @radix-ui/react-tabs@^1.0.4 @radix-ui/react-toast@^1.1.5
    npm install @radix-ui/react-tooltip@^1.0.7 class-variance-authority@^0.7.0 clsx@^2.0.0
    npm install lucide-react@^0.290.0 tailwind-merge@^2.0.0 tailwindcss-animate@^1.0.7
    npm install --save-dev autoprefixer@^10.0.1 postcss@^8 tailwindcss@^3.3.0 eslint@^8 eslint-config-next@14.0.0
    
    # Create package.json with proper scripts
    cat > package.json << 'EOF'
{
  "name": "hosting-control-panel",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18",
    "react-dom": "^18",
    "mysql2": "^3.6.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "speakeasy": "^2.0.0",
    "qrcode": "^1.5.0",
    "@radix-ui/react-accordion": "^1.1.2",
    "@radix-ui/react-alert-dialog": "^1.0.5",
    "@radix-ui/react-avatar": "^1.0.4",
    "@radix-ui/react-checkbox": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "@radix-ui/react-tooltip": "^1.0.7",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "lucide-react": "^0.290.0",
    "tailwind-merge": "^2.0.0",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "@types/bcryptjs": "^2.4.4",
    "@types/jsonwebtoken": "^9.0.0",
    "autoprefixer": "^10.0.1",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "eslint": "^8",
    "eslint-config-next": "14.0.0"
  }
}
EOF

    # Create environment file
    cat > .env.local << EOF
# Database Configuration
MYSQL_ROOT_USER=root
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
PANEL_DB_USER=panel_user
PANEL_DB_PASSWORD=$PANEL_DB_PASSWORD
DATABASE_URL=mysql://panel_user:$PANEL_DB_PASSWORD@localhost:3306/hosting_panel

# Application Configuration
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=http://$SERVER_IP:3000
JWT_SECRET=$(openssl rand -base64 32)

# Server Configuration
SERVER_IP=$SERVER_IP
ADMIN_EMAIL=$ADMIN_EMAIL
DOMAIN_NAME=$DOMAIN_NAME

# Service Configuration
APACHE_CONFIG_DIR=/etc/apache2
NGINX_CONFIG_DIR=/etc/nginx
BIND_CONFIG_DIR=/etc/bind
POSTFIX_CONFIG_DIR=/etc/postfix
DOVECOT_CONFIG_DIR=/etc/dovecot
PROFTPD_CONFIG_DIR=/etc/proftpd

# File Paths
WEB_ROOT=/var/www
BACKUP_DIR=/var/backups/hosting-panel
LOG_DIR=/var/log/hosting-panel
TEMP_DIR=/tmp/hosting-panel

# SSL Configuration
SSL_CERT_DIR=/etc/ssl/certs
SSL_KEY_DIR=/etc/ssl/private
LETSENCRYPT_DIR=/etc/letsencrypt

# Security
FAIL2BAN_CONFIG_DIR=/etc/fail2ban
FIREWALL_CONFIG_DIR=/etc/ufw

# WordPress
WORDPRESS_DOWNLOAD_URL=https://wordpress.org/latest.tar.gz
EOF

    # Create Next.js configuration
    cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  experimental: {
    serverActions: {
      allowedOrigins: ["localhost:3000", "*.localhost:3000"],
    },
  },
  async rewrites() {
    return [
      {
        source: "/phpmyadmin/:path*",
        destination: "http://localhost/phpmyadmin/:path*",
      },
    ]
  },
}

module.exports = nextConfig
EOF

    # Create Tailwind configuration
    cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss"

const config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
    "*.{js,ts,jsx,tsx,mdx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config

export default config
EOF

    # Create PostCSS configuration
    cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # Create TypeScript configuration
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

    success "Control panel application structure created"
}

# Create application files
create_app_files() {
    log "Creating application files..."
    
    cd $CONTROL_PANEL_DIR
    
    # Create directory structure
    mkdir -p app/{api,auth,dashboard,domains,email,databases,files,security,backups,settings,users}
    mkdir -p app/api/{auth,system,domains,email,databases,files,ssl,backups,users,security,dns,ftp,cron,apps}
    mkdir -p components/{ui,dashboard,forms,modals,charts}
    mkdir -p lib/{auth,database,utils,services}
    mkdir -p hooks
    mkdir -p types
    mkdir -p public/{images,icons}
    
    # Create lib/utils.ts
    cat > lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatBytes(bytes: number, decimals = 2) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i]
}

export function formatDate(date: Date | string) {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

export function generatePassword(length = 12) {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
  let password = ""
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length))
  }
  return password
}

export function validateEmail(email: string) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return re.test(email)
}

export function validateDomain(domain: string) {
  const re = /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/
  return re.test(domain)
}
EOF

    # Create database connection
    cat > lib/database.ts << 'EOF'
import mysql from 'mysql2/promise'

const pool = mysql.createPool({
  host: 'localhost',
  user: process.env.PANEL_DB_USER,
  password: process.env.PANEL_DB_PASSWORD,
  database: 'hosting_panel',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  acquireTimeout: 60000,
  timeout: 60000,
})

export async function query(sql: string, params?: any[]) {
  try {
    const [results] = await pool.execute(sql, params)
    return results
  } catch (error) {
    console.error('Database query error:', error)
    throw error
  }
}

export async function transaction(queries: Array<{ sql: string; params?: any[] }>) {
  const connection = await pool.getConnection()
  try {
    await connection.beginTransaction()
    
    const results = []
    for (const { sql, params } of queries) {
      const [result] = await connection.execute(sql, params)
      results.push(result)
    }
    
    await connection.commit()
    return results
  } catch (error) {
    await connection.rollback()
    throw error
  } finally {
    connection.release()
  }
}

export default pool
EOF

    # Create authentication utilities
    cat > lib/auth.ts << 'EOF'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import speakeasy from 'speakeasy'
import { query } from './database'

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12)
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

export function generateJWT(payload: any): string {
  return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: '24h' })
}

export function verifyJWT(token: string): any {
  return jwt.verify(token, process.env.JWT_SECRET!)
}

export function generate2FASecret(): { secret: string; qrCode: string } {
  const secret = speakeasy.generateSecret({
    name: 'Hosting Panel',
    length: 32
  })
  
  return {
    secret: secret.base32!,
    qrCode: secret.otpauth_url!
  }
}

export function verify2FA(token: string, secret: string): boolean {
  return speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 2
  })
}

export async function getUserByEmail(email: string) {
  const users = await query(
    'SELECT * FROM users WHERE email = ? AND status = "active"',
    [email]
  ) as any[]
  
  return users[0] || null
}

export async function getUserById(id: number) {
  const users = await query(
    'SELECT * FROM users WHERE id = ? AND status = "active"',
    [id]
  ) as any[]
  
  return users[0] || null
}

export async function createUser(userData: {
  username: string
  email: string
  password: string
  role?: string
}) {
  const hashedPassword = await hashPassword(userData.password)
  
  const result = await query(
    'INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
    [userData.username, userData.email, hashedPassword, userData.role || 'user']
  ) as any
  
  return result.insertId
}

export async function updateLastLogin(userId: number) {
  await query(
    'UPDATE users SET last_login = NOW() WHERE id = ?',
    [userId]
  )
}

export async function logActivity(userId: number | null, action: string, details: any, ip?: string) {
  await query(
    'INSERT INTO system_logs (user_id, log_level, component, action, message, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
    [userId, 'info', 'auth', action, JSON.stringify(details), ip]
  )
}
EOF

    # Create app/globals.css
    cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 94.1%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: hsl(var(--muted));
}

::-webkit-scrollbar-thumb {
  background: hsl(var(--border));
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: hsl(var(--muted-foreground));
}

/* Loading animation */
.loading-spinner {
  @apply animate-spin rounded-full border-2 border-gray-300 border-t-blue-600;
}

/* Code editor styles */
.code-editor {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.5;
}

/* File manager styles */
.file-icon {
  @apply w-4 h-4 mr-2 flex-shrink-0;
}

.file-row:hover {
  @apply bg-muted/50;
}

/* Terminal styles */
.terminal {
  background: #1a1a1a;
  color: #00ff00;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.4;
}

/* Chart styles */
.chart-container {
  @apply w-full h-64;
}

/* Modal animations */
.modal-overlay {
  @apply fixed inset-0 bg-black/50 z-50;
}

.modal-content {
  @apply fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 bg-background p-6 shadow-lg duration-200 rounded-lg border;
}

/* Toast notifications */
.toast {
  @apply fixed bottom-4 right-4 z-50 bg-background border rounded-lg shadow-lg p-4 max-w-sm;
}

.toast.success {
  @apply border-green-500 bg-green-50 text-green-800;
}

.toast.error {
  @apply border-red-500 bg-red-50 text-red-800;
}

.toast.warning {
  @apply border-yellow-500 bg-yellow-50 text-yellow-800;
}

/* Progress bars */
.progress-bar {
  @apply w-full bg-gray-200 rounded-full h-2;
}

.progress-fill {
  @apply h-2 rounded-full transition-all duration-300;
}

/* Status indicators */
.status-online {
  @apply text-green-600 bg-green-100 border-green-200;
}

.status-offline {
  @apply text-red-600 bg-red-100 border-red-200;
}

.status-warning {
  @apply text-yellow-600 bg-yellow-100 border-yellow-200;
}

/* Responsive utilities */
@media (max-width: 768px) {
  .mobile-hidden {
    @apply hidden;
  }
  
  .mobile-full {
    @apply w-full;
  }
}

/* Print styles */
@media print {
  .no-print {
    @apply hidden;
  }
}
EOF

    # Create app/layout.tsx
    cat > app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Hosting Control Panel',
  description: 'Professional web hosting control panel for VPS management',
  keywords: 'hosting, control panel, VPS, cPanel, Plesk, web hosting',
  authors: [{ name: 'Hosting Panel Team' }],
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="icon" href="/favicon.ico" />
        <meta name="theme-color" content="#3b82f6" />
      </head>
      <body className={inter.className} suppressHydrationWarning>
        <div id="root">{children}</div>
        <div id="modal-root"></div>
        <div id="toast-root"></div>
      </body>
    </html>
  )
}
EOF

    success "Application files created successfully"
}

# Install and build the application
install_and_build_app() {
    log "Installing and building the control panel application..."
    
    cd $CONTROL_PANEL_DIR
    
    # Install dependencies
    npm install
    
    # Build the application
    npm run build
    
    success "Control Panel application built successfully"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/hosting-panel.service << EOF
[Unit]
Description=Hosting Control Panel
After=network.target mysql.service mariadb.service apache2.service nginx.service

[Service]
Type=simple
User=root
WorkingDirectory=$CONTROL_PANEL_DIR
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
EnvironmentFile=$CONTROL_PANEL_DIR/.env.local
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hosting-panel

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

# Backup hosting panel database separately
mysqldump -u root -p$MYSQL_ROOT_PASSWORD hosting_panel --single-transaction > $BACKUP_DIR/hosting_panel_$DATE.sql
gzip $BACKUP_DIR/hosting_panel_$DATE.sql

# Backup website files
log "Backing up website files..."
if [ -d "/var/www" ]; then
    tar -czf $BACKUP_DIR/websites_$DATE.tar.gz -C /var/www . 2>/dev/null || true
fi

# Backup email data
log "Backing up email data..."
if [ -d "/var/mail/vhosts" ]; then
    tar -czf $BACKUP_DIR/email_$DATE.tar.gz -C /var/mail vhosts 2>/dev/null || true
fi

# Backup configuration files
log "Backing up configuration files..."
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    /etc/apache2 \
    /etc/nginx \
    /etc/postfix \
    /etc/dovecot \
    /etc/bind \
    /etc/proftpd \
    /etc/fail2ban \
    /etc/letsencrypt \
    /opt/hosting-panel/.env.local \
    2>/dev/null || true

# Backup control panel application
log "Backing up control panel..."
tar -czf $BACKUP_DIR/panel_app_$DATE.tar.gz -C /opt hosting-panel --exclude=node_modules --exclude=.next 2>/dev/null || true

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete 2>/dev/null || true
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete 2>/dev/null || true

# Calculate backup sizes
TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
log "Backup completed successfully. Total backup size: $TOTAL_SIZE"

# Send notification (if configured)
if [ -n "$BACKUP_EMAIL" ]; then
    echo "System backup completed successfully on $(hostname) at $(date)" | \
    mail -s "Backup Completed - $(hostname)" $BACKUP_EMAIL 2>/dev/null || true
fi
EOF

    # SSL renewal script
    cat > $CONTROL_PANEL_DIR/scripts/ssl-renew.sh << 'EOF'
#!/bin/bash

# SSL Certificate Renewal Script
set -e

LOG_FILE="/var/log/hosting-panel/ssl-renewal.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "Starting SSL certificate renewal..."

# Renew certificates
certbot renew --quiet --no-self-upgrade --deploy-hook "systemctl reload apache2 nginx postfix dovecot" 2>&1 | tee -a $LOG_FILE

# Update database with new expiration dates
mysql -u root -p$MYSQL_ROOT_PASSWORD hosting_panel << 'SQL'
UPDATE ssl_certificates 
SET expires_at = DATE_ADD(NOW(), INTERVAL 90 DAY),
    updated_at = NOW()
WHERE certificate_type = 'letsencrypt' 
AND status = 'active';
SQL

log "SSL certificate renewal completed"
EOF

    # System monitoring script
    cat > $CONTROL_PANEL_DIR/scripts/monitor-system.sh << 'EOF'
#!/bin/bash

# System Monitoring Script
LOG_FILE="/var/log/hosting-panel/monitor.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    log "WARNING: Disk usage is at ${DISK_USAGE}%"
    # Send alert if configured
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -gt 90 ]; then
    log "WARNING: Memory usage is at ${MEMORY_USAGE}%"
fi

# Check service status
SERVICES=("apache2" "mysql" "postfix" "dovecot" "proftpd" "bind9" "hosting-panel")
for service in "${SERVICES[@]}"; do
    if ! systemctl is-active --quiet $service 2>/dev/null; then
        log "ERROR: Service $service is not running"
        # Attempt to restart
        systemctl restart $service 2>/dev/null || true
    fi
done

# Check SSL certificate expiration
mysql -u root -p$MYSQL_ROOT_PASSWORD hosting_panel -e "
SELECT domain_name, expires_at 
FROM ssl_certificates sc
JOIN domains d ON sc.domain_id = d.id
WHERE expires_at < DATE_ADD(NOW(), INTERVAL 30 DAY)
AND status = 'active'
" 2>/dev/null | while read domain expires; do
    if [ "$domain" != "domain_name" ]; then
        log "WARNING: SSL certificate for $domain expires on $expires"
    fi
done
EOF

    # WordPress installer script
    cat > $CONTROL_PANEL_DIR/scripts/install-wordpress.sh << 'EOF'
#!/bin/bash

# WordPress Installation Script
set -e

DOMAIN=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4
ADMIN_USER=$5
ADMIN_PASS=$6
ADMIN_EMAIL=$7

if [ $# -ne 7 ]; then
    echo "Usage: $0 <domain> <db_name> <db_user> <db_pass> <admin_user> <admin_pass> <admin_email>"
    exit 1
fi

DOCUMENT_ROOT="/var/www/$DOMAIN"
WP_CLI="/usr/local/bin/wp"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Installing WordPress for $DOMAIN..."

# Download WordPress
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Move WordPress files
mkdir -p $DOCUMENT_ROOT
cp -r wordpress/* $DOCUMENT_ROOT/
rm -rf wordpress latest.tar.gz

# Set permissions
chown -R www-data:www-data $DOCUMENT_ROOT
find $DOCUMENT_ROOT -type d -exec chmod 755 {} \;
find $DOCUMENT_ROOT -type f -exec chmod 644 {} \;

# Install WP-CLI if not exists
if [ ! -f "$WP_CLI" ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar $WP_CLI
fi

# Configure WordPress
cd $DOCUMENT_ROOT
sudo -u www-data $WP_CLI config create \
    --dbname=$DB_NAME \
    --dbuser=$DB_USER \
    --dbpass=$DB_PASS \
    --dbhost=localhost \
    --dbprefix=wp_

# Install WordPress
sudo -u www-data $WP_CLI core install \
    --url="https://$DOMAIN" \
    --title="$DOMAIN" \
    --admin_user=$ADMIN_USER \
    --admin_password=$ADMIN_PASS \
    --admin_email=$ADMIN_EMAIL

# Install essential plugins
sudo -u www-data $WP_CLI plugin install \
    wordfence \
    updraftplus \
    yoast-seo \
    --activate

# Set up basic security
sudo -u www-data $WP_CLI config set WP_DEBUG false
sudo -u www-data $WP_CLI config set DISALLOW_FILE_EDIT true

log "WordPress installation completed for $DOMAIN"
EOF

    # Make scripts executable
    chmod +x $CONTROL_PANEL_DIR/scripts/*.sh
    
    success "Scripts created successfully"
}

# Setup cron jobs
setup_cron_jobs() {
    log "Setting up cron jobs..."
    
    # Create crontab entries
    (crontab -l 2>/dev/null; echo "# Hosting Panel Automated Tasks") | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * $CONTROL_PANEL_DIR/scripts/backup-system.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * * $CONTROL_PANEL_DIR/scripts/ssl-renew.sh") | crontab -
    (crontab -l 2>/dev/null; echo "*/15 * * * * $CONTROL_PANEL_DIR/scripts/monitor-system.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 4 * * 0 /usr/bin/sa-update && /usr/bin/systemctl restart spamassassin") | crontab -
    
    success "Cron jobs configured"
}

# Create Docker configuration
create_docker_config() {
    log "Creating Docker configuration..."
    
    cd $CONTROL_PANEL_DIR
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    mysql-client \
    curl \
    bash \
    openssl

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Build application
RUN npm run build

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Change ownership
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["npm", "start"]
EOF

    # Create docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hosting-panel:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.local
    volumes:
      - /var/www:/var/www:ro
      - /var/log/hosting-panel:/var/log/hosting-panel
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - mysql
    restart: unless-stopped
    networks:
      - hosting-network

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: hosting_panel
      MYSQL_USER: ${PANEL_DB_USER}
      MYSQL_PASSWORD: ${PANEL_DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    restart: unless-stopped
    networks:
      - hosting-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - hosting-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /var/www:/var/www:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - hosting-panel
    restart: unless-stopped
    networks:
      - hosting-network

volumes:
  mysql_data:
  redis_data:

networks:
  hosting-network:
    driver: bridge
EOF

    # Create nginx configuration for Docker
    cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    # Control Panel
    server {
        listen 80;
        server_name _;
        
        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name _;
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
        
        # Control Panel
        location / {
            proxy_pass http://hosting-panel:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
        
        # API rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://hosting-panel:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Login rate limiting
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://hosting-panel:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # phpMyAdmin
        location /phpmyadmin/ {
            root /var/www/html;
            index index.php;
            
            location ~ \.php$ {
                fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
            }
        }
    }
}
EOF

    success "Docker configuration created"
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
        .btn.secondary {
            background: #805ad5;
            box-shadow: 0 4px 15px rgba(128, 90, 213, 0.3);
        }
        .btn.secondary:hover {
            background: #6b46c1;
            box-shadow: 0 6px 20px rgba(128, 90, 213, 0.4);
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
        .footer {
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid #e2e8f0;
            color: #718096;
            font-size: 0.9rem;
        }
        @media (max-width: 768px) {
            .container { padding: 2rem 1.5rem; }
            h1 { font-size: 2rem; }
            .buttons { flex-direction: column; align-items: center; }
            .btn { width: 100%; max-width: 300px; justify-content: center; }
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
            <a href="/phpmyadmin" class="btn secondary">
                🗄️ phpMyAdmin
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
            
            <div class="info-card">
                <h3>📋 Quick Access</h3>
                <p><strong>Control Panel:</strong> :3000<br>
                <strong>phpMyAdmin:</strong> /phpmyadmin<br>
                <strong>Email:</strong> Ports 993, 587</p>
            </div>
            
            <div class="info-card">
                <h3>🛠️ Services</h3>
                <p><strong>Web Server:</strong> Apache<br>
                <strong>Database:</strong> MySQL 8.0<br>
                <strong>Mail Server:</strong> Postfix + Dovecot</p>
            </div>
        </div>
        
        <div class="footer">
            <p>🔒 Remember to secure your server and change default passwords<br>
            📚 For documentation and support, check the control panel</p>
        </div>
    </div>
</body>
</html>
EOF

    # Configure Apache virtual host for control panel
    if [[ "$PACKAGE_MANAGER" == "apt-get" ]]; then
        cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Proxy control panel
    ProxyPreserveHost On
    ProxyPass /control-panel/ http://localhost:3000/
    ProxyPassReverse /control-panel/ http://localhost:3000/
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    fi
    
    # Start services
    systemctl restart apache2 2>/dev/null || systemctl restart httpd
    systemctl restart mysql 2>/dev/null || systemctl restart mariadb
    systemctl restart postfix
    systemctl restart dovecot
    systemctl restart proftpd
    systemctl restart bind9 2>/dev/null || systemctl restart named
    systemctl restart fail2ban
    
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
    echo -e "${BLUE}phpMyAdmin:${NC}        http://$SERVER_IP/phpmyadmin"
    echo -e "${BLUE}Welcome Page:${NC}      http://$SERVER_IP"
    if [[ -n "$DOMAIN_NAME" ]]; then
        echo -e "${BLUE}Domain Access:${NC}     https://$DOMAIN_NAME:3000"
    fi
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
        "postfix:Mail Server (SMTP)"
        "dovecot:Mail Server (IMAP/POP3)"
        "proftpd:FTP Server"
        "bind9:DNS Server"
        "fail2ban:Security (Fail2Ban)"
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
    echo "   🔒 SSL Certificate Management (Let's Encrypt)"
    echo "   📧 Email Server (SMTP, IMAP, POP3)"
    echo "   🗄️ Database Management (MySQL, phpMyAdmin)"
    echo "   📁 File Manager with Code Editor"
    echo "   🔐 Security (2FA, IP Blocking, Firewall)"
    echo "   📊 Real-time System Monitoring"
    echo "   💾 Automated Backup System"
    echo "   🚀 One-click App Installers (WordPress, etc.)"
    echo "   👥 Multi-user Management"
    echo "   📱 Mobile-responsive Interface"
    echo "   🐳 Docker Support"
    echo ""
    
    echo -e "${GREEN}📝 NEXT STEPS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1. 🌐 Access control panel: http://$SERVER_IP:3000"
    echo "   2. 🔑 Change default admin password"
    echo "   3. 🌍 Add your first domain"
    echo "   4. 🔒 Set up SSL certificates"
    echo "   5. 📧 Create email accounts"
    echo "   6. 🗄️ Create databases"
    echo "   7. 🚀 Install applications (WordPress, etc.)"
    echo ""
    
    echo -e "${GREEN}🔧 MANAGEMENT COMMANDS:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Control Panel:  systemctl {start|stop|restart|status} hosting-panel"
    echo "   View Logs:       journalctl -u hosting-panel -f"
    echo "   Backup System:   $CONTROL_PANEL_DIR/scripts/backup-system.sh"
    echo "   SSL Renewal:     $CONTROL_PANEL_DIR/scripts/ssl-renew.sh"
    echo ""
    
    echo -e "${GREEN}📁 IMPORTANT FILES:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Control Panel:     $CONTROL_PANEL_DIR"
    echo "   MySQL Credentials: /root/.mysql_credentials"
    echo "   Web Files:         /var/www/html"
    echo "   Backups:           /var/backups/hosting-panel"
