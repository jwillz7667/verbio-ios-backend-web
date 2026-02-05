// ElevenLabs v3 Text-to-Speech Service

import { Language } from '@prisma/client'
import { TTSResult, DEFAULT_VOICES } from '@/types/translation'
import { BadRequestError, InternalServerError } from '@/lib/errors/AppError'

// ElevenLabs API configuration
const ELEVENLABS_API_URL = 'https://api.elevenlabs.io/v1'
const MODEL_ID = 'eleven_v3' // Most capable model with 70+ languages
const OUTPUT_FORMAT = 'mp3_44100_128'

// Voice settings for natural speech
const VOICE_SETTINGS = {
  stability: 0.5,
  similarity_boost: 0.75,
  use_speaker_boost: true,
}

// Maximum text length (5000 characters)
const MAX_TEXT_LENGTH = 5000

/**
 * Generate speech from text using ElevenLabs v3
 * @param text Text to synthesize
 * @param targetLanguage Target language for voice selection
 * @param voiceId Optional override voice ID
 * @returns Audio buffer and duration
 */
export async function synthesizeSpeech(
  text: string,
  targetLanguage: Language,
  voiceId?: string
): Promise<TTSResult> {
  // Validate text length
  if (text.length > MAX_TEXT_LENGTH) {
    throw new BadRequestError(`Text exceeds maximum length of ${MAX_TEXT_LENGTH} characters`)
  }

  if (text.trim().length === 0) {
    throw new BadRequestError('Text cannot be empty')
  }

  // Select voice based on language or use override
  const selectedVoiceId = voiceId || DEFAULT_VOICES[targetLanguage] || DEFAULT_VOICES['EN']

  try {
    const response = await fetch(
      `${ELEVENLABS_API_URL}/text-to-speech/${selectedVoiceId}?output_format=${OUTPUT_FORMAT}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': process.env.ELEVENLABS_API_KEY || '',
        },
        body: JSON.stringify({
          text,
          model_id: MODEL_ID,
          voice_settings: VOICE_SETTINGS,
        }),
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('ElevenLabs API error:', response.status, errorText)

      if (response.status === 401) {
        throw new InternalServerError('TTS service authentication failed')
      }

      if (response.status === 429) {
        throw new InternalServerError('TTS service rate limit exceeded')
      }

      if (response.status === 400) {
        throw new BadRequestError('Invalid text for speech synthesis')
      }

      throw new InternalServerError('Failed to generate speech')
    }

    // Get audio data as buffer
    const arrayBuffer = await response.arrayBuffer()
    const audioBuffer = Buffer.from(arrayBuffer)

    // Estimate duration based on text length (rough approximation)
    // Average speaking rate: ~150 words per minute, ~5 characters per word
    const estimatedDurationMs = Math.round((text.length / 5 / 150) * 60 * 1000)

    return {
      audioBuffer,
      durationMs: estimatedDurationMs,
    }
  } catch (error) {
    if (error instanceof BadRequestError || error instanceof InternalServerError) {
      throw error
    }

    console.error('ElevenLabs TTS failed:', error)
    throw new InternalServerError('Failed to generate speech')
  }
}

/**
 * Stream speech synthesis (for real-time playback)
 * Returns a ReadableStream for streaming to client
 */
export async function synthesizeSpeechStream(
  text: string,
  targetLanguage: Language,
  voiceId?: string
): Promise<ReadableStream<Uint8Array>> {
  if (text.length > MAX_TEXT_LENGTH) {
    throw new BadRequestError(`Text exceeds maximum length of ${MAX_TEXT_LENGTH} characters`)
  }

  if (text.trim().length === 0) {
    throw new BadRequestError('Text cannot be empty')
  }

  const selectedVoiceId = voiceId || DEFAULT_VOICES[targetLanguage] || DEFAULT_VOICES['EN']

  try {
    const response = await fetch(
      `${ELEVENLABS_API_URL}/text-to-speech/${selectedVoiceId}/stream?output_format=${OUTPUT_FORMAT}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': process.env.ELEVENLABS_API_KEY || '',
        },
        body: JSON.stringify({
          text,
          model_id: MODEL_ID,
          voice_settings: VOICE_SETTINGS,
        }),
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('ElevenLabs streaming error:', response.status, errorText)

      if (response.status === 429) {
        throw new InternalServerError('TTS service rate limit exceeded')
      }

      throw new InternalServerError('Failed to generate speech stream')
    }

    if (!response.body) {
      throw new InternalServerError('No stream body in response')
    }

    return response.body
  } catch (error) {
    if (error instanceof BadRequestError || error instanceof InternalServerError) {
      throw error
    }

    console.error('ElevenLabs streaming failed:', error)
    throw new InternalServerError('Failed to generate speech stream')
  }
}

/**
 * Get available voices from ElevenLabs
 * Useful for settings/preferences UI
 */
export async function getAvailableVoices(): Promise<Array<{
  voiceId: string
  name: string
  previewUrl?: string
  labels?: Record<string, string>
}>> {
  try {
    const response = await fetch(`${ELEVENLABS_API_URL}/voices`, {
      headers: {
        'xi-api-key': process.env.ELEVENLABS_API_KEY || '',
      },
    })

    if (!response.ok) {
      throw new Error('Failed to fetch voices')
    }

    const data = await response.json() as {
      voices: Array<{
        voice_id: string
        name: string
        preview_url?: string
        labels?: Record<string, string>
      }>
    }

    return data.voices.map(voice => ({
      voiceId: voice.voice_id,
      name: voice.name,
      previewUrl: voice.preview_url,
      labels: voice.labels,
    }))
  } catch (error) {
    console.error('Failed to fetch ElevenLabs voices:', error)
    return []
  }
}

/**
 * Get character usage for rate limiting
 */
export async function getCharacterUsage(): Promise<{
  characterCount: number
  characterLimit: number
  canResetAt?: string
}> {
  try {
    const response = await fetch(`${ELEVENLABS_API_URL}/user/subscription`, {
      headers: {
        'xi-api-key': process.env.ELEVENLABS_API_KEY || '',
      },
    })

    if (!response.ok) {
      throw new Error('Failed to fetch subscription info')
    }

    const data = await response.json() as {
      character_count: number
      character_limit: number
      next_character_count_reset_unix?: number
    }

    return {
      characterCount: data.character_count,
      characterLimit: data.character_limit,
      canResetAt: data.next_character_count_reset_unix
        ? new Date(data.next_character_count_reset_unix * 1000).toISOString()
        : undefined,
    }
  } catch (error) {
    console.error('Failed to fetch ElevenLabs usage:', error)
    return { characterCount: 0, characterLimit: 0 }
  }
}
