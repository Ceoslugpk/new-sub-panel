import { NextResponse } from "next/server"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)

interface ServiceStatus {
  name: string
  status: "running" | "stopped" | "error"
  port?: number
}

export async function GET() {
  const services: ServiceStatus[] = [
    { name: "Apache", port: 80 },
    { name: "MySQL", port: 3306 },
    { name: "PHP-FPM" },
    { name: "Postfix", port: 25 },
    { name: "Dovecot", port: 993 },
    { name: "BIND", port: 53 },
    { name: "ProFTPD", port: 21 },
    { name: "Fail2Ban" },
  ]

  const serviceStatuses = await Promise.all(
    services.map(async (service) => {
      try {
        const serviceName = service.name.toLowerCase()
        let command = ""

        switch (serviceName) {
          case "apache":
            command = "systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null"
            break
          case "mysql":
            command =
              "systemctl is-active mysql 2>/dev/null || systemctl is-active mysqld 2>/dev/null || systemctl is-active mariadb 2>/dev/null"
            break
          case "php-fpm":
            command = "systemctl is-active php*-fpm 2>/dev/null"
            break
          case "postfix":
            command = "systemctl is-active postfix 2>/dev/null"
            break
          case "dovecot":
            command = "systemctl is-active dovecot 2>/dev/null"
            break
          case "bind":
            command = "systemctl is-active bind9 2>/dev/null || systemctl is-active named 2>/dev/null"
            break
          case "proftpd":
            command = "systemctl is-active proftpd 2>/dev/null"
            break
          case "fail2ban":
            command = "systemctl is-active fail2ban 2>/dev/null"
            break
          default:
            command = `systemctl is-active ${serviceName} 2>/dev/null`
        }

        const { stdout } = await execAsync(command)
        const status = stdout.trim() === "active" ? "running" : "stopped"

        return {
          ...service,
          status,
        }
      } catch (error) {
        return {
          ...service,
          status: "error" as const,
        }
      }
    }),
  )

  return NextResponse.json(serviceStatuses)
}
