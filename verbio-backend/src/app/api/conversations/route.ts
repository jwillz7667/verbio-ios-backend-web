// GET/POST /api/conversations - List and create conversations

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { conversationCreateSchema, validateBody } from '@/lib/validation/schemas'
import prisma from '@/lib/db/prisma'
import { Conversation } from '@prisma/client'

// List user's conversations
export async function GET(
  request: NextRequest
): Promise<NextResponse<{ conversations: Conversation[] } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    // Get query params
    const { searchParams } = new URL(request.url)
    const limit = parseInt(searchParams.get('limit') || '20', 10)
    const offset = parseInt(searchParams.get('offset') || '0', 10)
    const active = searchParams.get('active')

    // Build where clause
    const where: any = { userId: auth.userId }
    if (active !== null) {
      where.isActive = active === 'true'
    }

    const conversations = await prisma.conversation.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      take: Math.min(limit, 100),
      skip: offset,
      include: {
        _count: {
          select: { messages: true },
        },
      },
    })

    return NextResponse.json({ conversations }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Create a new conversation
export async function POST(
  request: NextRequest
): Promise<NextResponse<{ conversation: Conversation } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const body = await validateBody(request, conversationCreateSchema)

    const conversation = await prisma.conversation.create({
      data: {
        userId: auth.userId,
        title: body.title,
        sourceLanguage: body.sourceLanguage,
        targetLanguage: body.targetLanguage,
        isActive: true,
      },
    })

    return NextResponse.json({ conversation }, { status: 201 })
  } catch (error) {
    return handleError(error)
  }
}
