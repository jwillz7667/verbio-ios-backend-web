// Apple Sign In verification

import * as jose from 'jose'
import { AppleIDTokenClaims } from '@/types/auth'
import { UnauthorizedError } from '@/lib/errors/AppError'

// Apple's public key endpoint
const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys'

// Cache for Apple's public keys
let applePublicKeys: jose.JWK[] | null = null
let keysLastFetched: number = 0
const KEYS_CACHE_DURATION = 60 * 60 * 1000 // 1 hour

// Fetch Apple's public keys
async function fetchApplePublicKeys(): Promise<jose.JWK[]> {
  const now = Date.now()

  // Return cached keys if still valid
  if (applePublicKeys && now - keysLastFetched < KEYS_CACHE_DURATION) {
    return applePublicKeys
  }

  const response = await fetch(APPLE_KEYS_URL)
  if (!response.ok) {
    throw new Error('Failed to fetch Apple public keys')
  }

  const data = await response.json() as { keys: jose.JWK[] }
  applePublicKeys = data.keys
  keysLastFetched = now

  return applePublicKeys
}

// Get the correct public key by kid
async function getApplePublicKey(kid: string): Promise<jose.KeyLike> {
  const keys = await fetchApplePublicKeys()
  const key = keys.find(k => k.kid === kid)

  if (!key) {
    throw new UnauthorizedError('Invalid Apple identity token: key not found')
  }

  // importJWK returns KeyLike | Uint8Array, but RS256 always returns KeyLike
  const publicKey = await jose.importJWK(key, 'RS256')
  return publicKey as jose.KeyLike
}

// Verify Apple identity token
export async function verifyAppleIdentityToken(identityToken: string): Promise<AppleIDTokenClaims> {
  try {
    // Decode the header to get the key ID
    const header = jose.decodeProtectedHeader(identityToken)

    if (!header.kid) {
      throw new UnauthorizedError('Invalid Apple identity token: missing kid')
    }

    // Get the public key
    const publicKey = await getApplePublicKey(header.kid)

    // Verify the token
    // Accept both the iOS bundle ID and the Services ID (for web) as valid audiences
    const validAudiences = [
      process.env.APPLE_BUNDLE_ID || '',
      process.env.APPLE_SERVICE_ID || '',
    ].filter(Boolean)

    const { payload } = await jose.jwtVerify(identityToken, publicKey, {
      issuer: 'https://appleid.apple.com',
      audience: validAudiences,
    })

    // Validate required claims
    if (!payload.sub) {
      throw new UnauthorizedError('Invalid Apple identity token: missing subject')
    }

    // Check token expiry
    const now = Math.floor(Date.now() / 1000)
    if (payload.exp && payload.exp < now) {
      throw new UnauthorizedError('Apple identity token has expired')
    }

    return payload as unknown as AppleIDTokenClaims
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      throw error
    }

    console.error('Apple token verification failed:', error)
    throw new UnauthorizedError('Invalid Apple identity token')
  }
}

// Exchange authorization code for tokens (optional - for refresh tokens from Apple)
export async function exchangeAppleAuthCode(authorizationCode: string): Promise<{
  accessToken: string
  refreshToken?: string
  idToken: string
}> {
  const clientSecret = await generateAppleClientSecret()

  const params = new URLSearchParams({
    client_id: process.env.APPLE_SERVICE_ID || '',
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: 'authorization_code',
  })

  const response = await fetch('https://appleid.apple.com/auth/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  })

  if (!response.ok) {
    const error = await response.text()
    console.error('Apple token exchange failed:', error)
    throw new UnauthorizedError('Failed to exchange Apple authorization code')
  }

  const data = await response.json() as {
    access_token: string
    refresh_token?: string
    id_token: string
  }

  return {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    idToken: data.id_token,
  }
}

// Generate Apple client secret (JWT)
async function generateAppleClientSecret(): Promise<string> {
  const teamId = process.env.APPLE_TEAM_ID
  const keyId = process.env.APPLE_KEY_ID
  const serviceId = process.env.APPLE_SERVICE_ID
  const privateKeyPem = process.env.APPLE_PRIVATE_KEY

  if (!teamId || !keyId || !serviceId || !privateKeyPem) {
    throw new Error('Missing Apple Sign In configuration')
  }

  const privateKey = await jose.importPKCS8(privateKeyPem, 'ES256')

  return new jose.SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: keyId })
    .setIssuer(teamId)
    .setAudience('https://appleid.apple.com')
    .setSubject(serviceId)
    .setIssuedAt()
    .setExpirationTime('5m')
    .sign(privateKey)
}
