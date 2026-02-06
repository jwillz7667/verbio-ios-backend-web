// GET/POST /api/phrases - List and create saved phrases

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { savedPhraseCreateSchema, validateBody } from '@/lib/validation/schemas'
import { ConflictError } from '@/lib/errors/AppError'
import prisma from '@/lib/db/prisma'
import { SavedPhrase, Language } from '@prisma/client'

// List user's saved phrases
export async function GET(
  request: NextRequest
): Promise<NextResponse<{ phrases: SavedPhrase[]; total: number } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const { searchParams } = new URL(request.url)
    const limit = Math.min(parseInt(searchParams.get('limit') || '50', 10), 100)
    const offset = parseInt(searchParams.get('offset') || '0', 10)
    const favoritesOnly = searchParams.get('favorites') === 'true'
    const sourceLang = searchParams.get('sourceLang') as Language | null
    const targetLang = searchParams.get('targetLang') as Language | null
    const search = searchParams.get('search')

    // Build where clause
    const where: Record<string, unknown> = { userId: auth.userId }

    if (favoritesOnly) {
      where.isFavorite = true
    }
    if (sourceLang) {
      where.sourceLanguage = sourceLang
    }
    if (targetLang) {
      where.targetLanguage = targetLang
    }
    if (search) {
      where.OR = [
        { originalText: { contains: search, mode: 'insensitive' } },
        { translatedText: { contains: search, mode: 'insensitive' } },
      ]
    }

    const [phrases, total] = await Promise.all([
      prisma.savedPhrase.findMany({
        where,
        orderBy: [
          { isFavorite: 'desc' },
          { lastUsedAt: { sort: 'desc', nulls: 'last' } },
          { createdAt: 'desc' },
        ],
        take: limit,
        skip: offset,
      }),
      prisma.savedPhrase.count({ where }),
    ])

    return NextResponse.json({ phrases, total }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Create a new saved phrase
export async function POST(
  request: NextRequest
): Promise<NextResponse<{ phrase: SavedPhrase } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const body = await validateBody(request, savedPhraseCreateSchema)

    // Check for duplicate (same text + target language)
    const existing = await prisma.savedPhrase.findUnique({
      where: {
        userId_originalText_targetLanguage: {
          userId: auth.userId,
          originalText: body.originalText,
          targetLanguage: body.targetLanguage as Language,
        },
      },
    })

    if (existing) {
      throw new ConflictError('This phrase is already saved')
    }

    const phrase = await prisma.savedPhrase.create({
      data: {
        userId: auth.userId,
        originalText: body.originalText,
        translatedText: body.translatedText,
        sourceLanguage: body.sourceLanguage as Language,
        targetLanguage: body.targetLanguage as Language,
        isFavorite: body.isFavorite ?? false,
      },
    })

    return NextResponse.json({ phrase }, { status: 201 })
  } catch (error) {
    return handleError(error)
  }
}
