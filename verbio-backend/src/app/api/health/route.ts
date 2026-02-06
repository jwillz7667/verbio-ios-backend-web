// Health check endpoint

import { NextResponse } from 'next/server'
import prisma from '@/lib/db/prisma'
import { redis } from '@/lib/db/redis'

interface HealthResponse {
  status: 'healthy' | 'degraded' | 'unhealthy'
  timestamp: string
  version: string
  services: {
    database: 'connected' | 'disconnected'
    redis: 'connected' | 'disconnected' | 'not_configured'
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

  // Check Redis connection
  let redisStatus: 'connected' | 'disconnected' | 'not_configured' = 'not_configured'
  if (redis) {
    try {
      await redis.ping()
      redisStatus = 'connected'
    } catch (error) {
      console.error('Redis health check failed:', error)
      redisStatus = 'disconnected'
    }
  }

  // Determine overall status
  let status: HealthResponse['status'] = 'healthy'
  if (databaseStatus === 'disconnected') {
    status = 'unhealthy'
  } else if (redisStatus === 'disconnected') {
    status = 'degraded'
  }

  const response: HealthResponse = {
    status,
    timestamp,
    version,
    services: {
      database: databaseStatus,
      redis: redisStatus,
    },
  }

  return NextResponse.json(response, {
    status: status === 'unhealthy' ? 503 : 200,
  })
}
