import { type NextRequest, NextResponse } from "next/server"

// Mock domains storage
const domains: any[] = [
  {
    id: 1,
    name: "example.com",
    document_root: "/var/www/example.com",
    status: "active",
    created_at: new Date().toISOString(),
  },
  {
    id: 2,
    name: "demo.local",
    document_root: "/var/www/demo.local",
    status: "active",
    created_at: new Date().toISOString(),
  },
]

export async function GET() {
  try {
    return NextResponse.json({ domains })
  } catch (error) {
    console.error("Error fetching domains:", error)
    return NextResponse.json({ error: "Failed to fetch domains" }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const { domain, subdomain } = await request.json()

    if (!domain) {
      return NextResponse.json({ error: "Domain name is required" }, { status: 400 })
    }

    const fullDomain = subdomain ? `${subdomain}.${domain}` : domain
    const documentRoot = `/var/www/${fullDomain}`

    // Check if domain already exists
    const existingDomain = domains.find((d) => d.name === fullDomain)
    if (existingDomain) {
      return NextResponse.json({ error: "Domain already exists" }, { status: 400 })
    }

    // Create new domain
    const newDomain = {
      id: domains.length + 1,
      name: fullDomain,
      document_root: documentRoot,
      status: "active",
      created_at: new Date().toISOString(),
    }

    domains.push(newDomain)

    return NextResponse.json({
      success: true,
      domain: fullDomain,
      message: `Domain ${fullDomain} created successfully`,
    })
  } catch (error) {
    console.error("Error creating domain:", error)
    return NextResponse.json({ error: "Failed to create domain" }, { status: 500 })
  }
}
