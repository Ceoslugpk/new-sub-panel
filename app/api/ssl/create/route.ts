import { type NextRequest, NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function POST(request: NextRequest) {
  try {
    const { domain, email } = await request.json()

    if (!domain || !email) {
      return NextResponse.json({ error: "Domain and email are required" }, { status: 400 })
    }

    // Check if certbot is installed
    try {
      await execAsync("which certbot")
    } catch (error) {
      return NextResponse.json({ error: "Certbot is not installed" }, { status: 500 })
    }

    // Generate SSL certificate using Let's Encrypt
    const command = `certbot --apache -d ${domain} --email ${email} --agree-tos --non-interactive`

    try {
      const { stdout, stderr } = await execAsync(command)

      return NextResponse.json({
        success: true,
        message: `SSL certificate generated for ${domain}`,
        output: stdout,
      })
    } catch (error: any) {
      return NextResponse.json({ error: `Failed to generate SSL certificate: ${error.message}` }, { status: 500 })
    }
  } catch (error) {
    console.error("SSL creation error:", error)
    return NextResponse.json({ error: "Failed to create SSL certificate" }, { status: 500 })
  }
}
