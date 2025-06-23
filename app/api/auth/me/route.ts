import { type NextRequest, NextResponse } from "next/server"

export async function GET(request: NextRequest) {
  try {
    const token = request.cookies.get("auth-token")?.value

    if (!token) {
      return NextResponse.json({ error: "Not authenticated" }, { status: 401 })
    }

    try {
      // Decode the simple token
      const userData = JSON.parse(Buffer.from(token, "base64").toString())

      // Check if token is expired
      if (userData.exp < Date.now()) {
        return NextResponse.json({ error: "Token expired" }, { status: 401 })
      }

      return NextResponse.json({
        user: {
          id: userData.userId,
          username: userData.username,
          role: userData.role,
        },
      })
    } catch (decodeError) {
      return NextResponse.json({ error: "Invalid token" }, { status: 401 })
    }
  } catch (error) {
    console.error("Auth check error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
