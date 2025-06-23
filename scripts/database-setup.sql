-- Create hosting_panel database if not exists
CREATE DATABASE IF NOT EXISTS hosting_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
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
    name VARCHAR(255) UNIQUE NOT NULL,
    document_root VARCHAR(500) NOT NULL,
    status ENUM('active', 'suspended', 'pending') DEFAULT 'active',
    ssl_enabled BOOLEAN DEFAULT FALSE,
    ssl_cert_path VARCHAR(500),
    ssl_key_path VARCHAR(500),
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_user_id (user_id)
);

-- Email accounts table
CREATE TABLE IF NOT EXISTS email_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    quota_mb INT DEFAULT 1000,
    used_mb INT DEFAULT 0,
    domain_id INT,
    user_id INT,
    status ENUM('active', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_domain_id (domain_id),
    INDEX idx_user_id (user_id)
);

-- Databases table
CREATE TABLE IF NOT EXISTS databases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL,
    username VARCHAR(32) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    size_mb DECIMAL(10,2) DEFAULT 0.00,
    user_id INT,
    status ENUM('active', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_username (username),
    INDEX idx_user_id (user_id)
);

-- Application installations table
CREATE TABLE IF NOT EXISTS app_installations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    app_name VARCHAR(100) NOT NULL,
    app_version VARCHAR(50),
    installation_path VARCHAR(500),
    database_name VARCHAR(64),
    status ENUM('installed', 'failed', 'updating') DEFAULT 'installed',
    user_id INT,
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_domain (domain),
    INDEX idx_app_name (app_name),
    INDEX idx_user_id (user_id)
);

-- System logs table
CREATE TABLE IF NOT EXISTS system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- Insert sample users with hashed passwords
-- Password for all users: admin123, user123, reseller123 respectively
INSERT INTO users (username, email, password_hash, role, status) VALUES
('admin', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'active'),
('user1', 'user1@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', 'active'),
('reseller1', 'reseller1@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'reseller', 'active'),
('demo', 'demo@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', 'active'),
('testuser', 'test@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', 'active')
ON DUPLICATE KEY UPDATE 
    email = VALUES(email),
    role = VALUES(role),
    status = VALUES(status);

-- Insert sample domains
INSERT INTO domains (name, document_root, status, user_id) VALUES
('example.com', '/var/www/example.com', 'active', 1),
('demo.local', '/var/www/demo.local', 'active', 2),
('test.site', '/var/www/test.site', 'active', 1)
ON DUPLICATE KEY UPDATE 
    document_root = VALUES(document_root),
    status = VALUES(status);

-- Insert sample email accounts
INSERT INTO email_accounts (email, password_hash, quota_mb, domain_id, user_id) VALUES
('admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2000, 1, 1),
('info@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1000, 1, 1),
('support@demo.local', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1500, 2, 2)
ON DUPLICATE KEY UPDATE 
    quota_mb = VALUES(quota_mb);

-- Insert sample databases
INSERT INTO databases (name, username, password_hash, user_id) VALUES
('example_db', 'example_user', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1),
('demo_database', 'demo_user', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2),
('test_db', 'test_user', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1)
ON DUPLICATE KEY UPDATE 
    username = VALUES(username);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_domains_user_status ON domains(user_id, status);
CREATE INDEX IF NOT EXISTS idx_email_domain_status ON email_accounts(domain_id, status);
CREATE INDEX IF NOT EXISTS idx_databases_user_status ON databases(user_id, status);
CREATE INDEX IF NOT EXISTS idx_logs_user_date ON system_logs(user_id, created_at);

-- Grant permissions to panel user
GRANT ALL PRIVILEGES ON hosting_panel.* TO 'panel_user'@'localhost';
FLUSH PRIVILEGES;
