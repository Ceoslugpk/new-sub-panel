import { type NextRequest, NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import jwt from "jsonwebtoken"
import mysql from "mysql2/promise"

const dbConfig = {
  host: "localhost",
  user: "panel_user",
  password: process.env.PANEL_DB_PASSWORD,
  database: "hosting_panel",
}

export async function POST(request: NextRequest) {
  try {
    const { username, password } = await request.json()

    if (!username || !password) {
      return NextResponse.json({ error: "Username and password required" }, { status: 400 })
    }

    const connection = await mysql.createConnection(dbConfig)

    const [rows] = await connection.execute('SELECT * FROM users WHERE username = ? AND status = "active"', [username])

    await connection.end()

    const users = rows as any[]
    if (users.length === 0) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 })
    }

    const user = users[0]
    const isValidPassword = await bcrypt.compare(password, user.password_hash)

    if (!isValidPassword) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 })
    }

    // Update last login
    const updateConnection = await mysql.createConnection(dbConfig)
    await updateConnection.execute("UPDATE users SET last_login = NOW() WHERE id = ?", [user.id])
    await updateConnection.end()

    // Create JWT token
    const token = jwt.sign(
      {
        userId: user.id,
        username: user.username,
        role: user.role,
      },
      process.env.NEXTAUTH_SECRET || "fallback-secret",
      { expiresIn: "24h" },
    )

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
