// GET /api/conversations/[id]/messages - Get messages for a conversation

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { NotFoundError, ForbiddenError } from '@/lib/errors/AppError'
import prisma from '@/lib/db/prisma'
import { Message } from '@prisma/client'

type Params = { params: Promise<{ id: string }> }

// Get messages for a conversation
export async function GET(
  request: NextRequest,
  context: Params
): Promise<NextResponse<{
  messages: Message[]
  total: number
} | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)
    const { id } = await context.params

    // Get query params for pagination
    const { searchParams } = new URL(request.url)
    const limit = parseInt(searchParams.get('limit') || '50', 10)
    const offset = parseInt(searchParams.get('offset') || '0', 10)

    // Verify conversation ownership
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

    // Get messages with pagination
    const [messages, total] = await Promise.all([
      prisma.message.findMany({
        where: { conversationId: id },
        orderBy: { createdAt: 'asc' },
        take: Math.min(limit, 100),
        skip: offset,
      }),
      prisma.message.count({
        where: { conversationId: id },
      }),
    ])

    return NextResponse.json({ messages, total }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
