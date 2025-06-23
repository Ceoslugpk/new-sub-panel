import { type NextRequest, NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

export async function POST(request: NextRequest) {
  try {
    const { type, name } = await request.json()

    if (!type || !name) {
      return NextResponse.json({ error: "Backup type and name are required" }, { status: 400 })
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-")
    const backupDir = "/var/backups/control-panel"

    // Create backup directory
    await execAsync(`mkdir -p ${backupDir}`)

    let backupCommand = ""
    let backupFile = ""

    switch (type) {
      case "database":
        backupFile = `${backupDir}/${name}_${timestamp}.sql`
        backupCommand = `mysqldump -u root -p${process.env.MYSQL_ROOT_PASSWORD} ${name} > ${backupFile}`
        break

      case "website":
        backupFile = `${backupDir}/${name}_${timestamp}.tar.gz`
        backupCommand = `tar -czf ${backupFile} -C /var/www ${name}`
        break

      case "full":
        backupFile = `${backupDir}/full_backup_${timestamp}.tar.gz`
        backupCommand = `tar -czf ${backupFile} --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/var/backups /`
        break

      default:
        return NextResponse.json({ error: "Invalid backup type" }, { status: 400 })
    }

    // Execute backup command
    await execAsync(backupCommand)

    // Compress and set permissions
    await execAsync(`chmod 600 ${backupFile}`)

    return NextResponse.json({
      success: true,
      message: `Backup created successfully`,
      backupFile,
      timestamp,
    })
  } catch (error: any) {
    console.error("Backup creation error:", error)
    return NextResponse.json({ error: `Failed to create backup: ${error.message}` }, { status: 500 })
  }
}
