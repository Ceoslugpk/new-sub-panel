"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Server,
  Database,
  Mail,
  Globe,
  Shield,
  HardDrive,
  Users,
  Activity,
  Cpu,
  MemoryStick,
  Network,
  AlertTriangle,
  CheckCircle,
  Clock,
} from "lucide-react"

interface SystemStats {
  cpu: number
  memory: number
  disk: number
  network: number
  uptime: string
  load: string
}

interface ServiceStatus {
  name: string
  status: "running" | "stopped" | "error"
  port?: number
}

export default function Dashboard() {
  const [stats, setStats] = useState<SystemStats>({
    cpu: 0,
    memory: 0,
    disk: 0,
    network: 0,
    uptime: "0d 0h 0m",
    load: "0.00",
  })

  const [services, setServices] = useState<ServiceStatus[]>([
    { name: "Apache", status: "running", port: 80 },
    { name: "MySQL", status: "running", port: 3306 },
    { name: "PHP-FPM", status: "running" },
    { name: "Postfix", status: "running", port: 25 },
    { name: "Dovecot", status: "running", port: 993 },
    { name: "BIND", status: "running", port: 53 },
    { name: "ProFTPD", status: "running", port: 21 },
    { name: "Fail2Ban", status: "running" },
  ])

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await fetch("/api/system/stats")
        if (response.ok) {
          const data = await response.json()
          setStats(data)
        }
      } catch (error) {
        console.error("Failed to fetch system stats:", error)
      }
    }

    const fetchServices = async () => {
      try {
        const response = await fetch("/api/system/services")
        if (response.ok) {
          const data = await response.json()
          setServices(data)
        }
      } catch (error) {
        console.error("Failed to fetch services:", error)
      }
    }

    fetchStats()
    fetchServices()

    const interval = setInterval(() => {
      fetchStats()
      fetchServices()
    }, 5000)

    return () => clearInterval(interval)
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case "running":
        return "bg-green-500"
      case "stopped":
        return "bg-yellow-500"
      case "error":
        return "bg-red-500"
      default:
        return "bg-gray-500"
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "running":
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case "stopped":
        return <Clock className="h-4 w-4 text-yellow-500" />
      case "error":
        return <AlertTriangle className="h-4 w-4 text-red-500" />
      default:
        return <AlertTriangle className="h-4 w-4 text-gray-500" />
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Server Control Panel</h1>
            <p className="text-gray-600">Manage your VPS hosting environment</p>
          </div>
          <div className="flex items-center space-x-2">
            <Badge variant="outline" className="text-green-600 border-green-600">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
              Online
            </Badge>
          </div>
        </div>

        {/* System Overview Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">CPU Usage</CardTitle>
              <Cpu className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.cpu.toFixed(1)}%</div>
              <Progress value={stats.cpu} className="mt-2" />
              <p className="text-xs text-muted-foreground mt-2">Load: {stats.load}</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Memory Usage</CardTitle>
              <MemoryStick className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.memory.toFixed(1)}%</div>
              <Progress value={stats.memory} className="mt-2" />
              <p className="text-xs text-muted-foreground mt-2">Available RAM</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Disk Usage</CardTitle>
              <HardDrive className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.disk.toFixed(1)}%</div>
              <Progress value={stats.disk} className="mt-2" />
              <p className="text-xs text-muted-foreground mt-2">Storage space</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Network</CardTitle>
              <Network className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.network.toFixed(1)} MB/s</div>
              <p className="text-xs text-muted-foreground mt-2">Uptime: {stats.uptime}</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-6">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="files">Files</TabsTrigger>
            <TabsTrigger value="databases">Databases</TabsTrigger>
            <TabsTrigger value="email">Email</TabsTrigger>
            <TabsTrigger value="domains">Domains</TabsTrigger>
            <TabsTrigger value="security">Security</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Services Status */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Activity className="h-5 w-5 mr-2" />
                    System Services
                  </CardTitle>
                  <CardDescription>Current status of all system services</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {services.map((service, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex items-center space-x-3">
                          {getStatusIcon(service.status)}
                          <div>
                            <p className="font-medium">{service.name}</p>
                            {service.port && <p className="text-sm text-gray-500">Port: {service.port}</p>}
                          </div>
                        </div>
                        <Badge
                          variant={service.status === "running" ? "default" : "destructive"}
                          className={service.status === "running" ? "bg-green-500" : ""}
                        >
                          {service.status}
                        </Badge>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              {/* Quick Actions */}
              <Card>
                <CardHeader>
                  <CardTitle>Quick Actions</CardTitle>
                  <CardDescription>Common administrative tasks</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-4">
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Server className="h-6 w-6 mb-2" />
                      Restart Services
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Database className="h-6 w-6 mb-2" />
                      Backup Database
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Shield className="h-6 w-6 mb-2" />
                      Security Scan
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Activity className="h-6 w-6 mb-2" />
                      View Logs
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="files">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <HardDrive className="h-5 w-5 mr-2" />
                  File Management
                </CardTitle>
                <CardDescription>Manage your server files and directories</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Button variant="outline" className="h-24 flex flex-col">
                    <HardDrive className="h-8 w-8 mb-2" />
                    File Manager
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Network className="h-8 w-8 mb-2" />
                    FTP Accounts
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Shield className="h-8 w-8 mb-2" />
                    Directory Privacy
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="databases">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Database className="h-5 w-5 mr-2" />
                  Database Management
                </CardTitle>
                <CardDescription>Manage MySQL and PostgreSQL databases</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Database className="h-8 w-8 mb-2" />
                    MySQL Databases
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Users className="h-8 w-8 mb-2" />
                    Database Users
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Activity className="h-8 w-8 mb-2" />
                    phpMyAdmin
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="email">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Mail className="h-5 w-5 mr-2" />
                  Email Management
                </CardTitle>
                <CardDescription>Configure email accounts and settings</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Mail className="h-8 w-8 mb-2" />
                    Email Accounts
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Network className="h-8 w-8 mb-2" />
                    Email Forwarders
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Shield className="h-8 w-8 mb-2" />
                    Email Filters
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="domains">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Globe className="h-5 w-5 mr-2" />
                  Domain Management
                </CardTitle>
                <CardDescription>Manage domains, subdomains, and DNS settings</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Globe className="h-8 w-8 mb-2" />
                    Addon Domains
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Network className="h-8 w-8 mb-2" />
                    Subdomains
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Activity className="h-8 w-8 mb-2" />
                    DNS Zone Editor
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="security">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Shield className="h-5 w-5 mr-2" />
                  Security Management
                </CardTitle>
                <CardDescription>Configure security settings and SSL certificates</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Shield className="h-8 w-8 mb-2" />
                    SSL/TLS Certificates
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Users className="h-8 w-8 mb-2" />
                    Two-Factor Auth
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Activity className="h-8 w-8 mb-2" />
                    IP Blocker
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
