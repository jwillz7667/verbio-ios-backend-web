// GPT-4o Translation Service

import OpenAI from 'openai'
import { Language } from '@prisma/client'
import { GPTTranslationResult, ConversationContext, LANGUAGE_NAMES } from '@/types/translation'
import { InternalServerError } from '@/lib/errors/AppError'

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// Translation model
const MODEL = 'gpt-4o'

// Temperature for consistent translations
const TEMPERATURE = 0.3

// Maximum context messages to include
const MAX_CONTEXT_MESSAGES = 5

/**
 * Translate text using GPT-4o with optional conversation context
 * @param text Source text to translate
 * @param sourceLanguage Source language
 * @param targetLanguage Target language
 * @param context Optional conversation context for better translations
 * @returns Translated text with language metadata
 */
export async function translateText(
  text: string,
  sourceLanguage: Language,
  targetLanguage: Language,
  context?: ConversationContext
): Promise<GPTTranslationResult> {
  try {
    const systemPrompt = buildSystemPrompt(sourceLanguage, targetLanguage)
    const messages = buildMessages(text, sourceLanguage, targetLanguage, context)

    const response = await openai.chat.completions.create({
      model: MODEL,
      temperature: TEMPERATURE,
      max_tokens: 2048,
      messages: [
        { role: 'system', content: systemPrompt },
        ...messages,
      ],
    })

    const translatedText = response.choices[0]?.message?.content?.trim()

    if (!translatedText) {
      throw new InternalServerError('Translation returned empty result')
    }

    return {
      translatedText,
      sourceLanguage,
      targetLanguage,
    }
  } catch (error) {
    console.error('GPT-4o translation failed:', error)

    if (error instanceof OpenAI.APIError) {
      if (error.status === 429) {
        throw new InternalServerError('Translation service temporarily unavailable')
      }
    }

    if (error instanceof InternalServerError) {
      throw error
    }

    throw new InternalServerError('Failed to translate text')
  }
}

/**
 * Build the system prompt for translation
 */
function buildSystemPrompt(sourceLanguage: Language, targetLanguage: Language): string {
  const sourceName = LANGUAGE_NAMES[sourceLanguage]
  const targetName = LANGUAGE_NAMES[targetLanguage]

  return `You are a professional translator specializing in ${sourceName} to ${targetName} translation.

Your role:
- Translate the user's message accurately from ${sourceName} to ${targetName}
- Preserve the original meaning, tone, and intent
- Use natural, conversational language appropriate for spoken dialogue
- Maintain cultural nuances and idiomatic expressions
- Keep proper nouns, names, and technical terms as appropriate

Guidelines:
- Output ONLY the translated text, nothing else
- Do not add explanations, notes, or alternative translations
- Do not include quotation marks around the translation
- Preserve the formality level of the original text
- If the text contains multiple sentences, translate them all

If context from previous messages is provided, use it to improve translation accuracy and maintain consistency.`
}

/**
 * Build message array for GPT-4o including context
 */
function buildMessages(
  text: string,
  sourceLanguage: Language,
  targetLanguage: Language,
  context?: ConversationContext
): Array<OpenAI.Chat.Completions.ChatCompletionMessageParam> {
  const messages: Array<OpenAI.Chat.Completions.ChatCompletionMessageParam> = []

  // Add context messages if available
  if (context?.messages && context.messages.length > 0) {
    const recentContext = context.messages.slice(-MAX_CONTEXT_MESSAGES)

    // Add context as a single assistant message
    const contextSummary = recentContext
      .map(msg => {
        const speakerLabel = msg.speaker === 'USER' ? 'Speaker A' : 'Speaker B'
        return `${speakerLabel}: "${msg.originalText}" → "${msg.translatedText}"`
      })
      .join('\n')

    messages.push({
      role: 'assistant',
      content: `Previous conversation context:\n${contextSummary}\n\nI'll maintain consistency with this context for the next translation.`,
    })
  }

  // Add the text to translate
  messages.push({
    role: 'user',
    content: text,
  })

  return messages
}

/**
 * Detect the language of text using GPT-4o
 * Used when source language is not specified
 */
export async function detectLanguage(text: string): Promise<Language> {
  try {
    const response = await openai.chat.completions.create({
      model: MODEL,
      temperature: 0,
      max_tokens: 10,
      messages: [
        {
          role: 'system',
          content: `You are a language detection system. Identify the language of the user's text and respond with ONLY the ISO 639-1 two-letter code in uppercase. Valid codes: EN, ES, FR, DE, IT, PT, ZH, JA, KO, AR, HI, RU. If uncertain, respond with EN.`,
        },
        {
          role: 'user',
          content: text,
        },
      ],
    })

    const detected = response.choices[0]?.message?.content?.trim().toUpperCase()

    // Validate it's a valid Language enum value
    const validLanguages: Language[] = ['EN', 'ES', 'FR', 'DE', 'IT', 'PT', 'ZH', 'JA', 'KO', 'AR', 'HI', 'RU']

    if (detected && validLanguages.includes(detected as Language)) {
      return detected as Language
    }

    return 'EN' // Default to English
  } catch (error) {
    console.error('Language detection failed:', error)
    return 'EN' // Default to English on error
  }
}
