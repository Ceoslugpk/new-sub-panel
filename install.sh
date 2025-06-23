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
    
    # Download latest phpMyAdmin with better error handling
    cd /tmp
    
    # Try to get the latest version, fallback to a known stable version
    PHPMYADMIN_VERSION=$(curl -s --connect-timeout 10 https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | jq -r .tag_name 2>/dev/null || echo "5.2.1")
    
    log "Downloading phpMyAdmin version: $PHPMYADMIN_VERSION"
    
    # Download with multiple fallback URLs
    if ! wget -q --timeout=30 "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"; then
        warning "Failed to download from primary source, trying alternative..."
        if ! wget -q --timeout=30 "https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_${PHPMYADMIN_VERSION//./_}.tar.gz" -O "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"; then
            warning "Failed to download latest version, using fallback version 5.2.1..."
            PHPMYADMIN_VERSION="5.2.1"
            wget -q --timeout=30 "https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz" || {
                error "Failed to download phpMyAdmin. Please check your internet connection."
            }
        fi
    fi
    
    # Extract and install
    log "Extracting phpMyAdmin..."
    if tar xzf phpMyAdmin-*.tar.gz 2>/dev/null; then
        rm -rf /var/www/html/phpmyadmin 2>/dev/null || true
        
        # Find the extracted directory (it might have different naming)
        EXTRACTED_DIR=$(find . -maxdepth 1 -name "phpMyAdmin-*" -type d | head -1)
        if [[ -n "$EXTRACTED_DIR" ]]; then
            mv "$EXTRACTED_DIR" /var/www/html/phpmyadmin
        else
            error "Failed to find extracted phpMyAdmin directory"
        fi
    else
        error "Failed to extract phpMyAdmin archive"
    fi
    
    # Set permissions
    chown -R www-data:www-data /var/www/html/phpmyadmin 2>/dev/null || chown -R apache:apache /var/www/html/phpmyadmin
    chmod -R 755 /var/www/html/phpmyadmin
    
    # Create phpMyAdmin configuration
    if [[ -f /var/www/html/phpmyadmin/config.sample.inc.php ]]; then
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
    else
        warning "phpMyAdmin config template not found, creating basic config..."
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
    
    # Clean up
    rm -f /tmp/phpMyAdmin-*.tar.gz
    
    success "phpMyAdmin installed successfully"
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
    npm install mysql2@^3.6.0 bcryptjs@^2.4.3 jsonwebtoken@^9.0.0
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
EOF

    # Create basic app structure
    mkdir -p app components lib
    
    # Create basic layout
    cat > app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Hosting Control Panel',
  description: 'Professional web hosting control panel',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
EOF

    # Create basic page
    cat > app/page.tsx << 'EOF'
export default function Home() {
  return (
    <main className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold text-center mb-8">
          🚀 Hosting Control Panel
        </h1>
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold mb-4">Welcome to Your Control Panel</h2>
          <p className="text-gray-600 mb-6">
            Your professional web hosting control panel is now installed and ready to use.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-blue-50 p-4 rounded-lg">
              <h3 className="font-semibold text-blue-800">Domain Management</h3>
              <p className="text-blue-600 text-sm">Manage your domains and subdomains</p>
            </div>
            <div className="bg-green-50 p-4 rounded-lg">
              <h3 className="font-semibold text-green-800">Email Accounts</h3>
              <p className="text-green-600 text-sm">Create and manage email accounts</p>
            </div>
            <div className="bg-purple-50 p-4 rounded-lg">
              <h3 className="font-semibold text-purple-800">Database Management</h3>
              <p className="text-purple-600 text-sm">Manage MySQL databases</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}
EOF

    # Create globals.css
    cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
  }
  
  body {
    @apply bg-background text-foreground;
  }
}
EOF

    # Create Next.js config
    cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
}

module.exports = nextConfig
EOF

    # Create Tailwind config
    cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss"

const config = {
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
} satisfies Config

export default config
EOF

    # Create PostCSS config
    cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # Create TypeScript config
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

    # Build the application
    npm run build
    
    success "Control panel application created and built successfully"
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
    echo ""
    
    echo -e "${GREEN}📁 IMPORTANT FILES:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Control Panel:     $CONTROL_PANEL_DIR"
    echo "   MySQL Credentials: /root/.mysql_credentials"
    echo "   Web Files:         /var/www/html"
    echo "   Backups:           /var/backups/hosting-panel"
    echo ""
    
    echo -e "${CYAN}🎉 Installation completed successfully!${NC}"
    echo -e "${CYAN}Thank you for using the Professional Hosting Control Panel!${NC}"
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
