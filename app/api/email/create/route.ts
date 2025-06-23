import { type NextRequest, NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"
import bcrypt from "bcryptjs"

const execAsync = promisify(exec)

export async function POST(request: NextRequest) {
  try {
    const { email, password, quota = 1000 } = await request.json()

    if (!email || !password) {
      return NextResponse.json({ error: "Email and password are required" }, { status: 400 })
    }

    const [username, domain] = email.split("@")

    if (!username || !domain) {
      return NextResponse.json({ error: "Invalid email format" }, { status: 400 })
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10)

    // Create system user for email
    try {
      await execAsync(`useradd -m -s /bin/false ${username}`)
    } catch (error) {
      // User might already exist, continue
    }

    // Create mail directory
    await execAsync(`mkdir -p /var/mail/${domain}/${username}`)
    await execAsync(`chown -R mail:mail /var/mail/${domain}`)
    await execAsync(`chmod -R 755 /var/mail/${domain}`)

    // Add to virtual users file (Postfix)
    const virtualUsersPath = "/etc/postfix/virtual_users"
    await execAsync(`echo "${email} ${username}" >> ${virtualUsersPath}`)
    await execAsync("postmap /etc/postfix/virtual_users")

    // Add to Dovecot users file
    const dovecotUsersPath = "/etc/dovecot/users"
    await execAsync(`echo "${email}:${hashedPassword}::::::" >> ${dovecotUsersPath}`)

    // Reload services
    await execAsync("systemctl reload postfix")
    await execAsync("systemctl reload dovecot")

    return NextResponse.json({
      success: true,
      message: `Email account ${email} created successfully`,
    })
  } catch (error) {
    console.error("Email creation error:", error)
    return NextResponse.json({ error: "Failed to create email account" }, { status: 500 })
  }
}
