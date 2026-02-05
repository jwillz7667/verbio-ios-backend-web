// JWT utilities using ES256

import * as jose from 'jose'
import { JWTPayload } from '@/types/auth'
import { randomBytes, createHash } from 'crypto'

// Token expiry times
const ACCESS_TOKEN_EXPIRY = '15m'    // 15 minutes
const REFRESH_TOKEN_EXPIRY = '30d'   // 30 days
const ACCESS_TOKEN_EXPIRY_SECONDS = 15 * 60
const REFRESH_TOKEN_EXPIRY_SECONDS = 30 * 24 * 60 * 60

// Get private key for signing
async function getPrivateKey(): Promise<jose.KeyLike> {
  const privateKeyPem = process.env.JWT_PRIVATE_KEY
  if (!privateKeyPem) {
    throw new Error('JWT_PRIVATE_KEY environment variable is not set')
  }
  return jose.importPKCS8(privateKeyPem, 'ES256')
}

// Get public key for verification
async function getPublicKey(): Promise<jose.KeyLike> {
  const publicKeyPem = process.env.JWT_PUBLIC_KEY
  if (!publicKeyPem) {
    throw new Error('JWT_PUBLIC_KEY environment variable is not set')
  }
  return jose.importSPKI(publicKeyPem, 'ES256')
}

// Generate access token
export async function generateAccessToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): Promise<string> {
  const privateKey = await getPrivateKey()

  return new jose.SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'ES256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(ACCESS_TOKEN_EXPIRY)
    .setIssuer('verbio-api')
    .setAudience('verbio-ios')
    .sign(privateKey)
}

// Generate refresh token
export async function generateRefreshToken(): Promise<string> {
  const privateKey = await getPrivateKey()
  const tokenId = randomBytes(32).toString('hex')

  return new jose.SignJWT({ jti: tokenId })
    .setProtectedHeader({ alg: 'ES256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(REFRESH_TOKEN_EXPIRY)
    .setIssuer('verbio-api')
    .setAudience('verbio-ios')
    .sign(privateKey)
}

// Verify access token
export async function verifyAccessToken(token: string): Promise<JWTPayload> {
  const publicKey = await getPublicKey()

  const { payload } = await jose.jwtVerify(token, publicKey, {
    issuer: 'verbio-api',
    audience: 'verbio-ios',
  })

  return payload as unknown as JWTPayload
}

// Verify refresh token
export async function verifyRefreshToken(token: string): Promise<{ jti: string }> {
  const publicKey = await getPublicKey()

  const { payload } = await jose.jwtVerify(token, publicKey, {
    issuer: 'verbio-api',
    audience: 'verbio-ios',
  })

  if (!payload.jti) {
    throw new Error('Invalid refresh token: missing jti')
  }

  return { jti: payload.jti as string }
}

// Hash refresh token for storage
export function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex')
}

// Generate token family ID for refresh token rotation
export function generateTokenFamily(): string {
  return randomBytes(16).toString('hex')
}

// Get expiry dates
export function getAccessTokenExpiry(): Date {
  return new Date(Date.now() + ACCESS_TOKEN_EXPIRY_SECONDS * 1000)
}

export function getRefreshTokenExpiry(): Date {
  return new Date(Date.now() + REFRESH_TOKEN_EXPIRY_SECONDS * 1000)
}

// Export constants
export { ACCESS_TOKEN_EXPIRY_SECONDS, REFRESH_TOKEN_EXPIRY_SECONDS }
