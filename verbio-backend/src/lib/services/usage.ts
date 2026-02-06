// Usage Tracking and Rate Limiting Service

import { SubscriptionTier } from '@prisma/client'
import prisma from '@/lib/db/prisma'
import { redis } from '@/lib/db/redis'
import { RATE_LIMITS } from '@/types/translation'
import { TooManyRequestsError } from '@/lib/errors/AppError'

// Redis key prefixes
const RATE_LIMIT_PREFIX = 'ratelimit:translations:'
const USAGE_PREFIX = 'usage:'

// Rate limit window (24 hours in seconds)
const RATE_LIMIT_WINDOW = 24 * 60 * 60

/**
 * Check if user can perform a translation based on their tier
 * @param userId User ID
 * @param tier Subscription tier
 * @returns Number of remaining translations
 * @throws TooManyRequestsError if limit exceeded
 */
export async function checkRateLimit(
  userId: string,
  tier: SubscriptionTier
): Promise<{ remaining: number; limit: number; resetAt: Date }> {
  const limit = RATE_LIMITS[tier].dailyTranslations

  // Enterprise has no limit
  if (tier === 'ENTERPRISE') {
    return {
      remaining: Infinity,
      limit: Infinity,
      resetAt: new Date(Date.now() + RATE_LIMIT_WINDOW * 1000),
    }
  }

  const key = `${RATE_LIMIT_PREFIX}${userId}`

  // Auto-reset daily count if 24h have passed (DB fallback or primary)
  await autoResetDailyCount(userId)

  // If Redis is not available, fall back to database-based rate limiting
  if (!redis) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { dailyTranslations: true, lastUsageReset: true },
    })

    const count = user?.dailyTranslations || 0
    const remaining = Math.max(0, limit - count)
    const lastReset = user?.lastUsageReset || new Date()
    const resetAt = new Date(lastReset.getTime() + RATE_LIMIT_WINDOW * 1000)

    if (count >= limit) {
      const retryAfter = Math.max(1, Math.ceil((resetAt.getTime() - Date.now()) / 1000))
      throw new TooManyRequestsError(
        `Daily translation limit (${limit}) exceeded.`,
        retryAfter
      )
    }

    return { remaining, limit, resetAt }
  }

  // Get current count from Redis
  const countStr = await redis.get(key)
  const count = countStr ? parseInt(countStr, 10) : 0

  // Get TTL for reset time
  const ttl = await redis.ttl(key)
  const resetAt = new Date(Date.now() + (ttl > 0 ? ttl : RATE_LIMIT_WINDOW) * 1000)

  const remaining = Math.max(0, limit - count)

  if (count >= limit) {
    const retryAfter = ttl > 0 ? ttl : RATE_LIMIT_WINDOW
    throw new TooManyRequestsError(
      `Daily translation limit (${limit}) exceeded. Resets in ${Math.ceil(retryAfter / 3600)} hours.`,
      retryAfter
    )
  }

  return { remaining, limit, resetAt }
}

/**
 * Increment translation count after successful translation
 * @param userId User ID
 */
export async function incrementTranslationCount(userId: string): Promise<void> {
  // If Redis is not available, skip (database update happens in recordUsage)
  if (!redis) {
    return
  }

  const key = `${RATE_LIMIT_PREFIX}${userId}`

  // Increment and set expiry if new key
  const count = await redis.incr(key)

  if (count === 1) {
    // First translation today, set 24-hour expiry
    await redis.expire(key, RATE_LIMIT_WINDOW)
  }
}

/**
 * Record usage metrics for analytics and billing
 * @param userId User ID
 * @param audioMinutes Audio duration in minutes
 * @param ttsCharacters Number of TTS characters
 * @param estimatedCost Estimated cost in USD
 */
export async function recordUsage(
  userId: string,
  audioMinutes: number,
  ttsCharacters: number,
  estimatedCost: number
): Promise<void> {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  try {
    // Upsert daily usage record
    await prisma.usageRecord.upsert({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
      update: {
        translations: { increment: 1 },
        audioMinutes: { increment: audioMinutes },
        ttsCharacters: { increment: ttsCharacters },
        estimatedCost: { increment: estimatedCost },
      },
      create: {
        userId,
        date: today,
        translations: 1,
        audioMinutes,
        ttsCharacters,
        estimatedCost,
      },
    })

    // Update user totals
    await prisma.user.update({
      where: { id: userId },
      data: {
        dailyTranslations: { increment: 1 },
        totalTranslations: { increment: 1 },
      },
    })
  } catch (error) {
    // Log but don't fail the translation
    console.error('Failed to record usage:', error)
  }
}

/**
 * Get usage statistics for a user
 * @param userId User ID
 * @param days Number of days to look back
 */
export async function getUserUsageStats(
  userId: string,
  days: number = 30
): Promise<{
  totalTranslations: number
  dailyTranslations: number
  audioMinutes: number
  ttsCharacters: number
  estimatedCost: number
  history: Array<{
    date: Date
    translations: number
    audioMinutes: number
    ttsCharacters: number
    estimatedCost: number
  }>
}> {
  const startDate = new Date()
  startDate.setDate(startDate.getDate() - days)
  startDate.setHours(0, 0, 0, 0)

  const [user, records] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: {
        totalTranslations: true,
        dailyTranslations: true,
      },
    }),
    prisma.usageRecord.findMany({
      where: {
        userId,
        date: { gte: startDate },
      },
      orderBy: { date: 'desc' },
    }),
  ])

  // Aggregate totals
  const totals = records.reduce(
    (acc, record) => ({
      audioMinutes: acc.audioMinutes + record.audioMinutes,
      ttsCharacters: acc.ttsCharacters + record.ttsCharacters,
      estimatedCost: acc.estimatedCost + record.estimatedCost,
    }),
    { audioMinutes: 0, ttsCharacters: 0, estimatedCost: 0 }
  )

  return {
    totalTranslations: user?.totalTranslations || 0,
    dailyTranslations: user?.dailyTranslations || 0,
    audioMinutes: totals.audioMinutes,
    ttsCharacters: totals.ttsCharacters,
    estimatedCost: totals.estimatedCost,
    history: records.map(r => ({
      date: r.date,
      translations: r.translations,
      audioMinutes: r.audioMinutes,
      ttsCharacters: r.ttsCharacters,
      estimatedCost: r.estimatedCost,
    })),
  }
}

/**
 * Auto-reset daily translation count if 24h have elapsed.
 * Called automatically within checkRateLimit to ensure counts reset.
 */
async function autoResetDailyCount(userId: string): Promise<void> {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { lastUsageReset: true, dailyTranslations: true },
    })

    if (!user) return

    const msSinceReset = Date.now() - user.lastUsageReset.getTime()

    if (msSinceReset >= RATE_LIMIT_WINDOW * 1000) {
      await prisma.user.update({
        where: { id: userId },
        data: {
          dailyTranslations: 0,
          lastUsageReset: new Date(),
        },
      })
    }
  } catch (error) {
    console.error('Failed to auto-reset daily count:', error)
  }
}

/**
 * Reset daily translation count (called by cron or on first daily request)
 * @param userId User ID
 */
export async function resetDailyCount(userId: string): Promise<void> {
  await autoResetDailyCount(userId)
}

/**
 * Calculate estimated cost for a translation
 * @param audioMinutes Audio duration
 * @param ttsCharacters TTS character count
 * @returns Estimated cost in USD
 */
export function calculateEstimatedCost(
  audioMinutes: number,
  ttsCharacters: number
): number {
  // Pricing (approximate):
  // Whisper: $0.006 / minute
  // GPT-4o: ~$0.01 / 1K tokens (assuming ~200 tokens per translation)
  // ElevenLabs: ~$0.30 / 1K characters (varies by plan)
  // R2: negligible

  const whisperCost = audioMinutes * 0.006
  const gptCost = 0.002 // Flat estimate per translation
  const elevenLabsCost = (ttsCharacters / 1000) * 0.30

  return Math.round((whisperCost + gptCost + elevenLabsCost) * 1000) / 1000
}
