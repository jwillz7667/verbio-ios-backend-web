// Zod validation schemas

import { z } from 'zod'

// Apple Sign In request schema
export const appleAuthRequestSchema = z.object({
  identityToken: z.string().min(1, 'Identity token is required'),
  authorizationCode: z.string().min(1, 'Authorization code is required'),
  firstName: z.string().nullable().optional(),
  lastName: z.string().nullable().optional(),
  email: z.string().email().nullable().optional(),
})

export type AppleAuthRequestInput = z.infer<typeof appleAuthRequestSchema>

// Token refresh request schema
export const tokenRefreshRequestSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
})

export type TokenRefreshRequestInput = z.infer<typeof tokenRefreshRequestSchema>

// User update request schema
export const userUpdateRequestSchema = z.object({
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
})

export type UserUpdateRequestInput = z.infer<typeof userUpdateRequestSchema>

// Preferences update schema
export const preferencesUpdateSchema = z.object({
  preferredSourceLanguage: z.string().length(2).optional(),
  preferredTargetLanguage: z.string().length(2).optional(),
  preferredVoiceId: z.string().optional(),
  autoPlayTranslation: z.boolean().optional(),
  hapticFeedbackEnabled: z.boolean().optional(),
  saveConversationHistory: z.boolean().optional(),
})

export type PreferencesUpdateInput = z.infer<typeof preferencesUpdateSchema>

// Valid language codes
const languageCodes = ['EN', 'ES', 'FR', 'DE', 'IT', 'PT', 'ZH', 'JA', 'KO', 'AR', 'HI', 'RU'] as const

// Translation request schema
export const translateRequestSchema = z.object({
  audio: z.string().min(1, 'Audio data is required'),
  sourceLanguage: z.enum(languageCodes).optional(),
  targetLanguage: z.enum(languageCodes, {
    required_error: 'Target language is required',
    invalid_type_error: 'Invalid target language',
  }),
  conversationId: z.string().uuid().optional(),
  voiceId: z.string().optional(),
  speaker: z.enum(['USER', 'OTHER']).optional().default('USER'),
})

export type TranslateRequestInput = z.infer<typeof translateRequestSchema>

// Conversation create schema
export const conversationCreateSchema = z.object({
  title: z.string().max(200).optional(),
  sourceLanguage: z.enum(languageCodes),
  targetLanguage: z.enum(languageCodes),
})

export type ConversationCreateInput = z.infer<typeof conversationCreateSchema>

// Voice preference update schema
export const voicePreferenceSchema = z.object({
  preferredVoiceId: z.string().min(1).optional(),
  voiceName: z.string().max(100).optional(),
  speechRate: z.number().min(0.5).max(2.0).optional(),
  defaultSourceLang: z.enum(languageCodes).optional(),
  defaultTargetLang: z.enum(languageCodes).optional(),
  autoDetectSource: z.boolean().optional(),
})

export type VoicePreferenceInput = z.infer<typeof voicePreferenceSchema>

// Validate request body helper
export async function validateBody<T>(
  request: Request,
  schema: z.ZodSchema<T>
): Promise<T> {
  const body = await request.json()
  return schema.parse(body)
}
