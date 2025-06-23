import { type NextRequest, NextResponse } from "next/server"
import mysql from "mysql2/promise"

export async function POST(request: NextRequest) {
  try {
    const { dbName, username, password } = await request.json()

    if (!dbName || !username || !password) {
      return NextResponse.json({ error: "Database name, username, and password are required" }, { status: 400 })
    }

    // Connect to MySQL as root
    const connection = await mysql.createConnection({
      host: "localhost",
      user: process.env.MYSQL_ROOT_USER || "root",
      password: process.env.MYSQL_ROOT_PASSWORD || "",
      port: 3306,
    })

    // Create database
    await connection.execute(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``)

    // Create user
    await connection.execute(`CREATE USER IF NOT EXISTS ?@'localhost' IDENTIFIED BY ?`, [username, password])

    // Grant privileges
    await connection.execute(`GRANT ALL PRIVILEGES ON \`${dbName}\`.* TO ?@'localhost'`, [username])

    // Flush privileges
    await connection.execute("FLUSH PRIVILEGES")

    await connection.end()

    return NextResponse.json({
      success: true,
      message: `Database ${dbName} created successfully with user ${username}`,
    })
  } catch (error) {
    console.error("Database creation error:", error)
    return NextResponse.json({ error: "Failed to create database" }, { status: 500 })
  }
}
