"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
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
  Activity,
  Cpu,
  MemoryStick,
  Network,
  AlertTriangle,
  CheckCircle,
  Plus,
  Settings,
  LogOut,
  ExternalLink,
  Package,
  Loader2,
  Eye,
  EyeOff,
} from "lucide-react"

interface User {
  id: number
  username: string
  email: string
  role: string
}

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
  document_root: string
  status: string
  created_at: string
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

interface App {
  id: string
  name: string
  description: string
  icon: string
  category: string
  requirements: string[]
}

export default function Dashboard() {
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
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
  const [apps, setApps] = useState<App[]>([])

  // Form states
  const [newDomain, setNewDomain] = useState({ domain: "", subdomain: "" })
  const [newEmail, setNewEmail] = useState({ email: "", password: "", quota: "1000" })
  const [newDatabase, setNewDatabase] = useState({ name: "", username: "", password: "" })
  const [appInstall, setAppInstall] = useState({ domain: "", app: "", dbName: "", dbUser: "", dbPassword: "" })
  const [showPassword, setShowPassword] = useState(false)
  const [isInstalling, setIsInstalling] = useState(false)

  useEffect(() => {
    fetchUser()
    fetchStats()
    fetchServices()
    fetchDomains()
    fetchApps()

    const interval = setInterval(() => {
      fetchStats()
      fetchServices()
    }, 5000)

    return () => clearInterval(interval)
  }, [])

  const fetchUser = async () => {
    try {
      const response = await fetch("/api/auth/me")
      if (response.ok) {
        const data = await response.json()
        setUser(data.user)
      } else {
        router.push("/login")
      }
    } catch (error) {
      router.push("/login")
    } finally {
      setLoading(false)
    }
  }

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

  const fetchDomains = async () => {
    try {
      const response = await fetch("/api/domain/create")
      if (response.ok) {
        const data = await response.json()
        setDomains(data.domains || [])
      }
    } catch (error) {
      console.error("Failed to fetch domains:", error)
    }
  }

  const fetchApps = async () => {
    try {
      const response = await fetch("/api/apps/install")
      if (response.ok) {
        const data = await response.json()
        setApps(data.apps || [])
      }
    } catch (error) {
      console.error("Failed to fetch apps:", error)
    }
  }

  const handleLogout = async () => {
    try {
      await fetch("/api/auth/logout", { method: "POST" })
      router.push("/login")
    } catch (error) {
      console.error("Logout failed:", error)
    }
  }

  const handleCreateDomain = async () => {
    if (!newDomain.domain) {
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
        body: JSON.stringify(newDomain),
      })

      if (response.ok) {
        const result = await response.json()
        toast({
          title: "Success",
          description: `Domain ${result.domain} created successfully`,
        })
        fetchDomains()
        setNewDomain({ domain: "", subdomain: "" })
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

  const handleInstallApp = async () => {
    if (!appInstall.domain || !appInstall.app) {
      toast({
        title: "Error",
        description: "Please select domain and application",
        variant: "destructive",
      })
      return
    }

    setIsInstalling(true)
    try {
      const response = await fetch("/api/apps/install", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(appInstall),
      })

      if (response.ok) {
        const result = await response.json()
        toast({
          title: "Success",
          description: `${appInstall.app} installed successfully on ${appInstall.domain}`,
        })
        setAppInstall({ domain: "", app: "", dbName: "", dbUser: "", dbPassword: "" })
      } else {
        const error = await response.json()
        toast({
          title: "Error",
          description: error.error || "Failed to install application",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Network error occurred",
        variant: "destructive",
      })
    } finally {
      setIsInstalling(false)
    }
  }

  const generatePassword = () => {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    let password = ""
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return password
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p>Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-cyan-600 rounded-lg flex items-center justify-center">
                <Server className="h-6 w-6 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Control Panel</h1>
                <p className="text-gray-600">Welcome back, {user?.username}</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <Badge variant="outline" className="text-green-600 border-green-600">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Online
              </Badge>
              <Button variant="outline" onClick={handleLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto p-6 space-y-6">
        {/* System Overview Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card className="bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">CPU Usage</CardTitle>
              <Cpu className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.cpu.toFixed(1)}%</div>
              <Progress value={stats.cpu} className="mt-2 bg-blue-400" />
              <p className="text-xs text-blue-100 mt-2">Load: {stats.load}</p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-green-500 to-green-600 text-white">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Memory Usage</CardTitle>
              <MemoryStick className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.memory.toFixed(1)}%</div>
              <Progress value={stats.memory} className="mt-2 bg-green-400" />
              <p className="text-xs text-green-100 mt-2">Available RAM</p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-yellow-500 to-orange-500 text-white">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Disk Usage</CardTitle>
              <HardDrive className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.disk.toFixed(1)}%</div>
              <Progress value={stats.disk} className="mt-2 bg-orange-400" />
              <p className="text-xs text-orange-100 mt-2">Storage space</p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-purple-500 to-purple-600 text-white">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Network</CardTitle>
              <Network className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.network.toFixed(1)} MB/s</div>
              <p className="text-xs text-purple-100 mt-2">Uptime: {stats.uptime}</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-7">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="domains">Domains</TabsTrigger>
            <TabsTrigger value="apps">Apps</TabsTrigger>
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
                      <div
                        key={index}
                        className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50 transition-colors"
                      >
                        <div className="flex items-center space-x-3">
                          {service.status === "running" ? (
                            <CheckCircle className="h-4 w-4 text-green-500" />
                          ) : (
                            <AlertTriangle className="h-4 w-4 text-red-500" />
                          )}
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

              {/* Quick Stats */}
              <Card>
                <CardHeader>
                  <CardTitle>Quick Statistics</CardTitle>
                  <CardDescription>Overview of your hosting environment</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <Globe className="h-8 w-8 text-blue-600" />
                        <div>
                          <p className="font-medium">Domains</p>
                          <p className="text-sm text-gray-500">Active websites</p>
                        </div>
                      </div>
                      <div className="text-2xl font-bold text-blue-600">{domains.length}</div>
                    </div>

                    <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <Mail className="h-8 w-8 text-green-600" />
                        <div>
                          <p className="font-medium">Email Accounts</p>
                          <p className="text-sm text-gray-500">Active mailboxes</p>
                        </div>
                      </div>
                      <div className="text-2xl font-bold text-green-600">{emails.length}</div>
                    </div>

                    <div className="flex items-center justify-between p-3 bg-purple-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <Database className="h-8 w-8 text-purple-600" />
                        <div>
                          <p className="font-medium">Databases</p>
                          <p className="text-sm text-gray-500">MySQL databases</p>
                        </div>
                      </div>
                      <div className="text-2xl font-bold text-purple-600">{databases.length}</div>
                    </div>
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
                      <Button className="bg-gradient-to-r from-blue-600 to-cyan-600">
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
                          <Label htmlFor="subdomain">Subdomain (optional)</Label>
                          <Input
                            id="subdomain"
                            placeholder="www, blog, shop..."
                            value={newDomain.subdomain}
                            onChange={(e) => setNewDomain({ ...newDomain, subdomain: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor="domain">Domain Name</Label>
                          <Input
                            id="domain"
                            placeholder="example.com"
                            value={newDomain.domain}
                            onChange={(e) => setNewDomain({ ...newDomain, domain: e.target.value })}
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
                  <div className="text-center py-12">
                    <Globe className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No domains configured</h3>
                    <p className="text-gray-500 mb-4">Add your first domain to get started with hosting</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {domains.map((domain) => (
                      <div
                        key={domain.id}
                        className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                      >
                        <div className="flex items-center space-x-4">
                          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                            <Globe className="h-5 w-5 text-blue-600" />
                          </div>
                          <div>
                            <h3 className="font-medium">{domain.name}</h3>
                            <p className="text-sm text-gray-500">
                              Created: {new Date(domain.created_at).toLocaleDateString()}
                            </p>
                            <p className="text-xs text-gray-400">{domain.document_root}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Badge variant="outline" className="text-green-600 border-green-600">
                            {domain.status}
                          </Badge>
                          <Button variant="outline" size="sm" asChild>
                            <a href={`http://${domain.name}`} target="_blank" rel="noopener noreferrer">
                              <ExternalLink className="h-4 w-4" />
                            </a>
                          </Button>
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

          <TabsContent value="apps">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center">
                      <Package className="h-5 w-5 mr-2" />
                      Application Installer
                    </CardTitle>
                    <CardDescription>Install popular applications on your domains</CardDescription>
                  </div>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button className="bg-gradient-to-r from-green-600 to-emerald-600">
                        <Plus className="h-4 w-4 mr-2" />
                        Install App
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-md">
                      <DialogHeader>
                        <DialogTitle>Install Application</DialogTitle>
                        <DialogDescription>Choose a domain and application to install</DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div>
                          <Label htmlFor="app-domain">Select Domain</Label>
                          <Select
                            value={appInstall.domain}
                            onValueChange={(value) => setAppInstall({ ...appInstall, domain: value })}
                          >
                            <SelectTrigger>
                              <SelectValue placeholder="Choose domain" />
                            </SelectTrigger>
                            <SelectContent>
                              {domains.map((domain) => (
                                <SelectItem key={domain.id} value={domain.name}>
                                  {domain.name}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>

                        <div>
                          <Label htmlFor="app-type">Select Application</Label>
                          <Select
                            value={appInstall.app}
                            onValueChange={(value) => setAppInstall({ ...appInstall, app: value })}
                          >
                            <SelectTrigger>
                              <SelectValue placeholder="Choose application" />
                            </SelectTrigger>
                            <SelectContent>
                              {apps.map((app) => (
                                <SelectItem key={app.id} value={app.id}>
                                  {app.icon} {app.name}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>

                        {appInstall.app && ["wordpress", "joomla", "drupal", "laravel"].includes(appInstall.app) && (
                          <>
                            <div>
                              <Label htmlFor="db-name">Database Name</Label>
                              <Input
                                id="db-name"
                                placeholder="app_database"
                                value={appInstall.dbName}
                                onChange={(e) => setAppInstall({ ...appInstall, dbName: e.target.value })}
                              />
                            </div>

                            <div>
                              <Label htmlFor="db-user">Database User</Label>
                              <Input
                                id="db-user"
                                placeholder="app_user"
                                value={appInstall.dbUser}
                                onChange={(e) => setAppInstall({ ...appInstall, dbUser: e.target.value })}
                              />
                            </div>

                            <div>
                              <Label htmlFor="db-password">Database Password</Label>
                              <div className="flex space-x-2">
                                <div className="relative flex-1">
                                  <Input
                                    id="db-password"
                                    type={showPassword ? "text" : "password"}
                                    placeholder="Database password"
                                    value={appInstall.dbPassword}
                                    onChange={(e) => setAppInstall({ ...appInstall, dbPassword: e.target.value })}
                                  />
                                  <Button
                                    type="button"
                                    variant="ghost"
                                    size="sm"
                                    className="absolute right-0 top-0 h-full px-3"
                                    onClick={() => setShowPassword(!showPassword)}
                                  >
                                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                  </Button>
                                </div>
                                <Button
                                  type="button"
                                  variant="outline"
                                  onClick={() => setAppInstall({ ...appInstall, dbPassword: generatePassword() })}
                                >
                                  Generate
                                </Button>
                              </div>
                            </div>
                          </>
                        )}

                        <Button onClick={handleInstallApp} className="w-full" disabled={isInstalling}>
                          {isInstalling ? (
                            <>
                              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                              Installing...
                            </>
                          ) : (
                            "Install Application"
                          )}
                        </Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {apps.map((app) => (
                    <Card key={app.id} className="hover:shadow-md transition-shadow cursor-pointer">
                      <CardContent className="p-4">
                        <div className="flex items-start space-x-3">
                          <div className="text-2xl">{app.icon}</div>
                          <div className="flex-1">
                            <h3 className="font-medium">{app.name}</h3>
                            <p className="text-sm text-gray-500 mb-2">{app.description}</p>
                            <div className="flex items-center space-x-2">
                              <Badge variant="secondary" className="text-xs">
                                {app.category}
                              </Badge>
                            </div>
                            <div className="mt-2">
                              <p className="text-xs text-gray-400">Requires: {app.requirements.join(", ")}</p>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Other tabs remain the same but with improved styling */}
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
                <div className="text-center py-12">
                  <Mail className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Email Management</h3>
                  <p className="text-gray-500">Email functionality coming soon</p>
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
                <div className="text-center py-12">
                  <Database className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Database Management</h3>
                  <p className="text-gray-500">Database functionality coming soon</p>
                </div>
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
                <div className="text-center py-12">
                  <HardDrive className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">File Manager</h3>
                  <p className="text-gray-500">File management functionality coming soon</p>
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
                <div className="text-center py-12">
                  <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Security Center</h3>
                  <p className="text-gray-500">Security features coming soon</p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
