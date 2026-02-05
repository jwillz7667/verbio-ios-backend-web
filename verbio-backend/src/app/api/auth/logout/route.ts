// Logout endpoint

import { NextRequest, NextResponse } from 'next/server'
import prisma from '@/lib/db/prisma'
import { verifyAuth } from '@/lib/auth/middleware'
import { hashRefreshToken } from '@/lib/auth/jwt'
import { handleError } from '@/lib/errors/handler'

interface LogoutRequest {
  refreshToken?: string
  allDevices?: boolean
}

interface LogoutResponse {
  success: boolean
  message: string
}

export async function POST(request: NextRequest): Promise<NextResponse<LogoutResponse | { error: string; message: string; statusCode: number }>> {
  try {
    // Verify authentication
    const authContext = await verifyAuth(request)

    // Parse request body (optional)
    let body: LogoutRequest = {}
    try {
      body = await request.json()
    } catch {
      // Body is optional
    }

    if (body.allDevices) {
      // Revoke all refresh tokens for the user
      await prisma.refreshToken.updateMany({
        where: {
          userId: authContext.userId,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
        },
      })

      return NextResponse.json({
        success: true,
        message: 'Logged out from all devices',
      })
    }

    if (body.refreshToken) {
      // Revoke specific refresh token and its family
      const tokenHash = hashRefreshToken(body.refreshToken)
      const storedToken = await prisma.refreshToken.findUnique({
        where: { tokenHash },
      })

      if (storedToken && storedToken.userId === authContext.userId) {
        // Revoke all tokens in the family
        await prisma.refreshToken.updateMany({
          where: { family: storedToken.family },
          data: { revokedAt: new Date() },
        })
      }
    }

    return NextResponse.json({
      success: true,
      message: 'Logged out successfully',
    })
  } catch (error) {
    return handleError(error)
  }
}
