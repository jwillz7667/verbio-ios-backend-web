// Authentication middleware

import { NextRequest, NextResponse } from 'next/server'
import { verifyAccessToken } from './jwt'
import { UnauthorizedError } from '@/lib/errors/AppError'
import { handleError } from '@/lib/errors/handler'
import { AuthContext } from '@/types/auth'

// Header name for passing auth context
const AUTH_CONTEXT_HEADER = 'x-auth-context'

// Extract bearer token from request
function extractBearerToken(request: NextRequest): string | null {
  const authHeader = request.headers.get('authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null
  }

  return authHeader.slice(7)
}

// Verify authentication and return context
export async function verifyAuth(request: NextRequest): Promise<AuthContext> {
  const token = extractBearerToken(request)

  if (!token) {
    throw new UnauthorizedError('Missing authentication token')
  }

  try {
    const payload = await verifyAccessToken(token)

    return {
      userId: payload.sub,
      email: payload.email,
      tier: payload.tier,
    }
  } catch (error) {
    console.error('Token verification failed:', error)
    throw new UnauthorizedError('Invalid or expired token')
  }
}

// Higher-order function to wrap API handlers with auth
export function withAuth<T>(
  handler: (request: NextRequest, context: AuthContext) => Promise<NextResponse<T>>
) {
  return async (request: NextRequest): Promise<NextResponse<T | { error: string; message: string; statusCode: number }>> => {
    try {
      const authContext = await verifyAuth(request)
      return handler(request, authContext)
    } catch (error) {
      return handleError(error) as NextResponse<{ error: string; message: string; statusCode: number }>
    }
  }
}

// Get auth context from request headers (for use in route handlers)
export function getAuthContext(request: NextRequest): AuthContext | null {
  const contextHeader = request.headers.get(AUTH_CONTEXT_HEADER)

  if (!contextHeader) {
    return null
  }

  try {
    return JSON.parse(contextHeader) as AuthContext
  } catch {
    return null
  }
}

// Check if user has required subscription tier
export function requireTier(
  context: AuthContext,
  requiredTiers: string[]
): void {
  if (!requiredTiers.includes(context.tier)) {
    throw new UnauthorizedError('Subscription tier not sufficient for this action')
  }
}
