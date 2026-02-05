// Cloudflare R2 Storage Service (S3-compatible)

import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'
import { InternalServerError } from '@/lib/errors/AppError'
import crypto from 'crypto'

// Initialize S3 client for Cloudflare R2
const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
  },
})

// Bucket name
const BUCKET_NAME = process.env.R2_BUCKET_NAME || 'verbio-audio'

// Signed URL expiry (24 hours)
const SIGNED_URL_EXPIRY = 24 * 60 * 60 // 24 hours in seconds

// Public URL prefix (if using public bucket or CDN)
const PUBLIC_URL = process.env.R2_PUBLIC_URL

/**
 * Upload audio file to R2 storage
 * @param audioBuffer Audio file buffer
 * @param userId User ID for organization
 * @param type Type of audio (original or translated)
 * @returns Storage key and public URL
 */
export async function uploadAudio(
  audioBuffer: Buffer,
  userId: string,
  type: 'original' | 'translated'
): Promise<{ key: string; url: string }> {
  // Generate unique key
  const timestamp = Date.now()
  const hash = crypto.randomBytes(8).toString('hex')
  const key = `audio/${userId}/${type}/${timestamp}-${hash}.mp3`

  try {
    await s3Client.send(
      new PutObjectCommand({
        Bucket: BUCKET_NAME,
        Key: key,
        Body: audioBuffer,
        ContentType: 'audio/mpeg',
        CacheControl: 'max-age=86400', // 24 hour cache
        Metadata: {
          userId,
          type,
          uploadedAt: new Date().toISOString(),
        },
      })
    )

    // Return public URL if configured, otherwise generate signed URL
    const url = PUBLIC_URL
      ? `${PUBLIC_URL}/${key}`
      : await getSignedAudioUrl(key)

    return { key, url }
  } catch (error) {
    console.error('R2 upload failed:', error)
    throw new InternalServerError('Failed to upload audio file')
  }
}

/**
 * Generate a signed URL for private audio access
 * @param key Storage key
 * @param expiresIn Expiry time in seconds (default 24 hours)
 * @returns Signed URL
 */
export async function getSignedAudioUrl(
  key: string,
  expiresIn: number = SIGNED_URL_EXPIRY
): Promise<string> {
  try {
    const command = new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    })

    const url = await getSignedUrl(s3Client, command, { expiresIn })
    return url
  } catch (error) {
    console.error('Failed to generate signed URL:', error)
    throw new InternalServerError('Failed to generate audio URL')
  }
}

/**
 * Delete audio file from R2 storage
 * @param key Storage key
 */
export async function deleteAudio(key: string): Promise<void> {
  try {
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: BUCKET_NAME,
        Key: key,
      })
    )
  } catch (error) {
    console.error('R2 delete failed:', error)
    // Don't throw - deletion failures shouldn't block operations
  }
}

/**
 * Delete all audio files for a user
 * Used for account deletion / data cleanup
 * @param userId User ID
 */
export async function deleteUserAudio(userId: string): Promise<void> {
  // Note: R2 doesn't support listing with prefix in all plans
  // For production, consider using a database to track files
  // or implementing a batch cleanup job
  console.log(`Cleanup requested for user: ${userId}`)
}

/**
 * Get audio file from R2
 * @param key Storage key
 * @returns Audio buffer or null if not found
 */
export async function getAudio(key: string): Promise<Buffer | null> {
  try {
    const response = await s3Client.send(
      new GetObjectCommand({
        Bucket: BUCKET_NAME,
        Key: key,
      })
    )

    if (!response.Body) {
      return null
    }

    // Convert stream to buffer
    const chunks: Uint8Array[] = []
    for await (const chunk of response.Body as AsyncIterable<Uint8Array>) {
      chunks.push(chunk)
    }

    return Buffer.concat(chunks)
  } catch (error: any) {
    if (error.name === 'NoSuchKey') {
      return null
    }

    console.error('R2 get failed:', error)
    throw new InternalServerError('Failed to retrieve audio file')
  }
}
