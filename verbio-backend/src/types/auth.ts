// Authentication types

import { User } from '@prisma/client'

// JWT Payload
export interface JWTPayload {
  sub: string       // User ID
  email: string
  tier: string      // Subscription tier
  iat: number       // Issued at
  exp: number       // Expires at
}

// Sign in with Apple request
export interface AppleAuthRequest {
  identityToken: string
  authorizationCode: string
  firstName?: string | null
  lastName?: string | null
  email?: string | null
}

// Apple ID Token Claims
export interface AppleIDTokenClaims {
  iss: string       // Issuer (https://appleid.apple.com)
  sub: string       // Apple user ID
  aud: string       // Your app's bundle ID
  iat: number       // Issued at
  exp: number       // Expires at
  email?: string
  email_verified?: string | boolean
  is_private_email?: string | boolean
  nonce?: string
  nonce_supported?: boolean
  auth_time?: number
}

// Token refresh request
export interface TokenRefreshRequest {
  refreshToken: string
}

// Auth response (returned to client)
export interface AuthResponse {
  user: SafeUser
  accessToken: string
  refreshToken: string
  expiresIn: number
}

// Token refresh response
export interface TokenRefreshResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

// Safe user (excludes sensitive fields)
export type SafeUser = Omit<User, 'appleUserId'>

// Authenticated request context
export interface AuthContext {
  userId: string
  email: string
  tier: string
}
