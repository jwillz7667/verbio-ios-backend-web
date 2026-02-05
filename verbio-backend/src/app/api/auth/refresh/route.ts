// Token refresh endpoint

import { NextRequest, NextResponse } from 'next/server'
import prisma from '@/lib/db/prisma'
import {
  verifyRefreshToken,
  generateAccessToken,
  generateRefreshToken,
  hashRefreshToken,
  generateTokenFamily,
  getRefreshTokenExpiry,
  ACCESS_TOKEN_EXPIRY_SECONDS,
} from '@/lib/auth/jwt'
import { handleError } from '@/lib/errors/handler'
import { UnauthorizedError } from '@/lib/errors/AppError'
import { tokenRefreshRequestSchema, validateBody } from '@/lib/validation/schemas'
import { TokenRefreshResponse } from '@/types/auth'

export async function POST(request: NextRequest): Promise<NextResponse<TokenRefreshResponse | { error: string; message: string; statusCode: number }>> {
  try {
    // Validate request body
    const body = await validateBody(request, tokenRefreshRequestSchema)

    // Verify the refresh token JWT
    let tokenJti: string
    try {
      const { jti } = await verifyRefreshToken(body.refreshToken)
      tokenJti = jti
    } catch {
      throw new UnauthorizedError('Invalid refresh token')
    }

    // Find the token in database
    const tokenHash = hashRefreshToken(body.refreshToken)
    const storedToken = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    })

    if (!storedToken) {
      throw new UnauthorizedError('Refresh token not found')
    }

    // Check if token is revoked
    if (storedToken.revokedAt) {
      // Token reuse detected - revoke all tokens in family
      await prisma.refreshToken.updateMany({
        where: { family: storedToken.family },
        data: { revokedAt: new Date() },
      })

      console.warn('Refresh token reuse detected for user:', storedToken.userId)
      throw new UnauthorizedError('Refresh token has been revoked')
    }

    // Check if token is expired
    if (storedToken.expiresAt < new Date()) {
      throw new UnauthorizedError('Refresh token has expired')
    }

    // Revoke the current token (single-use)
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    })

    // Generate new tokens
    const newAccessToken = await generateAccessToken({
      sub: storedToken.user.id,
      email: storedToken.user.email,
      tier: storedToken.user.subscriptionTier,
    })

    const newRefreshToken = await generateRefreshToken()

    // Store new refresh token in same family
    await prisma.refreshToken.create({
      data: {
        tokenHash: hashRefreshToken(newRefreshToken),
        family: storedToken.family,
        userId: storedToken.userId,
        expiresAt: getRefreshTokenExpiry(),
      },
    })

    const response: TokenRefreshResponse = {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: ACCESS_TOKEN_EXPIRY_SECONDS,
    }

    return NextResponse.json(response, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
