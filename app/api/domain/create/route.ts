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
    const { domain, documentRoot = `/var/www/${domain}`, subdomain = "" } = await request.json()

    if (!domain) {
      return NextResponse.json({ error: "Domain is required" }, { status: 400 })
    }

    const fullDomain = subdomain ? `${subdomain}.${domain}` : domain
    const fullDocumentRoot = subdomain ? `/var/www/${fullDomain}` : documentRoot

    // Create document root directory
    await execAsync(`mkdir -p ${fullDocumentRoot}`)
    await execAsync(`chown -R www-data:www-data ${fullDocumentRoot}`)
    await execAsync(`chmod -R 755 ${fullDocumentRoot}`)

    // Create Apache virtual host configuration
    const vhostConfig = `
<VirtualHost *:80>
    ServerName ${fullDomain}
    ${!subdomain ? `ServerAlias www.${domain}` : ""}
    DocumentRoot ${fullDocumentRoot}
    
    <Directory ${fullDocumentRoot}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${fullDomain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${fullDomain}_access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
`

    // Write virtual host configuration
    await fs.writeFile(`/etc/apache2/sites-available/${fullDomain}.conf`, vhostConfig)

    // Enable the site
    await execAsync(`a2ensite ${fullDomain}.conf`)

    // Test Apache configuration
    await execAsync("apache2ctl configtest")

    // Reload Apache
    await execAsync("systemctl reload apache2")

    // Create a default index.html with better styling
    const indexHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to ${fullDomain}</title>
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
        .logo { font-size: 3rem; margin-bottom: 1rem; }
        h1 { color: #2d3748; margin-bottom: 1rem; font-size: 2.5rem; font-weight: 700; }
        .subtitle { color: #718096; margin-bottom: 2rem; font-size: 1.2rem; }
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
        .info {
            background: #f7fafc;
            padding: 1.5rem;
            border-radius: 10px;
            border-left: 4px solid #4299e1;
            text-align: left;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐</div>
        <h1>Welcome to ${fullDomain}</h1>
        <p class="subtitle">Your domain has been successfully configured!</p>
        
        <div class="status">
            ✅ Domain is active and ready!
        </div>
        
        <div class="info">
            <h3>Domain Information:</h3>
            <p><strong>Domain:</strong> ${fullDomain}</p>
            <p><strong>Document Root:</strong> ${fullDocumentRoot}</p>
            <p><strong>Status:</strong> Active</p>
            <p><strong>Created:</strong> ${new Date().toLocaleString()}</p>
        </div>
    </div>
</body>
</html>
`

    await fs.writeFile(`${fullDocumentRoot}/index.html`, indexHtml)

    // Save to database
    const connection = await mysql.createConnection(dbConfig)
    await connection.execute("INSERT INTO domains (name, document_root, status, created_at) VALUES (?, ?, ?, NOW())", [
      fullDomain,
      fullDocumentRoot,
      "active",
    ])
    await connection.end()

    return NextResponse.json({
      success: true,
      message: `Domain ${fullDomain} created successfully`,
      domain: fullDomain,
      documentRoot: fullDocumentRoot,
    })
  } catch (error: any) {
    console.error("Domain creation error:", error)
    return NextResponse.json({ error: `Failed to create domain: ${error.message}` }, { status: 500 })
  }
}

export async function GET() {
  try {
    const connection = await mysql.createConnection(dbConfig)
    const [rows] = await connection.execute("SELECT * FROM domains ORDER BY created_at DESC")
    await connection.end()

    return NextResponse.json({ domains: rows })
  } catch (error: any) {
    console.error("Failed to fetch domains:", error)
    return NextResponse.json({ error: "Failed to fetch domains" }, { status: 500 })
  }
}
