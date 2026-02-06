// GET/PATCH/DELETE /api/phrases/[id] - Manage individual saved phrases

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { savedPhraseUpdateSchema, validateBody } from '@/lib/validation/schemas'
import { NotFoundError, ForbiddenError } from '@/lib/errors/AppError'
import prisma from '@/lib/db/prisma'
import { SavedPhrase } from '@prisma/client'

type Params = { params: Promise<{ id: string }> }

// Get a single saved phrase
export async function GET(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{ phrase: SavedPhrase } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    const phrase = await prisma.savedPhrase.findUnique({
      where: { id },
    })

    if (!phrase) {
      throw new NotFoundError('Saved phrase not found')
    }

    if (phrase.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this phrase')
    }

    // Increment usage count
    await prisma.savedPhrase.update({
      where: { id },
      data: {
        usageCount: { increment: 1 },
        lastUsedAt: new Date(),
      },
    })

    return NextResponse.json({ phrase }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Update a saved phrase (toggle favorite, etc.)
export async function PATCH(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{ phrase: SavedPhrase } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    const body = await validateBody(request, savedPhraseUpdateSchema)

    // Verify ownership
    const existing = await prisma.savedPhrase.findUnique({
      where: { id },
      select: { userId: true },
    })

    if (!existing) {
      throw new NotFoundError('Saved phrase not found')
    }

    if (existing.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this phrase')
    }

    // Build update data from provided fields
    const updateData: Record<string, unknown> = {}
    if (body.isFavorite !== undefined) updateData.isFavorite = body.isFavorite
    if (body.translatedText !== undefined) updateData.translatedText = body.translatedText

    const phrase = await prisma.savedPhrase.update({
      where: { id },
      data: updateData,
    })

    return NextResponse.json({ phrase }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Delete a saved phrase
export async function DELETE(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{ success: boolean } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    // Verify ownership
    const existing = await prisma.savedPhrase.findUnique({
      where: { id },
      select: { userId: true },
    })

    if (!existing) {
      throw new NotFoundError('Saved phrase not found')
    }

    if (existing.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this phrase')
    }

    await prisma.savedPhrase.delete({
      where: { id },
    })

    return NextResponse.json({ success: true }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
