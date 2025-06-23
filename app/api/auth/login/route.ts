import { type NextRequest, NextResponse } from "next/server"

// Simple in-memory user store for demo purposes
const users = [
  {
    id: 1,
    username: "admin",
    email: "admin@example.com",
    password: "admin123", // In production, this would be hashed
    role: "admin",
  },
  {
    id: 2,
    username: "user1",
    email: "user1@example.com",
    password: "user123",
    role: "user",
  },
  {
    id: 3,
    username: "reseller1",
    email: "reseller1@example.com",
    password: "reseller123",
    role: "reseller",
  },
]

export async function POST(request: NextRequest) {
  try {
    const { username, password } = await request.json()

    if (!username || !password) {
      return NextResponse.json({ error: "Username and password required" }, { status: 400 })
    }

    // Find user
    const user = users.find((u) => u.username === username && u.password === password)

    if (!user) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 })
    }

    // Create a simple token (in production, use proper JWT)
    const token = Buffer.from(
      JSON.stringify({
        userId: user.id,
        username: user.username,
        role: user.role,
        exp: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
      }),
    ).toString("base64")

    const response = NextResponse.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
      },
    })

    response.cookies.set("auth-token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 86400, // 24 hours
    })

    return response
  } catch (error: any) {
    console.error("Login error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
