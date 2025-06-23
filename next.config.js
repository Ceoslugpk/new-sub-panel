/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  experimental: {
    serverActions: {
      allowedOrigins: ["localhost:3000", "*.localhost:3000"],
    },
  },
  async rewrites() {
    return [
      {
        source: "/phpmyadmin/:path*",
        destination: "http://localhost/phpmyadmin/:path*",
      },
    ]
  },
}

module.exports = nextConfig
