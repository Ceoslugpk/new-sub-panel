"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { toast } from "@/components/ui/use-toast"
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
  Plus,
  Settings,
  FileText,
  Download,
  Upload,
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

interface Domain {
  id: number
  name: string
  status: string
  created: string
}

interface EmailAccount {
  id: number
  email: string
  quota: number
  used: number
  created: string
}

interface DatabaseAccount {
  id: number
  name: string
  user: string
  size: string
  created: string
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

  const [domains, setDomains] = useState<Domain[]>([])
  const [emails, setEmails] = useState<EmailAccount[]>([])
  const [databases, setDatabases] = useState<DatabaseAccount[]>([])

  // Form states
  const [newDomain, setNewDomain] = useState("")
  const [newEmail, setNewEmail] = useState({ email: "", password: "", quota: "1000" })
  const [newDatabase, setNewDatabase] = useState({ name: "", username: "", password: "" })

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

  const handleCreateDomain = async () => {
    if (!newDomain) {
      toast({
        title: "Error",
        description: "Please enter a domain name",
        variant: "destructive",
      })
      return
    }

    try {
      const response = await fetch("/api/domain/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ domain: newDomain }),
      })

      if (response.ok) {
        const result = await response.json()
        toast({
          title: "Success",
          description: `Domain ${newDomain} created successfully`,
        })
        setDomains([
          ...domains,
          {
            id: Date.now(),
            name: newDomain,
            status: "Active",
            created: new Date().toLocaleDateString(),
          },
        ])
        setNewDomain("")
      } else {
        const error = await response.json()
        toast({
          title: "Error",
          description: error.error || "Failed to create domain",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Network error occurred",
        variant: "destructive",
      })
    }
  }

  const handleCreateEmail = async () => {
    if (!newEmail.email || !newEmail.password) {
      toast({
        title: "Error",
        description: "Please fill in all fields",
        variant: "destructive",
      })
      return
    }

    try {
      const response = await fetch("/api/email/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newEmail),
      })

      if (response.ok) {
        toast({
          title: "Success",
          description: `Email account ${newEmail.email} created successfully`,
        })
        setEmails([
          ...emails,
          {
            id: Date.now(),
            email: newEmail.email,
            quota: Number.parseInt(newEmail.quota),
            used: 0,
            created: new Date().toLocaleDateString(),
          },
        ])
        setNewEmail({ email: "", password: "", quota: "1000" })
      } else {
        const error = await response.json()
        toast({
          title: "Error",
          description: error.error || "Failed to create email account",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Network error occurred",
        variant: "destructive",
      })
    }
  }

  const handleCreateDatabase = async () => {
    if (!newDatabase.name || !newDatabase.username || !newDatabase.password) {
      toast({
        title: "Error",
        description: "Please fill in all fields",
        variant: "destructive",
      })
      return
    }

    try {
      const response = await fetch("/api/database/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          dbName: newDatabase.name,
          username: newDatabase.username,
          password: newDatabase.password,
        }),
      })

      if (response.ok) {
        toast({
          title: "Success",
          description: `Database ${newDatabase.name} created successfully`,
        })
        setDatabases([
          ...databases,
          {
            id: Date.now(),
            name: newDatabase.name,
            user: newDatabase.username,
            size: "0 MB",
            created: new Date().toLocaleDateString(),
          },
        ])
        setNewDatabase({ name: "", username: "", password: "" })
      } else {
        const error = await response.json()
        toast({
          title: "Error",
          description: error.error || "Failed to create database",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Network error occurred",
        variant: "destructive",
      })
    }
  }

  const handleBackup = async () => {
    try {
      const response = await fetch("/api/backup/create", {
        method: "POST",
      })

      if (response.ok) {
        toast({
          title: "Success",
          description: "Backup created successfully",
        })
      } else {
        toast({
          title: "Error",
          description: "Failed to create backup",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Network error occurred",
        variant: "destructive",
      })
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
            <TabsTrigger value="domains">Domains</TabsTrigger>
            <TabsTrigger value="email">Email</TabsTrigger>
            <TabsTrigger value="databases">Databases</TabsTrigger>
            <TabsTrigger value="files">Files</TabsTrigger>
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
                    <Button variant="outline" className="h-20 flex flex-col" onClick={handleBackup}>
                      <Download className="h-6 w-6 mb-2" />
                      Create Backup
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Server className="h-6 w-6 mb-2" />
                      Restart Services
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <Shield className="h-6 w-6 mb-2" />
                      Security Scan
                    </Button>
                    <Button variant="outline" className="h-20 flex flex-col">
                      <FileText className="h-6 w-6 mb-2" />
                      View Logs
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="domains">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center">
                      <Globe className="h-5 w-5 mr-2" />
                      Domain Management
                    </CardTitle>
                    <CardDescription>Manage your domains and subdomains</CardDescription>
                  </div>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button>
                        <Plus className="h-4 w-4 mr-2" />
                        Add Domain
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Add New Domain</DialogTitle>
                        <DialogDescription>Enter the domain name you want to add to your server.</DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div>
                          <Label htmlFor="domain">Domain Name</Label>
                          <Input
                            id="domain"
                            placeholder="example.com"
                            value={newDomain}
                            onChange={(e) => setNewDomain(e.target.value)}
                          />
                        </div>
                        <Button onClick={handleCreateDomain} className="w-full">
                          Create Domain
                        </Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                {domains.length === 0 ? (
                  <div className="text-center py-8 text-gray-500">
                    No domains configured. Add your first domain to get started.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {domains.map((domain) => (
                      <div key={domain.id} className="flex items-center justify-between p-4 border rounded-lg">
                        <div>
                          <h3 className="font-medium">{domain.name}</h3>
                          <p className="text-sm text-gray-500">Created: {domain.created}</p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Badge variant="outline" className="text-green-600">
                            {domain.status}
                          </Badge>
                          <Button variant="outline" size="sm">
                            <Settings className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="email">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center">
                      <Mail className="h-5 w-5 mr-2" />
                      Email Management
                    </CardTitle>
                    <CardDescription>Configure email accounts and settings</CardDescription>
                  </div>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button>
                        <Plus className="h-4 w-4 mr-2" />
                        Add Email
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Create Email Account</DialogTitle>
                        <DialogDescription>Create a new email account for your domain.</DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div>
                          <Label htmlFor="email">Email Address</Label>
                          <Input
                            id="email"
                            placeholder="user@example.com"
                            value={newEmail.email}
                            onChange={(e) => setNewEmail({ ...newEmail, email: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor="password">Password</Label>
                          <Input
                            id="password"
                            type="password"
                            value={newEmail.password}
                            onChange={(e) => setNewEmail({ ...newEmail, password: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor="quota">Quota (MB)</Label>
                          <Input
                            id="quota"
                            type="number"
                            value={newEmail.quota}
                            onChange={(e) => setNewEmail({ ...newEmail, quota: e.target.value })}
                          />
                        </div>
                        <Button onClick={handleCreateEmail} className="w-full">
                          Create Email Account
                        </Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                {emails.length === 0 ? (
                  <div className="text-center py-8 text-gray-500">
                    No email accounts configured. Create your first email account.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {emails.map((email) => (
                      <div key={email.id} className="flex items-center justify-between p-4 border rounded-lg">
                        <div>
                          <h3 className="font-medium">{email.email}</h3>
                          <p className="text-sm text-gray-500">
                            {email.used}MB / {email.quota}MB used • Created: {email.created}
                          </p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Progress value={(email.used / email.quota) * 100} className="w-20" />
                          <Button variant="outline" size="sm">
                            <Settings className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="databases">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center">
                      <Database className="h-5 w-5 mr-2" />
                      Database Management
                    </CardTitle>
                    <CardDescription>Manage MySQL and PostgreSQL databases</CardDescription>
                  </div>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button>
                        <Plus className="h-4 w-4 mr-2" />
                        Add Database
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Create Database</DialogTitle>
                        <DialogDescription>Create a new MySQL database with a user account.</DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div>
                          <Label htmlFor="dbname">Database Name</Label>
                          <Input
                            id="dbname"
                            placeholder="my_database"
                            value={newDatabase.name}
                            onChange={(e) => setNewDatabase({ ...newDatabase, name: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor="dbuser">Username</Label>
                          <Input
                            id="dbuser"
                            placeholder="db_user"
                            value={newDatabase.username}
                            onChange={(e) => setNewDatabase({ ...newDatabase, username: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor="dbpass">Password</Label>
                          <Input
                            id="dbpass"
                            type="password"
                            value={newDatabase.password}
                            onChange={(e) => setNewDatabase({ ...newDatabase, password: e.target.value })}
                          />
                        </div>
                        <Button onClick={handleCreateDatabase} className="w-full">
                          Create Database
                        </Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                {databases.length === 0 ? (
                  <div className="text-center py-8 text-gray-500">
                    No databases configured. Create your first database.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {databases.map((db) => (
                      <div key={db.id} className="flex items-center justify-between p-4 border rounded-lg">
                        <div>
                          <h3 className="font-medium">{db.name}</h3>
                          <p className="text-sm text-gray-500">
                            User: {db.user} • Size: {db.size} • Created: {db.created}
                          </p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Button variant="outline" size="sm">
                            <Settings className="h-4 w-4" />
                          </Button>
                          <Button variant="outline" size="sm">
                            phpMyAdmin
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
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
                    <Upload className="h-8 w-8 mb-2" />
                    Upload Files
                  </Button>
                  <Button variant="outline" className="h-24 flex flex-col">
                    <Download className="h-8 w-8 mb-2" />
                    Download Backup
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
