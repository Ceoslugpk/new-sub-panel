import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function GET() {
  try {
    // Get CPU usage
    const { stdout: cpuInfo } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1")
    const cpu = Number.parseFloat(cpuInfo.trim()) || 0

    // Get memory usage
    const { stdout: memInfo } = await execAsync("free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'")
    const memory = Number.parseFloat(memInfo.trim()) || 0

    // Get disk usage
    const { stdout: diskInfo } = await execAsync("df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1")
    const disk = Number.parseFloat(diskInfo.trim()) || 0

    // Get network usage (simplified)
    const network = Math.random() * 100 // Placeholder for actual network monitoring

    // Get uptime
    const { stdout: uptimeInfo } = await execAsync("uptime -p")
    const uptime = uptimeInfo.trim().replace("up ", "") || "0 minutes"

    // Get load average
    const { stdout: loadInfo } = await execAsync(
      "uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1",
    )
    const load = loadInfo.trim() || "0.00"

    return NextResponse.json({
      cpu,
      memory,
      disk,
      network,
      uptime,
      load,
    })
  } catch (error) {
    console.error("Error fetching system stats:", error)
    return NextResponse.json({
      cpu: 0,
      memory: 0,
      disk: 0,
      network: 0,
      uptime: "Unknown",
      load: "0.00",
    })
  }
}
