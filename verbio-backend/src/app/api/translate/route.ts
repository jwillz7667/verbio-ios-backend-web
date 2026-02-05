// POST /api/translate - Main translation endpoint

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { translateRequestSchema, validateBody } from '@/lib/validation/schemas'
import { TranslateResponse, ConversationContext } from '@/types/translation'
import { Language, SubscriptionTier } from '@prisma/client'

// Services
import { transcribeAudio, decodeAudioBase64 } from '@/lib/services/whisper'
import { translateText, detectLanguage } from '@/lib/services/translation'
import { synthesizeSpeech } from '@/lib/services/elevenlabs'
import { uploadAudio } from '@/lib/services/storage'
import {
  checkRateLimit,
  incrementTranslationCount,
  recordUsage,
  calculateEstimatedCost,
} from '@/lib/services/usage'

// Database
import prisma from '@/lib/db/prisma'

export async function POST(
  request: NextRequest
): Promise<NextResponse<TranslateResponse | { error: string; message: string; statusCode: number }>> {
  try {
    // Authenticate user
    const auth = await verifyAuth(request)

    // Validate request body
    const body = await validateBody(request, translateRequestSchema)

    // Check rate limit
    const { remaining, limit } = await checkRateLimit(
      auth.userId,
      auth.tier as SubscriptionTier
    )

    // Decode audio from base64
    const audioBuffer = decodeAudioBase64(body.audio)

    // Step 1: Transcribe audio with Whisper
    const whisperResult = await transcribeAudio(
      audioBuffer,
      body.sourceLanguage as Language | undefined
    )

    // Determine source language (use Whisper detection or auto-detect if needed)
    let sourceLanguage = body.sourceLanguage as Language
    if (!sourceLanguage) {
      // Use Whisper's detection or fall back to GPT detection
      sourceLanguage = whisperResult.language as Language
      if (!sourceLanguage || !isValidLanguage(sourceLanguage)) {
        sourceLanguage = await detectLanguage(whisperResult.text)
      }
    }

    // Get conversation context if conversationId provided
    let conversationContext: ConversationContext | undefined
    if (body.conversationId) {
      const messages = await prisma.message.findMany({
        where: { conversationId: body.conversationId },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          speaker: true,
          originalText: true,
          translatedText: true,
          sourceLanguage: true,
          targetLanguage: true,
        },
      })

      if (messages.length > 0) {
        conversationContext = {
          messages: messages.reverse(),
        }
      }
    }

    // Step 2: Translate text with GPT-4o
    const translationResult = await translateText(
      whisperResult.text,
      sourceLanguage,
      body.targetLanguage as Language,
      conversationContext
    )

    // Step 3: Generate speech with ElevenLabs v3
    const ttsResult = await synthesizeSpeech(
      translationResult.translatedText,
      body.targetLanguage as Language,
      body.voiceId
    )

    // Step 4: Upload audio to R2
    const { url: audioUrl } = await uploadAudio(
      ttsResult.audioBuffer,
      auth.userId,
      'translated'
    )

    // Save message to database if conversation exists
    let messageId: string | undefined
    if (body.conversationId) {
      const message = await prisma.message.create({
        data: {
          conversationId: body.conversationId,
          speaker: body.speaker || 'USER',
          originalText: whisperResult.text,
          translatedText: translationResult.translatedText,
          sourceLanguage: sourceLanguage,
          targetLanguage: body.targetLanguage as Language,
          translatedAudioUrl: audioUrl,
          durationMs: whisperResult.durationMs,
          confidence: whisperResult.confidence,
        },
      })
      messageId = message.id
    }

    // Record usage and increment rate limit counter
    const audioMinutes = whisperResult.durationMs / 60000
    const ttsCharacters = translationResult.translatedText.length
    const estimatedCost = calculateEstimatedCost(audioMinutes, ttsCharacters)

    await Promise.all([
      incrementTranslationCount(auth.userId),
      recordUsage(auth.userId, audioMinutes, ttsCharacters, estimatedCost),
    ])

    // Build response
    const response: TranslateResponse = {
      id: messageId || crypto.randomUUID(),
      originalText: whisperResult.text,
      translatedText: translationResult.translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: body.targetLanguage as Language,
      audioUrl,
      confidence: whisperResult.confidence,
      durationMs: whisperResult.durationMs,
      usage: {
        dailyRemaining: remaining - 1,
        dailyLimit: limit,
        tier: auth.tier as SubscriptionTier,
      },
    }

    return NextResponse.json(response, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}

function isValidLanguage(lang: string): lang is Language {
  const validLanguages = ['EN', 'ES', 'FR', 'DE', 'IT', 'PT', 'ZH', 'JA', 'KO', 'AR', 'HI', 'RU']
  return validLanguages.includes(lang)
}
