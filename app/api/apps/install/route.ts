import { type NextRequest, NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"
import mysql from "mysql2/promise"

const execAsync = promisify(exec)

const dbConfig = {
  host: "localhost",
  user: "panel_user",
  password: process.env.PANEL_DB_PASSWORD,
  database: "hosting_panel",
}

export async function POST(request: NextRequest) {
  try {
    const { domain, app, dbName, dbUser, dbPassword } = await request.json()

    if (!domain || !app) {
      return NextResponse.json({ error: "Domain and app are required" }, { status: 400 })
    }

    const documentRoot = `/var/www/${domain}`

    // Check if domain exists
    const connection = await mysql.createConnection(dbConfig)
    const [domainRows] = await connection.execute("SELECT * FROM domains WHERE name = ?", [domain])

    if ((domainRows as any[]).length === 0) {
      await connection.end()
      return NextResponse.json({ error: "Domain not found" }, { status: 404 })
    }

    let installResult = {}

    switch (app) {
      case "wordpress":
        installResult = await installWordPress(domain, documentRoot, dbName, dbUser, dbPassword)
        break
      case "joomla":
        installResult = await installJoomla(domain, documentRoot, dbName, dbUser, dbPassword)
        break
      case "drupal":
        installResult = await installDrupal(domain, documentRoot, dbName, dbUser, dbPassword)
        break
      case "laravel":
        installResult = await installLaravel(domain, documentRoot, dbName, dbUser, dbPassword)
        break
      case "nextjs":
        installResult = await installNextJS(domain, documentRoot)
        break
      default:
        await connection.end()
        return NextResponse.json({ error: "Unsupported application" }, { status: 400 })
    }

    // Save installation record
    await connection.execute(
      "INSERT INTO app_installations (domain, app_name, status, installed_at) VALUES (?, ?, ?, NOW())",
      [domain, app, "installed"],
    )
    await connection.end()

    return NextResponse.json({
      success: true,
      message: `${app} installed successfully on ${domain}`,
      ...installResult,
    })
  } catch (error: any) {
    console.error("App installation error:", error)
    return NextResponse.json({ error: `Failed to install app: ${error.message}` }, { status: 500 })
  }
}

async function installWordPress(
  domain: string,
  documentRoot: string,
  dbName: string,
  dbUser: string,
  dbPassword: string,
) {
  // Create database
  await execAsync(`mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${dbName};"`)
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${dbUser}'@'localhost' IDENTIFIED BY '${dbPassword}';"`,
  )
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${dbName}.* TO '${dbUser}'@'localhost';"`,
  )
  await execAsync(`mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"`)

  // Download WordPress
  await execAsync(`cd /tmp && wget https://wordpress.org/latest.tar.gz`)
  await execAsync(`cd /tmp && tar xzf latest.tar.gz`)
  await execAsync(`cp -r /tmp/wordpress/* ${documentRoot}/`)
  await execAsync(`chown -R www-data:www-data ${documentRoot}`)
  await execAsync(`chmod -R 755 ${documentRoot}`)

  // Create wp-config.php
  const wpConfig = `<?php
define('DB_NAME', '${dbName}');
define('DB_USER', '${dbUser}');
define('DB_PASSWORD', '${dbPassword}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         '${generateRandomString(64)}');
define('SECURE_AUTH_KEY',  '${generateRandomString(64)}');
define('LOGGED_IN_KEY',    '${generateRandomString(64)}');
define('NONCE_KEY',        '${generateRandomString(64)}');
define('AUTH_SALT',        '${generateRandomString(64)}');
define('SECURE_AUTH_SALT', '${generateRandomString(64)}');
define('LOGGED_IN_SALT',   '${generateRandomString(64)}');
define('NONCE_SALT',       '${generateRandomString(64)}');

$table_prefix = 'wp_';
define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
`

  await fs.writeFile(`${documentRoot}/wp-config.php`, wpConfig)

  // Clean up
  await execAsync(`rm -f /tmp/latest.tar.gz`)
  await execAsync(`rm -rf /tmp/wordpress`)

  return {
    app: "WordPress",
    database: dbName,
    adminUrl: `http://${domain}/wp-admin/`,
    setupUrl: `http://${domain}/wp-admin/install.php`,
  }
}

async function installJoomla(domain: string, documentRoot: string, dbName: string, dbUser: string, dbPassword: string) {
  // Create database
  await execAsync(`mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${dbName};"`)
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${dbUser}'@'localhost' IDENTIFIED BY '${dbPassword}';"`,
  )
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${dbName}.* TO '${dbUser}'@'localhost';"`,
  )

  // Download Joomla
  await execAsync(`cd /tmp && wget https://downloads.joomla.org/cms/joomla4/4-4-0/Joomla_4-4-0-Stable-Full_Package.zip`)
  await execAsync(`cd /tmp && unzip -q Joomla_4-4-0-Stable-Full_Package.zip -d joomla`)
  await execAsync(`cp -r /tmp/joomla/* ${documentRoot}/`)
  await execAsync(`chown -R www-data:www-data ${documentRoot}`)
  await execAsync(`chmod -R 755 ${documentRoot}`)

  // Clean up
  await execAsync(`rm -f /tmp/Joomla_4-4-0-Stable-Full_Package.zip`)
  await execAsync(`rm -rf /tmp/joomla`)

  return {
    app: "Joomla",
    database: dbName,
    setupUrl: `http://${domain}/installation/`,
  }
}

async function installDrupal(domain: string, documentRoot: string, dbName: string, dbUser: string, dbPassword: string) {
  // Create database
  await execAsync(`mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${dbName};"`)
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${dbUser}'@'localhost' IDENTIFIED BY '${dbPassword}';"`,
  )
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${dbName}.* TO '${dbUser}'@'localhost';"`,
  )

  // Download Drupal
  await execAsync(`cd /tmp && wget https://ftp.drupal.org/files/projects/drupal-10.1.6.tar.gz`)
  await execAsync(`cd /tmp && tar xzf drupal-10.1.6.tar.gz`)
  await execAsync(`cp -r /tmp/drupal-10.1.6/* ${documentRoot}/`)
  await execAsync(`chown -R www-data:www-data ${documentRoot}`)
  await execAsync(`chmod -R 755 ${documentRoot}`)

  // Clean up
  await execAsync(`rm -f /tmp/drupal-10.1.6.tar.gz`)
  await execAsync(`rm -rf /tmp/drupal-10.1.6`)

  return {
    app: "Drupal",
    database: dbName,
    setupUrl: `http://${domain}/core/install.php`,
  }
}

async function installLaravel(
  domain: string,
  documentRoot: string,
  dbName: string,
  dbUser: string,
  dbPassword: string,
) {
  // Install Composer if not exists
  try {
    await execAsync("composer --version")
  } catch {
    await execAsync(
      "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer",
    )
  }

  // Create Laravel project
  await execAsync(`composer create-project laravel/laravel ${documentRoot} --prefer-dist`)
  await execAsync(`chown -R www-data:www-data ${documentRoot}`)
  await execAsync(`chmod -R 755 ${documentRoot}`)
  await execAsync(`chmod -R 775 ${documentRoot}/storage ${documentRoot}/bootstrap/cache`)

  // Create database
  await execAsync(`mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${dbName};"`)
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${dbUser}'@'localhost' IDENTIFIED BY '${dbPassword}';"`,
  )
  await execAsync(
    `mysql -u root -p${process.env.MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${dbName}.* TO '${dbUser}'@'localhost';"`,
  )

  // Configure .env
  const envContent = `APP_NAME=Laravel
APP_ENV=production
APP_KEY=base64:${Buffer.from(generateRandomString(32)).toString("base64")}
APP_DEBUG=false
APP_URL=http://${domain}

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=${dbName}
DB_USERNAME=${dbUser}
DB_PASSWORD=${dbPassword}
`

  await fs.writeFile(`${documentRoot}/.env`, envContent)

  return {
    app: "Laravel",
    database: dbName,
    url: `http://${domain}/public/`,
  }
}

async function installNextJS(domain: string, documentRoot: string) {
  // Create Next.js project
  await execAsync(
    `npx create-next-app@latest ${documentRoot} --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`,
  )
  await execAsync(`chown -R www-data:www-data ${documentRoot}`)
  await execAsync(`chmod -R 755 ${documentRoot}`)

  // Build the project
  await execAsync(`cd ${documentRoot} && npm run build`)

  return {
    app: "Next.js",
    url: `http://${domain}:3000/`,
    note: "Next.js requires Node.js runtime. Configure PM2 or similar process manager.",
  }
}

function generateRandomString(length: number): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
  let result = ""
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

export async function GET() {
  try {
    const apps = [
      {
        id: "wordpress",
        name: "WordPress",
        description: "Popular CMS for blogs and websites",
        icon: "📝",
        category: "CMS",
        requirements: ["PHP", "MySQL"],
      },
      {
        id: "joomla",
        name: "Joomla",
        description: "Flexible content management system",
        icon: "🏗️",
        category: "CMS",
        requirements: ["PHP", "MySQL"],
      },
      {
        id: "drupal",
        name: "Drupal",
        description: "Advanced content management platform",
        icon: "🔧",
        category: "CMS",
        requirements: ["PHP", "MySQL"],
      },
      {
        id: "laravel",
        name: "Laravel",
        description: "PHP framework for web applications",
        icon: "⚡",
        category: "Framework",
        requirements: ["PHP", "Composer", "MySQL"],
      },
      {
        id: "nextjs",
        name: "Next.js",
        description: "React framework for production",
        icon: "⚛️",
        category: "Framework",
        requirements: ["Node.js", "npm"],
      },
    ]

    return NextResponse.json({ apps })
  } catch (error: any) {
    return NextResponse.json({ error: "Failed to fetch apps" }, { status: 500 })
  }
}
