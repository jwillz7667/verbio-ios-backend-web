// Translation types

import { Language, Speaker, SubscriptionTier } from '@prisma/client'

// Translation request
export interface TranslateRequest {
  audio: string           // Base64 encoded WAV/MP3
  sourceLanguage?: Language // Auto-detect if omitted
  targetLanguage: Language  // Required
  conversationId?: string   // For context
  voiceId?: string          // Override default voice
  speaker?: Speaker         // USER or OTHER
}

// Translation response
export interface TranslateResponse {
  id: string
  originalText: string
  translatedText: string
  sourceLanguage: Language
  targetLanguage: Language
  audioUrl: string
  confidence: number
  durationMs: number
  usage: {
    dailyRemaining: number
    dailyLimit: number
    tier: SubscriptionTier
  }
}

// Whisper STT result
export interface WhisperResult {
  text: string
  language: string
  confidence: number
  durationMs: number
}

// GPT-4o Translation result
export interface GPTTranslationResult {
  translatedText: string
  sourceLanguage: Language
  targetLanguage: Language
}

// ElevenLabs TTS result
export interface TTSResult {
  audioBuffer: Buffer
  durationMs: number
}

// Rate limits by tier
export const RATE_LIMITS: Record<SubscriptionTier, {
  dailyTranslations: number
  audioMinutes: number
  ttsCharacters: number
}> = {
  FREE: { dailyTranslations: 10, audioMinutes: 5, ttsCharacters: 5000 },
  BASIC: { dailyTranslations: 50, audioMinutes: 30, ttsCharacters: 30000 },
  PRO: { dailyTranslations: 200, audioMinutes: 120, ttsCharacters: 120000 },
  ENTERPRISE: { dailyTranslations: Infinity, audioMinutes: Infinity, ttsCharacters: Infinity },
}

// Default voices by language
export const DEFAULT_VOICES: Record<string, string> = {
  EN: 'JBFqnCBsd6RMkjVDRZzb', // George (British)
  ES: 'EXAVITQu4vr4xnSDxMaL', // Bella
  FR: 'onwK4e9ZLuTAKqWW03F9', // Daniel
  DE: 'g5CIjZEefAph4nQFvHAz', // Freya
  IT: 'ThT5KcBeYPX3keUQqHPh', // Italian
  PT: 'TxGEqnHWrfWFTfGW9XjX', // Portuguese
  ZH: 'XB0fDUnXU5powFXDhCwa', // Chinese
  JA: 'iP95p4xoKVk53GoZ742B', // Japanese
  KO: 'Xb7hH8MSUJpSbSDYk0k2', // Korean
  AR: 'pNInz6obpgDQGcFmaJgB', // Arabic
  HI: 'pNInz6obpgDQGcFmaJgB', // Hindi
  RU: 'GBv7mTt0atIp3Br8iCZE', // Russian
}

// Conversation context for translation
export interface ConversationContext {
  messages: Array<{
    speaker: Speaker
    originalText: string
    translatedText: string
    sourceLanguage: Language
    targetLanguage: Language
  }>
}

// Language mapping for Whisper
export const WHISPER_LANGUAGE_MAP: Record<Language, string> = {
  EN: 'english',
  ES: 'spanish',
  FR: 'french',
  DE: 'german',
  IT: 'italian',
  PT: 'portuguese',
  ZH: 'chinese',
  JA: 'japanese',
  KO: 'korean',
  AR: 'arabic',
  HI: 'hindi',
  RU: 'russian',
}

// Language display names
export const LANGUAGE_NAMES: Record<Language, string> = {
  EN: 'English',
  ES: 'Spanish',
  FR: 'French',
  DE: 'German',
  IT: 'Italian',
  PT: 'Portuguese',
  ZH: 'Chinese',
  JA: 'Japanese',
  KO: 'Korean',
  AR: 'Arabic',
  HI: 'Hindi',
  RU: 'Russian',
}
