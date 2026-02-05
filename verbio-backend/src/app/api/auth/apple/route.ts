// Sign in with Apple endpoint

import { NextRequest, NextResponse } from 'next/server'
import prisma from '@/lib/db/prisma'
import { verifyAppleIdentityToken } from '@/lib/auth/apple'
import {
  generateAccessToken,
  generateRefreshToken,
  hashRefreshToken,
  generateTokenFamily,
  getRefreshTokenExpiry,
  ACCESS_TOKEN_EXPIRY_SECONDS,
} from '@/lib/auth/jwt'
import { handleError } from '@/lib/errors/handler'
import { appleAuthRequestSchema, validateBody } from '@/lib/validation/schemas'
import { AuthResponse, SafeUser } from '@/types/auth'

export async function POST(request: NextRequest): Promise<NextResponse<AuthResponse | { error: string; message: string; statusCode: number }>> {
  try {
    // Validate request body
    const body = await validateBody(request, appleAuthRequestSchema)

    // Verify Apple identity token
    const appleTokenClaims = await verifyAppleIdentityToken(body.identityToken)

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { appleUserId: appleTokenClaims.sub },
    })

    if (!user) {
      // Create new user
      // IMPORTANT: Email and name are only provided on first sign-in
      const email = body.email || appleTokenClaims.email || `${appleTokenClaims.sub}@privaterelay.appleid.com`

      user = await prisma.user.create({
        data: {
          appleUserId: appleTokenClaims.sub,
          email: email,
          firstName: body.firstName || null,
          lastName: body.lastName || null,
          subscriptionTier: 'FREE',
        },
      })

      console.log('Created new user:', user.id)
    } else {
      // Update user if name was provided (only on first sign-in)
      if ((body.firstName || body.lastName) && (!user.firstName || !user.lastName)) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            firstName: body.firstName || user.firstName,
            lastName: body.lastName || user.lastName,
          },
        })
      }
    }

    // Generate tokens
    const accessToken = await generateAccessToken({
      sub: user.id,
      email: user.email,
      tier: user.subscriptionTier,
    })

    const refreshToken = await generateRefreshToken()
    const tokenFamily = generateTokenFamily()

    // Store refresh token hash
    await prisma.refreshToken.create({
      data: {
        tokenHash: hashRefreshToken(refreshToken),
        family: tokenFamily,
        userId: user.id,
        expiresAt: getRefreshTokenExpiry(),
      },
    })

    // Build safe user (exclude sensitive fields)
    const safeUser: SafeUser = {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      subscriptionTier: user.subscriptionTier,
      dailyTranslations: user.dailyTranslations,
      totalTranslations: user.totalTranslations,
      lastUsageReset: user.lastUsageReset,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    }

    const response: AuthResponse = {
      user: safeUser,
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TOKEN_EXPIRY_SECONDS,
    }

    return NextResponse.json(response, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
