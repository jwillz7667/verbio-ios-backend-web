// GET/PATCH /api/user/profile - User profile management

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { userUpdateRequestSchema, validateBody } from '@/lib/validation/schemas'
import { NotFoundError } from '@/lib/errors/AppError'
import prisma from '@/lib/db/prisma'
import { SafeUser } from '@/types/auth'

// Get user profile
export async function GET(
  request: NextRequest
): Promise<NextResponse<{ user: SafeUser } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const user = await prisma.user.findUnique({
      where: { id: auth.userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        subscriptionTier: true,
        dailyTranslations: true,
        totalTranslations: true,
        lastUsageReset: true,
        createdAt: true,
        updatedAt: true,
      },
    })

    if (!user) {
      throw new NotFoundError('User not found')
    }

    return NextResponse.json({ user }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Update user profile
export async function PATCH(
  request: NextRequest
): Promise<NextResponse<{ user: SafeUser } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const body = await validateBody(request, userUpdateRequestSchema)

    // Only update fields that were provided
    const updateData: Record<string, string> = {}
    if (body.firstName !== undefined) updateData.firstName = body.firstName
    if (body.lastName !== undefined) updateData.lastName = body.lastName

    const user = await prisma.user.update({
      where: { id: auth.userId },
      data: updateData,
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        subscriptionTier: true,
        dailyTranslations: true,
        totalTranslations: true,
        lastUsageReset: true,
        createdAt: true,
        updatedAt: true,
      },
    })

    return NextResponse.json({ user }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
