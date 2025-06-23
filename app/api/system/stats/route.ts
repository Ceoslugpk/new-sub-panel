import { NextResponse } from "next/server"

export async function GET() {
  try {
    // Mock system statistics
    const stats = {
      cpu: Math.random() * 100,
      memory: Math.random() * 100,
      disk: Math.random() * 100,
      network: Math.random() * 10,
      uptime: "5d 12h 30m",
      load: (Math.random() * 2).toFixed(2),
    }

    return NextResponse.json(stats)
  } catch (error) {
    console.error("Error fetching system stats:", error)
    return NextResponse.json({ error: "Failed to fetch system stats" }, { status: 500 })
  }
}
