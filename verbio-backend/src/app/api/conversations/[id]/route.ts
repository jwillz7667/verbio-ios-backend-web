// GET/DELETE /api/conversations/[id] - Get or delete a conversation

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { NotFoundError, ForbiddenError } from '@/lib/errors/AppError'
import prisma from '@/lib/db/prisma'
import { Conversation, Message } from '@prisma/client'

type Params = { params: Promise<{ id: string }> }

// Get a specific conversation with messages
export async function GET(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{
  conversation: Conversation & { messages: Message[] }
} | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found')
    }

    if (conversation.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this conversation')
    }

    return NextResponse.json({ conversation }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Delete a conversation
export async function DELETE(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{ success: boolean } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    // Verify ownership
    const conversation = await prisma.conversation.findUnique({
      where: { id },
      select: { userId: true },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found')
    }

    if (conversation.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this conversation')
    }

    // Delete conversation (cascades to messages)
    await prisma.conversation.delete({
      where: { id },
    })

    return NextResponse.json({ success: true }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Update conversation (archive, rename, etc.)
export async function PATCH(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{ conversation: Conversation } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params
    const body = await request.json()

    // Verify ownership
    const existing = await prisma.conversation.findUnique({
      where: { id },
      select: { userId: true },
    })

    if (!existing) {
      throw new NotFoundError('Conversation not found')
    }

    if (existing.userId !== auth.userId) {
      throw new ForbiddenError('You do not have access to this conversation')
    }

    // Update allowed fields
    const conversation = await prisma.conversation.update({
      where: { id },
      data: {
        title: body.title,
        isActive: body.isActive,
      },
    })

    return NextResponse.json({ conversation }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
