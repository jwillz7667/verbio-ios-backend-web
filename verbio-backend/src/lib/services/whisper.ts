// OpenAI Whisper Speech-to-Text Service

import OpenAI from 'openai'
import { toFile } from 'openai/uploads'
import { WhisperResult, WHISPER_LANGUAGE_MAP } from '@/types/translation'
import { Language } from '@prisma/client'
import { BadRequestError, InternalServerError } from '@/lib/errors/AppError'

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// Maximum audio duration (60 seconds)
const MAX_AUDIO_DURATION_MS = 60000

// Supported audio formats
const SUPPORTED_FORMATS = ['audio/wav', 'audio/mpeg', 'audio/mp3', 'audio/webm', 'audio/m4a']

// Verbose JSON response type (extends base Transcription)
interface VerboseTranscription extends OpenAI.Audio.Transcription {
  duration?: number
  language?: string
  segments?: Array<{
    avg_logprob?: number
    [key: string]: unknown
  }>
}

/**
 * Transcribe audio using OpenAI Whisper
 * @param audioBuffer Audio file buffer (WAV, MP3, etc.)
 * @param sourceLanguage Optional language hint for better accuracy
 * @returns Transcription result with text, detected language, and confidence
 */
export async function transcribeAudio(
  audioBuffer: Buffer,
  sourceLanguage?: Language
): Promise<WhisperResult> {
  try {
    // Create a file from the buffer using OpenAI's helper
    const audioFile = await toFile(audioBuffer, 'audio.wav', { type: 'audio/wav' })

    // Build request options
    const options: OpenAI.Audio.Transcriptions.TranscriptionCreateParams = {
      file: audioFile,
      model: 'whisper-1',
      response_format: 'verbose_json',
      timestamp_granularities: ['segment'],
    }

    // Add language hint if provided
    if (sourceLanguage) {
      options.language = WHISPER_LANGUAGE_MAP[sourceLanguage]
    }

    // Call Whisper API
    const response = await openai.audio.transcriptions.create(options) as VerboseTranscription

    // Extract duration from response
    const durationMs = response.duration ? Math.round(response.duration * 1000) : 0

    // Validate duration
    if (durationMs > MAX_AUDIO_DURATION_MS) {
      throw new BadRequestError(`Audio exceeds maximum duration of ${MAX_AUDIO_DURATION_MS / 1000} seconds`)
    }

    // Map detected language to Language enum
    const detectedLanguage = mapWhisperLanguageToEnum(response.language || 'en')

    // Calculate average confidence from segments
    const confidence = calculateConfidence(response)

    return {
      text: response.text.trim(),
      language: detectedLanguage,
      confidence,
      durationMs,
    }
  } catch (error) {
    if (error instanceof BadRequestError) {
      throw error
    }

    console.error('Whisper transcription failed:', error)

    if (error instanceof OpenAI.APIError) {
      if (error.status === 400) {
        throw new BadRequestError('Invalid audio format or corrupted file')
      }
      if (error.status === 429) {
        throw new InternalServerError('Transcription service temporarily unavailable')
      }
    }

    throw new InternalServerError('Failed to transcribe audio')
  }
}

/**
 * Convert base64 audio to buffer with validation
 */
export function decodeAudioBase64(base64Audio: string): Buffer {
  try {
    // Remove data URL prefix if present
    const base64Data = base64Audio.replace(/^data:audio\/\w+;base64,/, '')

    // Decode base64
    const buffer = Buffer.from(base64Data, 'base64')

    // Validate minimum size (1KB)
    if (buffer.length < 1024) {
      throw new BadRequestError('Audio file is too small')
    }

    // Validate maximum size (25MB - Whisper limit)
    if (buffer.length > 25 * 1024 * 1024) {
      throw new BadRequestError('Audio file exceeds maximum size of 25MB')
    }

    return buffer
  } catch (error) {
    if (error instanceof BadRequestError) {
      throw error
    }

    throw new BadRequestError('Invalid base64 audio data')
  }
}

/**
 * Map Whisper detected language to Language enum
 */
function mapWhisperLanguageToEnum(whisperLanguage: string): string {
  const languageMap: Record<string, Language> = {
    english: 'EN',
    spanish: 'ES',
    french: 'FR',
    german: 'DE',
    italian: 'IT',
    portuguese: 'PT',
    chinese: 'ZH',
    japanese: 'JA',
    korean: 'KO',
    arabic: 'AR',
    hindi: 'HI',
    russian: 'RU',
  }

  const normalized = whisperLanguage.toLowerCase()
  return languageMap[normalized] || 'EN'
}

/**
 * Calculate average confidence from Whisper response segments
 */
function calculateConfidence(response: VerboseTranscription): number {
  const segments = response.segments

  if (!segments || segments.length === 0) {
    return 0.9 // Default high confidence if no segments
  }

  // Convert log probabilities to confidence (0-1 range)
  // avg_logprob is typically between -0.5 (high confidence) and -1.5 (low confidence)
  const avgLogProb = segments.reduce((sum, seg) => sum + (seg.avg_logprob || -0.5), 0) / segments.length

  // Map logprob to 0-1 confidence
  // -0.5 -> 1.0, -1.5 -> 0.5, -2.5 -> 0.0
  const confidence = Math.max(0, Math.min(1, 1 + avgLogProb / 2))

  return Math.round(confidence * 100) / 100
}
