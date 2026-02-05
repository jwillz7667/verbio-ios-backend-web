// GET /api/user/usage - User usage statistics

import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth/middleware'
import { handleError } from '@/lib/errors/handler'
import { getUserUsageStats, checkRateLimit } from '@/lib/services/usage'
import { SubscriptionTier } from '@prisma/client'
import { RATE_LIMITS } from '@/types/translation'

interface UsageResponse {
  current: {
    dailyTranslations: number
    dailyLimit: number
    dailyRemaining: number
    resetAt: Date
  }
  total: {
    translations: number
    audioMinutes: number
    ttsCharacters: number
    estimatedCost: number
  }
  tier: {
    name: SubscriptionTier
    limits: {
      dailyTranslations: number
      audioMinutes: number
      ttsCharacters: number
    }
  }
  history: Array<{
    date: Date
    translations: number
    audioMinutes: number
    ttsCharacters: number
    estimatedCost: number
  }>
}

export async function GET(
  request: NextRequest
): Promise<NextResponse<UsageResponse | { error: string; message: string; statusCode: number }>> {
  try {
    const auth = await verifyAuth(request)

    // Get query params
    const { searchParams } = new URL(request.url)
    const days = parseInt(searchParams.get('days') || '30', 10)

    // Get rate limit info
    const rateLimit = await checkRateLimit(auth.userId, auth.tier as SubscriptionTier)

    // Get usage stats
    const stats = await getUserUsageStats(auth.userId, days)

    const response: UsageResponse = {
      current: {
        dailyTranslations: stats.dailyTranslations,
        dailyLimit: rateLimit.limit,
        dailyRemaining: rateLimit.remaining,
        resetAt: rateLimit.resetAt,
      },
      total: {
        translations: stats.totalTranslations,
        audioMinutes: stats.audioMinutes,
        ttsCharacters: stats.ttsCharacters,
        estimatedCost: stats.estimatedCost,
      },
      tier: {
        name: auth.tier as SubscriptionTier,
        limits: RATE_LIMITS[auth.tier as SubscriptionTier],
      },
      history: stats.history,
    }

    return NextResponse.json(response, { status: 200 })
  } catch (error) {
    return handleError(error)
  }
}
