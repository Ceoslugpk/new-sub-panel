import { NextResponse } from "next/server"

export async function GET() {
  try {
    const services = [
      { name: "Apache", status: "running", port: 80 },
      { name: "MySQL", status: "running", port: 3306 },
      { name: "PHP-FPM", status: "running" },
      { name: "Postfix", status: "running", port: 25 },
      { name: "Dovecot", status: "running", port: 993 },
      { name: "BIND", status: "running", port: 53 },
      { name: "ProFTPD", status: "running", port: 21 },
      { name: "Fail2Ban", status: "running" },
    ]

    return NextResponse.json(services)
  } catch (error) {
    console.error("Error fetching services:", error)
    return NextResponse.json({ error: "Failed to fetch services" }, { status: 500 })
  }
}
