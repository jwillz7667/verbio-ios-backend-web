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

// Validate request body helper
export async function validateBody<T>(
  request: Request,
  schema: z.ZodSchema<T>
): Promise<T> {
  const body = await request.json()
  return schema.parse(body)
}
