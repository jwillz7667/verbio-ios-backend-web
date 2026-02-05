// Health check endpoint

import { NextResponse } from 'next/server'
import prisma from '@/lib/db/prisma'

interface HealthResponse {
  status: 'healthy' | 'degraded' | 'unhealthy'
  timestamp: string
  version: string
  services: {
    database: 'connected' | 'disconnected'
    redis?: 'connected' | 'disconnected'
  }
}

export async function GET(): Promise<NextResponse<HealthResponse>> {
  const timestamp = new Date().toISOString()
  const version = process.env.npm_package_version || '1.0.0'

  // Check database connection
  let databaseStatus: 'connected' | 'disconnected' = 'disconnected'
  try {
    await prisma.$queryRaw`SELECT 1`
    databaseStatus = 'connected'
  } catch (error) {
    console.error('Database health check failed:', error)
  }

  // Determine overall status
  const status = databaseStatus === 'connected' ? 'healthy' : 'unhealthy'

  const response: HealthResponse = {
    status,
    timestamp,
    version,
    services: {
      database: databaseStatus,
    },
  }

  return NextResponse.json(response, {
    status: status === 'healthy' ? 200 : 503,
  })
}
