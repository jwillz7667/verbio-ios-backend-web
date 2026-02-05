// GET/PUT /api/user/preferences - User voice and translation preferences

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { voicePreferenceSchema, validateBody } from '@/lib/validation/schemas'
import prisma from '@/lib/db/prisma'
import { VoicePreference, Language } from '@prisma/client'
import { DEFAULT_VOICES } from '@/types/translation'

// Default preferences when none exist
const DEFAULT_PREFERENCES = {
  preferredVoiceId: DEFAULT_VOICES['EN'],
  voiceName: 'George',
  speechRate: 1.0,
  defaultSourceLang: 'EN' as Language,
  defaultTargetLang: 'ES' as Language,
  autoDetectSource: true,
}

// Get user preferences
export async function GET(
  request: NextRequest
): Promise<NextResponse<{ preferences: VoicePreference | typeof DEFAULT_PREFERENCES } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const preferences = await prisma.voicePreference.findUnique({
      where: { userId: auth.userId },
    })

    if (!preferences) {
      return NextResponse.json({ preferences: DEFAULT_PREFERENCES }, { status: 200 })
    }

    return NextResponse.json({ preferences }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

// Update user preferences
export async function PUT(
  request: NextRequest
): Promise<NextResponse<{ preferences: VoicePreference } | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    const body = await validateBody(request, voicePreferenceSchema)

    // Upsert preferences
    const preferences = await prisma.voicePreference.upsert({
      where: { userId: auth.userId },
      update: {
        preferredVoiceId: body.preferredVoiceId,
        voiceName: body.voiceName,
        speechRate: body.speechRate,
        defaultSourceLang: body.defaultSourceLang as Language,
        defaultTargetLang: body.defaultTargetLang as Language,
        autoDetectSource: body.autoDetectSource,
      },
      create: {
        userId: auth.userId,
        preferredVoiceId: body.preferredVoiceId || DEFAULT_PREFERENCES.preferredVoiceId,
        voiceName: body.voiceName || DEFAULT_PREFERENCES.voiceName,
        speechRate: body.speechRate ?? DEFAULT_PREFERENCES.speechRate,
        defaultSourceLang: (body.defaultSourceLang as Language) || DEFAULT_PREFERENCES.defaultSourceLang,
        defaultTargetLang: (body.defaultTargetLang as Language) || DEFAULT_PREFERENCES.defaultTargetLang,
        autoDetectSource: body.autoDetectSource ?? DEFAULT_PREFERENCES.autoDetectSource,
      },
    })

    return NextResponse.json({ preferences }, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
