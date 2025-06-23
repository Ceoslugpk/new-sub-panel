import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function middleware(request: NextRequest) {
  // Skip middleware for login page and API auth routes
  if (
    request.nextUrl.pathname === "/login" ||
    request.nextUrl.pathname.startsWith("/api/auth/login") ||
    request.nextUrl.pathname.startsWith("/_next") ||
    request.nextUrl.pathname.startsWith("/favicon")
  ) {
    return NextResponse.next()
  }

  // Check for auth token
  const token = request.cookies.get("auth-token")?.value

  if (!token) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  try {
    // Decode and validate token
    const userData = JSON.parse(Buffer.from(token, "base64").toString())

    // Check if token is expired
    if (userData.exp < Date.now()) {
      const response = NextResponse.redirect(new URL("/login", request.url))
      response.cookies.delete("auth-token")
      return response
    }

    return NextResponse.next()
  } catch (error) {
    // Invalid token, redirect to login
    const response = NextResponse.redirect(new URL("/login", request.url))
    response.cookies.delete("auth-token")
    return response
  }
}

export const config = {
  matcher: ["/((?!api/auth/login|login|_next/static|_next/image|favicon.ico).*)"],
}
