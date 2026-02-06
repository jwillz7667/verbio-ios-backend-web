// Rate limiting middleware for API routes

import { NextRequest, NextResponse } from 'next/server'

interface RateLimitEntry {
  count: number
  resetAt: number
}

// In-memory store for rate limiting (use Redis in production)
const rateLimitStore = new Map<string, RateLimitEntry>()

// Cleanup expired entries periodically
const CLEANUP_INTERVAL = 60_000 // 1 minute
let lastCleanup = Date.now()

function cleanupExpired() {
  const now = Date.now()
  if (now - lastCleanup < CLEANUP_INTERVAL) return

  for (const [key, entry] of rateLimitStore) {
    if (entry.resetAt < now) {
      rateLimitStore.delete(key)
    }
  }
  lastCleanup = now
}

interface RateLimitConfig {
  windowMs: number     // Time window in milliseconds
  maxRequests: number  // Max requests per window
  keyPrefix?: string   // Prefix for rate limit key
}

const DEFAULT_CONFIG: RateLimitConfig = {
  windowMs: 60_000,    // 1 minute
  maxRequests: 60,     // 60 requests per minute
}

// Extract client identifier from request
function getClientKey(request: NextRequest, prefix: string): string {
  // Use forwarded IP, then direct IP
  const forwarded = request.headers.get('x-forwarded-for')
  const ip = forwarded?.split(',')[0]?.trim() || 'unknown'

  // Also include auth token hash if available for per-user limiting
  const authHeader = request.headers.get('authorization')
  const userKey = authHeader
    ? authHeader.slice(-16) // Last 16 chars of token as identifier
    : ip

  return `${prefix}:${userKey}`
}

export function checkRateLimit(
  request: NextRequest,
  config: Partial<RateLimitConfig> = {}
): { allowed: boolean; remaining: number; resetAt: Date } {
  const { windowMs, maxRequests, keyPrefix } = { ...DEFAULT_CONFIG, ...config }

  cleanupExpired()

  const key = getClientKey(request, keyPrefix || 'api')
  const now = Date.now()

  let entry = rateLimitStore.get(key)

  if (!entry || entry.resetAt < now) {
    entry = { count: 0, resetAt: now + windowMs }
    rateLimitStore.set(key, entry)
  }

  entry.count++

  const remaining = Math.max(0, maxRequests - entry.count)
  const allowed = entry.count <= maxRequests

  return {
    allowed,
    remaining,
    resetAt: new Date(entry.resetAt),
  }
}

export function rateLimitResponse(resetAt: Date): NextResponse {
  const retryAfter = Math.ceil((resetAt.getTime() - Date.now()) / 1000)

  return NextResponse.json(
    {
      error: 'TOO_MANY_REQUESTS',
      message: 'Rate limit exceeded. Please try again later.',
      statusCode: 429,
    },
    {
      status: 429,
      headers: {
        'Retry-After': String(retryAfter),
        'X-RateLimit-Reset': resetAt.toISOString(),
      },
    }
  )
}
