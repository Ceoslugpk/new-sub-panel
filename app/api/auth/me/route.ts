import { type NextRequest, NextResponse } from "next/server"
import jwt from "jsonwebtoken"
import mysql from "mysql2/promise"

const dbConfig = {
  host: "localhost",
  user: "panel_user",
  password: process.env.PANEL_DB_PASSWORD,
  database: "hosting_panel",
}

export async function GET(request: NextRequest) {
  try {
    const token = request.cookies.get("auth-token")?.value

    if (!token) {
      return NextResponse.json({ error: "Not authenticated" }, { status: 401 })
    }

    const decoded = jwt.verify(token, process.env.NEXTAUTH_SECRET || "fallback-secret") as any

    const connection = await mysql.createConnection(dbConfig)
    const [rows] = await connection.execute(
      "SELECT id, username, email, role, status, last_login FROM users WHERE id = ?",
      [decoded.userId],
    )
    await connection.end()

    const users = rows as any[]
    if (users.length === 0) {
      return NextResponse.json({ error: "User not found" }, { status: 404 })
    }

    return NextResponse.json({ user: users[0] })
  } catch (error) {
    return NextResponse.json({ error: "Invalid token" }, { status: 401 })
  }
}
