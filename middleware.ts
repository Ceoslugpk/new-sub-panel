import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import jwt from "jsonwebtoken"

export function middleware(request: NextRequest) {
  // Skip middleware for login page and API auth routes
  if (request.nextUrl.pathname === "/login" || request.nextUrl.pathname.startsWith("/api/auth/login")) {
    return NextResponse.next()
  }

  // Check for auth token
  const token = request.cookies.get("auth-token")?.value

  if (!token) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  try {
    jwt.verify(token, process.env.NEXTAUTH_SECRET || "fallback-secret")
    return NextResponse.next()
  } catch (error) {
    return NextResponse.redirect(new URL("/login", request.url))
  }
}

export const config = {
  matcher: ["/((?!api/auth/login|login|_next/static|_next/image|favicon.ico).*)"],
}
