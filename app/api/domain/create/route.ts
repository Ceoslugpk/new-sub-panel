import { type NextRequest, NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import fs from "fs/promises"

const execAsync = promisify(exec)

export async function POST(request: NextRequest) {
  try {
    const { domain, documentRoot = `/var/www/${domain}` } = await request.json()

    if (!domain) {
      return NextResponse.json({ error: "Domain is required" }, { status: 400 })
    }

    // Create document root directory
    await execAsync(`mkdir -p ${documentRoot}`)
    await execAsync(`chown -R www-data:www-data ${documentRoot}`)
    await execAsync(`chmod -R 755 ${documentRoot}`)

    // Create Apache virtual host configuration
    const vhostConfig = `
<VirtualHost *:80>
    ServerName ${domain}
    ServerAlias www.${domain}
    DocumentRoot ${documentRoot}
    
    <Directory ${documentRoot}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
</VirtualHost>
`

    // Write virtual host configuration
    await fs.writeFile(`/etc/apache2/sites-available/${domain}.conf`, vhostConfig)

    // Enable the site
    await execAsync(`a2ensite ${domain}.conf`)

    // Test Apache configuration
    await execAsync("apache2ctl configtest")

    // Reload Apache
    await execAsync("systemctl reload apache2")

    // Create a default index.html
    const indexHtml = `
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to ${domain}</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${domain}</h1>
        <p>Your domain has been successfully configured!</p>
        <p>You can now upload your website files to: ${documentRoot}</p>
    </div>
</body>
</html>
`

    await fs.writeFile(`${documentRoot}/index.html`, indexHtml)

    return NextResponse.json({
      success: true,
      message: `Domain ${domain} created successfully`,
      documentRoot,
    })
  } catch (error: any) {
    console.error("Domain creation error:", error)
    return NextResponse.json({ error: `Failed to create domain: ${error.message}` }, { status: 500 })
  }
}
