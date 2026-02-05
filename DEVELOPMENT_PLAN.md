# VoiceTranslate (Verbio) - Comprehensive Development Plan

## Executive Summary

A mobile-first real-time language translation application enabling bidirectional conversations between speakers of different languages. Differentiates through superior TTS quality (ElevenLabs), LLM-powered contextual translation (GPT-4o), and polished conversation UX.

---

## Table of Contents

1. [Technology Stack](#1-technology-stack)
2. [Project Architecture](#2-project-architecture)
3. [File Structure](#3-file-structure)
4. [Security Implementation](#4-security-implementation)
5. [Database Schema](#5-database-schema)
6. [API Design](#6-api-design)
7. [iOS Implementation](#7-ios-implementation)
8. [Backend Implementation](#8-backend-implementation)
9. [Testing Strategy](#9-testing-strategy)
10. [DevOps & CI/CD](#10-devops--cicd)
11. [Phase Implementation](#11-phase-implementation)

---

## 1. Technology Stack

### iOS Client
| Component | Technology | Version |
|-----------|------------|---------|
| UI Framework | SwiftUI | Latest |
| Language | Swift | 5.9+ |
| Min iOS | iOS | 17.0+ |
| Architecture | MVVM + Clean Architecture | - |
| Concurrency | Swift Concurrency (async/await) | - |
| Local Storage | SwiftData | - |
| Audio | AVFoundation, Speech | - |
| Networking | URLSession + Async | - |
| Auth | AuthenticationServices (Sign in with Apple) | - |
| IAP | StoreKit 2 | - |
| Keychain | KeychainAccess | - |

### Backend
| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Next.js (App Router) | 14.x |
| Language | TypeScript | 5.x |
| Runtime | Node.js | 20+ LTS |
| Database | PostgreSQL | 16 |
| Cache/Queue | Redis | 7.x |
| ORM | Prisma | 5.x |
| Auth | jose (JWT) | - |
| Validation | Zod | - |
| Rate Limiting | @upstash/ratelimit | - |
| Hosting | Railway | - |
| Object Storage | Cloudflare R2 | - |

### External Services
| Service | Purpose | Pricing |
|---------|---------|---------|
| OpenAI Whisper | Speech-to-Text | $0.006/min |
| GPT-4o | Contextual Translation | ~$0.01/1K tokens |
| ElevenLabs | Text-to-Speech | $0.30/1K chars |
| DeepL | Fallback Translation | API tier |
| Stripe | Payment Processing | 2.9% + $0.30 |

---

## 2. Project Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS CLIENT                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Views     │  │ ViewModels  │  │  Services   │  │Repositories │        │
│  │  (SwiftUI)  │──│   (MVVM)    │──│  (Domain)   │──│   (Data)    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                                                   │               │
│         └───────────────────┬───────────────────────────────┘               │
│                             │                                               │
│                    ┌────────▼────────┐                                      │
│                    │  NetworkClient  │                                      │
│                    │   (URLSession)  │                                      │
│                    └────────┬────────┘                                      │
└─────────────────────────────┼───────────────────────────────────────────────┘
                              │ HTTPS + JWT
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NEXT.JS BACKEND                                    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         API Routes (App Router)                       │   │
│  │  /api/auth/*  │  /api/translate  │  /api/conversations  │  /api/user │   │
│  └───────────────┴──────────────────┴───────────────────────┴───────────┘   │
│         │                  │                    │                 │          │
│         ▼                  ▼                    ▼                 ▼          │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      Middleware Layer                                │    │
│  │   Auth (JWT)  │  Rate Limit  │  Validation (Zod)  │  Error Handler  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│         │                  │                    │                 │          │
│         ▼                  ▼                    ▼                 ▼          │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                       Service Layer                                  │    │
│  │  AuthService  │ TranslationService │ ConversationService │ UserSvc  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
└──────────────────────────────┼───────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
┌───────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PostgreSQL   │    │     Redis       │    │  Cloudflare R2  │
│  (Primary DB) │    │ (Cache/Queue)   │    │ (Audio Storage) │
└───────────────┘    └─────────────────┘    └─────────────────┘

                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
┌───────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ OpenAI Whisper│    │     GPT-4o      │    │   ElevenLabs    │
│    (STT)      │    │  (Translation)  │    │     (TTS)       │
└───────────────┘    └─────────────────┘    └─────────────────┘
```

### Translation Pipeline Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TRANSLATION PIPELINE                             │
└────────────────────────────────────────────────────────────────────────┘

     iOS App                    Backend                    External APIs
        │                          │                            │
        │  1. Record Audio         │                            │
        │  (AVAudioRecorder)       │                            │
        │                          │                            │
        │  2. POST /api/translate  │                            │
        │  {base64Audio, srcLang,  │                            │
        │   targetLang, context}   │                            │
        │─────────────────────────▶│                            │
        │                          │  3. Whisper STT            │
        │                          │─────────────────────────────▶
        │                          │  {audio} → {text}          │
        │                          │◀─────────────────────────────
        │                          │                            │
        │                          │  4. GPT-4o Translation     │
        │                          │  (with conversation ctx)   │
        │                          │─────────────────────────────▶
        │                          │  {text, ctx} → {translated}│
        │                          │◀─────────────────────────────
        │                          │                            │
        │                          │  5. ElevenLabs TTS         │
        │                          │─────────────────────────────▶
        │                          │  {text} → {audio stream}   │
        │                          │◀─────────────────────────────
        │                          │                            │
        │                          │  6. Store in R2 + DB       │
        │                          │                            │
        │  7. Stream Response      │                            │
        │  {transcription,         │                            │
        │   translation, audioUrl} │                            │
        │◀─────────────────────────│                            │
        │                          │                            │
        │  8. Play Audio           │                            │
        │  (AVAudioPlayer)         │                            │
        │                          │                            │
```

---

## 3. File Structure

### iOS Client Structure

```
Verbio/
├── App/
│   ├── VerbioApp.swift                    # App entry point
│   ├── AppDelegate.swift                  # App lifecycle hooks
│   └── AppConfiguration.swift             # Environment configuration
│
├── Core/
│   ├── DependencyInjection/
│   │   ├── Container.swift                # DI container
│   │   └── Injected.swift                 # Property wrapper
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── Data+Extensions.swift
│   │
│   ├── Utilities/
│   │   ├── Logger.swift                   # Unified logging
│   │   ├── Haptics.swift                  # Haptic feedback manager
│   │   └── Constants.swift                # App-wide constants
│   │
│   └── Errors/
│       ├── AppError.swift                 # Base error types
│       ├── NetworkError.swift
│       └── AudioError.swift
│
├── Data/
│   ├── Network/
│   │   ├── NetworkClient.swift            # URLSession wrapper
│   │   ├── APIEndpoints.swift             # Endpoint definitions
│   │   ├── RequestBuilder.swift           # Request construction
│   │   ├── ResponseHandler.swift          # Response parsing
│   │   └── AuthInterceptor.swift          # JWT injection
│   │
│   ├── Repositories/
│   │   ├── AuthRepository.swift
│   │   ├── TranslationRepository.swift
│   │   ├── ConversationRepository.swift
│   │   ├── UserRepository.swift
│   │   └── PhraseRepository.swift
│   │
│   ├── Local/
│   │   ├── SwiftDataModels/
│   │   │   ├── ConversationModel.swift
│   │   │   ├── MessageModel.swift
│   │   │   └── SavedPhraseModel.swift
│   │   │
│   │   ├── KeychainService.swift          # Secure storage
│   │   └── UserDefaultsService.swift      # Preferences
│   │
│   └── DTOs/
│       ├── AuthDTO.swift
│       ├── TranslationDTO.swift
│       ├── ConversationDTO.swift
│       └── UserDTO.swift
│
├── Domain/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Conversation.swift
│   │   ├── Message.swift
│   │   ├── Translation.swift
│   │   ├── Language.swift
│   │   └── SubscriptionTier.swift
│   │
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── TranslationService.swift
│   │   ├── AudioService.swift
│   │   ├── SpeechRecognitionService.swift
│   │   ├── ConversationService.swift
│   │   └── SubscriptionService.swift
│   │
│   └── UseCases/
│       ├── TranslateAudioUseCase.swift
│       ├── StartConversationUseCase.swift
│       ├── SyncConversationsUseCase.swift
│       └── ManageSubscriptionUseCase.swift
│
├── Presentation/
│   ├── Components/
│   │   ├── Buttons/
│   │   │   ├── PrimaryButton.swift
│   │   │   ├── RecordButton.swift
│   │   │   └── LanguagePickerButton.swift
│   │   │
│   │   ├── Cards/
│   │   │   ├── MessageBubble.swift
│   │   │   ├── ConversationCard.swift
│   │   │   └── PhraseCard.swift
│   │   │
│   │   ├── Indicators/
│   │   │   ├── LoadingIndicator.swift
│   │   │   ├── WaveformView.swift
│   │   │   └── ProgressRing.swift
│   │   │
│   │   └── Shared/
│   │       ├── LanguagePicker.swift
│   │       ├── VoicePicker.swift
│   │       └── UsageIndicator.swift
│   │
│   ├── Screens/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift
│   │   │   ├── OnboardingViewModel.swift
│   │   │   └── OnboardingPages/
│   │   │
│   │   ├── Auth/
│   │   │   ├── SignInView.swift
│   │   │   └── SignInViewModel.swift
│   │   │
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   │
│   │   ├── Translation/
│   │   │   ├── TranslationView.swift
│   │   │   ├── TranslationViewModel.swift
│   │   │   └── Components/
│   │   │       ├── AudioRecorderView.swift
│   │   │       └── TranslationResultView.swift
│   │   │
│   │   ├── Conversation/
│   │   │   ├── ConversationView.swift
│   │   │   ├── ConversationViewModel.swift
│   │   │   ├── ConversationListView.swift
│   │   │   └── ConversationListViewModel.swift
│   │   │
│   │   ├── Phrases/
│   │   │   ├── PhrasesView.swift
│   │   │   └── PhrasesViewModel.swift
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── SettingsViewModel.swift
│   │   │   └── Sections/
│   │   │       ├── AccountSection.swift
│   │   │       ├── VoicePreferencesSection.swift
│   │   │       └── SubscriptionSection.swift
│   │   │
│   │   └── Subscription/
│   │       ├── SubscriptionView.swift
│   │       ├── SubscriptionViewModel.swift
│   │       └── PaywallView.swift
│   │
│   ├── Navigation/
│   │   ├── AppRouter.swift
│   │   ├── NavigationCoordinator.swift
│   │   └── DeepLinkHandler.swift
│   │
│   └── Theme/
│       ├── Colors.swift
│       ├── Typography.swift
│       ├── Spacing.swift
│       └── Animations.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   ├── Localizable.xcstrings
│   ├── Info.plist
│   └── Verbio.entitlements
│
└── Tests/
    ├── UnitTests/
    │   ├── Services/
    │   ├── ViewModels/
    │   └── Repositories/
    │
    └── UITests/
        ├── OnboardingUITests.swift
        ├── TranslationUITests.swift
        └── ConversationUITests.swift
```

### Backend Structure

```
verbio-backend/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   │   ├── apple/
│   │   │   │   │   └── route.ts           # Sign in with Apple
│   │   │   │   ├── refresh/
│   │   │   │   │   └── route.ts           # Token refresh
│   │   │   │   └── logout/
│   │   │   │       └── route.ts           # Logout/revoke
│   │   │   │
│   │   │   ├── translate/
│   │   │   │   └── route.ts               # Main translation endpoint
│   │   │   │
│   │   │   ├── conversations/
│   │   │   │   ├── route.ts               # List/Create conversations
│   │   │   │   └── [id]/
│   │   │   │       ├── route.ts           # Get/Update/Delete conversation
│   │   │   │       └── messages/
│   │   │   │           └── route.ts       # Conversation messages
│   │   │   │
│   │   │   ├── user/
│   │   │   │   ├── route.ts               # User profile
│   │   │   │   ├── preferences/
│   │   │   │   │   └── route.ts           # Voice/language preferences
│   │   │   │   └── usage/
│   │   │   │       └── route.ts           # Usage statistics
│   │   │   │
│   │   │   ├── phrases/
│   │   │   │   ├── route.ts               # List/Create saved phrases
│   │   │   │   └── [id]/
│   │   │   │       └── route.ts           # Get/Delete phrase
│   │   │   │
│   │   │   ├── subscriptions/
│   │   │   │   ├── route.ts               # Subscription status
│   │   │   │   └── verify/
│   │   │   │       └── route.ts           # App Store receipt verify
│   │   │   │
│   │   │   ├── webhooks/
│   │   │   │   ├── stripe/
│   │   │   │   │   └── route.ts           # Stripe webhooks
│   │   │   │   └── appstore/
│   │   │   │       └── route.ts           # App Store Server Notifs
│   │   │   │
│   │   │   └── health/
│   │   │       └── route.ts               # Health check
│   │   │
│   │   ├── layout.tsx
│   │   └── page.tsx                       # Landing page (optional)
│   │
│   ├── lib/
│   │   ├── auth/
│   │   │   ├── jwt.ts                     # JWT utilities
│   │   │   ├── apple.ts                   # Apple auth verification
│   │   │   └── middleware.ts              # Auth middleware
│   │   │
│   │   ├── services/
│   │   │   ├── whisper.ts                 # OpenAI Whisper integration
│   │   │   ├── translation.ts             # GPT-4o translation
│   │   │   ├── elevenlabs.ts              # ElevenLabs TTS
│   │   │   ├── deepl.ts                   # DeepL fallback
│   │   │   └── storage.ts                 # R2 storage operations
│   │   │
│   │   ├── db/
│   │   │   ├── prisma.ts                  # Prisma client singleton
│   │   │   ├── redis.ts                   # Redis client
│   │   │   └── queries/
│   │   │       ├── users.ts
│   │   │       ├── conversations.ts
│   │   │       └── messages.ts
│   │   │
│   │   ├── validation/
│   │   │   ├── schemas.ts                 # Zod schemas
│   │   │   └── middleware.ts              # Validation middleware
│   │   │
│   │   ├── rate-limit/
│   │   │   ├── limiter.ts                 # Rate limiter config
│   │   │   └── tiers.ts                   # Tier-based limits
│   │   │
│   │   ├── errors/
│   │   │   ├── AppError.ts                # Custom error classes
│   │   │   └── handler.ts                 # Error handler
│   │   │
│   │   └── utils/
│   │       ├── logger.ts                  # Structured logging
│   │       ├── crypto.ts                  # Encryption utilities
│   │       └── helpers.ts                 # General helpers
│   │
│   ├── types/
│   │   ├── api.ts                         # API request/response types
│   │   ├── auth.ts                        # Auth types
│   │   ├── translation.ts                 # Translation types
│   │   └── database.ts                    # Prisma type extensions
│   │
│   └── middleware.ts                      # Next.js middleware
│
├── prisma/
│   ├── schema.prisma                      # Database schema
│   ├── migrations/                        # Migration files
│   └── seed.ts                            # Seed data
│
├── tests/
│   ├── unit/
│   │   ├── services/
│   │   └── utils/
│   │
│   ├── integration/
│   │   ├── api/
│   │   └── db/
│   │
│   └── e2e/
│       └── translation.test.ts
│
├── scripts/
│   ├── generate-keys.ts                   # JWT key generation
│   └── sync-languages.ts                  # Language sync script
│
├── .env.example
├── .env.local
├── docker-compose.yml                     # Local dev environment
├── Dockerfile                             # Production build
├── next.config.js
├── package.json
├── tsconfig.json
├── jest.config.js
└── README.md
```

---

## 4. Security Implementation

### 4.1 Authentication Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SIGN IN WITH APPLE FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────┘

    iOS App                      Backend                        Apple
       │                            │                              │
       │  1. Tap "Sign in with Apple"                              │
       │  ──────────────────────────►                              │
       │                            │                              │
       │◄──────────────────────────  (Apple Auth Sheet)            │
       │  2. User authenticates     │                              │
       │  ──────────────────────────────────────────────────────────►
       │                            │                              │
       │  3. Receive identityToken  │                              │
       │◄──────────────────────────────────────────────────────────
       │  + authorizationCode       │                              │
       │                            │                              │
       │  4. POST /api/auth/apple   │                              │
       │  {identityToken, code,     │                              │
       │   firstName, lastName}     │                              │
       │  ──────────────────────────►                              │
       │                            │  5. Verify identityToken     │
       │                            │  with Apple's public keys    │
       │                            │  ─────────────────────────────►
       │                            │◄─────────────────────────────
       │                            │                              │
       │                            │  6. Create/Update user       │
       │                            │  Generate JWT pair           │
       │                            │                              │
       │  7. Return tokens          │                              │
       │  {accessToken, refreshToken│                              │
       │   expiresIn, user}         │                              │
       │◄──────────────────────────                               │
       │                            │                              │
       │  8. Store in Keychain      │                              │
       │                            │                              │
```

### 4.2 JWT Token Strategy

```typescript
// Token Configuration
interface TokenConfig {
  accessToken: {
    expiresIn: '15m';        // Short-lived for security
    algorithm: 'ES256';       // ECDSA with P-256 curve
  };
  refreshToken: {
    expiresIn: '30d';        // Long-lived for UX
    algorithm: 'ES256';
    rotateOnUse: true;       // Single-use refresh tokens
  };
}

// Access Token Payload
interface AccessTokenPayload {
  sub: string;               // User ID (UUID)
  email: string;             // User email
  tier: 'free' | 'pro' | 'premium';
  iat: number;               // Issued at
  exp: number;               // Expiration
  jti: string;               // Unique token ID
}

// Refresh Token Payload
interface RefreshTokenPayload {
  sub: string;               // User ID
  family: string;            // Token family for rotation
  iat: number;
  exp: number;
  jti: string;
}
```

### 4.3 Security Middleware Chain

```typescript
// Middleware execution order
const securityMiddlewareChain = [
  // 1. Request ID injection (for tracing)
  requestIdMiddleware,

  // 2. Rate limiting (before auth to prevent brute force)
  rateLimitMiddleware,

  // 3. Input sanitization
  sanitizationMiddleware,

  // 4. JWT authentication
  authMiddleware,

  // 5. Request validation (Zod schemas)
  validationMiddleware,

  // 6. Subscription tier verification
  tierMiddleware,

  // 7. Usage quota check
  usageMiddleware,
];
```

### 4.4 Rate Limiting Strategy

```typescript
// Tier-based rate limits
const rateLimits = {
  // Global limits (per IP)
  global: {
    windowMs: 60_000,        // 1 minute
    maxRequests: 100,        // 100 requests/min
  },

  // Authentication endpoints
  auth: {
    windowMs: 900_000,       // 15 minutes
    maxRequests: 5,          // 5 attempts
  },

  // Translation endpoints (by user tier)
  translation: {
    free: {
      windowMs: 86_400_000,  // 24 hours
      maxRequests: 10,       // 10/day
    },
    pro: {
      windowMs: 86_400_000,
      maxRequests: 100,      // 100/day
    },
    premium: {
      windowMs: 86_400_000,
      maxRequests: -1,       // Unlimited
    },
  },
};
```

### 4.5 Data Encryption

```typescript
// Encryption at rest
const encryptionConfig = {
  // Database-level encryption
  database: {
    method: 'AES-256-GCM',
    keyManagement: 'Railway Vault / AWS KMS',
    encryptedColumns: [
      'user.email',          // PII
      'user.apple_user_id',  // Sensitive identifier
      'message.audio_url',   // Audio location
    ],
  },

  // Audio file encryption
  audioStorage: {
    method: 'AES-256-GCM',
    keyDerivation: 'HKDF-SHA256',
    keyRotation: '90 days',
  },

  // Token encryption (refresh tokens in DB)
  tokens: {
    method: 'Argon2id',      // For hashing
    saltLength: 16,
    memoryCost: 65536,
    timeCost: 3,
  },
};
```

### 4.6 iOS Security Implementation

```swift
// Keychain storage for sensitive data
final class SecureStorage {
    private let keychain = Keychain(service: "com.verbio.app")
        .accessibility(.afterFirstUnlock)
        .authenticationPolicy(.biometryAny)

    // Store access token
    func storeAccessToken(_ token: String) throws {
        try keychain
            .label("Verbio Access Token")
            .set(token, key: "access_token")
    }

    // Store refresh token with biometric protection
    func storeRefreshToken(_ token: String) throws {
        try keychain
            .accessibility(.whenUnlockedThisDeviceOnly)
            .authenticationPolicy(.biometryCurrentSet)
            .label("Verbio Refresh Token")
            .set(token, key: "refresh_token")
    }
}

// Certificate pinning for API calls
final class NetworkSecurity {
    static let pinnedCertificates: [SecCertificate] = {
        // Load pinned certificates from bundle
        guard let certPath = Bundle.main.path(forResource: "api-cert", ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath),
              let cert = SecCertificateCreateWithData(nil, certData) else {
            fatalError("Failed to load pinned certificate")
        }
        return [cert]
    }()
}
```

### 4.7 Input Validation & Sanitization

```typescript
// Zod schemas with strict validation
import { z } from 'zod';

// Translation request schema
export const translateRequestSchema = z.object({
  audio: z
    .string()
    .regex(/^[A-Za-z0-9+/=]+$/, 'Invalid base64')
    .max(10_000_000, 'Audio too large (max 10MB)'),

  sourceLanguage: z
    .enum(['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko'])
    .optional(),

  targetLanguage: z
    .enum(['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko']),

  conversationId: z
    .string()
    .uuid()
    .optional(),

  context: z
    .string()
    .max(1000, 'Context too long')
    .optional(),
});

// Sanitization middleware
export function sanitizeInput<T>(data: T): T {
  if (typeof data === 'string') {
    return data
      .trim()
      .replace(/[<>]/g, '')           // Basic XSS prevention
      .normalize('NFC') as T;         // Unicode normalization
  }
  if (Array.isArray(data)) {
    return data.map(sanitizeInput) as T;
  }
  if (typeof data === 'object' && data !== null) {
    return Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, sanitizeInput(v)])
    ) as T;
  }
  return data;
}
```

### 4.8 OWASP Top 10 Mitigations

| Vulnerability | Mitigation |
|--------------|------------|
| **A01 Broken Access Control** | JWT with role claims, middleware checks, resource ownership validation |
| **A02 Cryptographic Failures** | AES-256-GCM encryption, TLS 1.3 only, secure key management |
| **A03 Injection** | Prisma ORM (parameterized queries), Zod validation, input sanitization |
| **A04 Insecure Design** | Threat modeling, secure defaults, principle of least privilege |
| **A05 Security Misconfiguration** | Environment validation, secure headers, CSP policies |
| **A06 Vulnerable Components** | Dependabot, npm audit, regular dependency updates |
| **A07 Auth Failures** | Sign in with Apple only, JWT rotation, brute force protection |
| **A08 Data Integrity** | Request signing, HMAC validation for webhooks |
| **A09 Logging Failures** | Structured logging, audit trails, no PII in logs |
| **A10 SSRF** | URL validation, allowlisted external services only |

### 4.9 Security Headers

```typescript
// next.config.js security headers
const securityHeaders = [
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on',
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload',
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY',
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()',
  },
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';",
  },
];
```

---

## 5. Database Schema

### 5.1 Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================================================
// ENUMS
// ============================================================================

enum SubscriptionTier {
  FREE
  PRO
  PREMIUM
}

enum SubscriptionStatus {
  ACTIVE
  CANCELLED
  EXPIRED
  GRACE_PERIOD
}

enum Speaker {
  USER
  OTHER
}

enum Language {
  EN  // English
  ES  // Spanish
  FR  // French
  DE  // German
  IT  // Italian
  PT  // Portuguese
  ZH  // Mandarin Chinese
  JA  // Japanese
  KO  // Korean
}

// ============================================================================
// MODELS
// ============================================================================

model User {
  id                String              @id @default(uuid()) @db.Uuid
  appleUserId       String              @unique @map("apple_user_id")
  email             String              @unique
  emailVerified     Boolean             @default(false) @map("email_verified")
  firstName         String?             @map("first_name")
  lastName          String?             @map("last_name")

  // Subscription
  subscriptionTier   SubscriptionTier   @default(FREE) @map("subscription_tier")
  subscriptionStatus SubscriptionStatus @default(ACTIVE) @map("subscription_status")
  subscriptionExpiry DateTime?          @map("subscription_expiry")
  stripeCustomerId   String?            @unique @map("stripe_customer_id")

  // Usage tracking
  dailyTranslations  Int                @default(0) @map("daily_translations")
  totalTranslations  Int                @default(0) @map("total_translations")
  lastUsageReset     DateTime           @default(now()) @map("last_usage_reset")

  // Timestamps
  createdAt          DateTime           @default(now()) @map("created_at")
  updatedAt          DateTime           @updatedAt @map("updated_at")
  lastLoginAt        DateTime?          @map("last_login_at")

  // Relations
  conversations      Conversation[]
  savedPhrases       SavedPhrase[]
  voicePreference    VoicePreference?
  refreshTokens      RefreshToken[]
  usageRecords       UsageRecord[]

  @@index([email])
  @@index([appleUserId])
  @@index([subscriptionTier])
  @@map("users")
}

model RefreshToken {
  id          String    @id @default(uuid()) @db.Uuid
  tokenHash   String    @unique @map("token_hash")
  family      String    @db.Uuid  // For token rotation detection
  userId      String    @map("user_id") @db.Uuid
  expiresAt   DateTime  @map("expires_at")
  revokedAt   DateTime? @map("revoked_at")
  createdAt   DateTime  @default(now()) @map("created_at")
  userAgent   String?   @map("user_agent")
  ipAddress   String?   @map("ip_address")

  // Relations
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([family])
  @@index([expiresAt])
  @@map("refresh_tokens")
}

model VoicePreference {
  id                String    @id @default(uuid()) @db.Uuid
  userId            String    @unique @map("user_id") @db.Uuid
  preferredVoiceId  String    @map("preferred_voice_id")  // ElevenLabs voice ID
  voiceName         String    @map("voice_name")
  speechRate        Float     @default(1.0) @map("speech_rate")
  defaultSourceLang Language  @default(EN) @map("default_source_lang")
  defaultTargetLang Language  @default(ES) @map("default_target_lang")
  autoDetectSource  Boolean   @default(true) @map("auto_detect_source")
  createdAt         DateTime  @default(now()) @map("created_at")
  updatedAt         DateTime  @updatedAt @map("updated_at")

  // Relations
  user              User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("voice_preferences")
}

model Conversation {
  id              String     @id @default(uuid()) @db.Uuid
  userId          String     @map("user_id") @db.Uuid
  title           String?
  sourceLanguage  Language   @map("source_language")
  targetLanguage  Language   @map("target_language")
  isActive        Boolean    @default(true) @map("is_active")
  createdAt       DateTime   @default(now()) @map("created_at")
  updatedAt       DateTime   @updatedAt @map("updated_at")
  deletedAt       DateTime?  @map("deleted_at")

  // Relations
  user            User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  messages        Message[]

  @@index([userId])
  @@index([createdAt])
  @@index([isActive])
  @@map("conversations")
}

model Message {
  id              String        @id @default(uuid()) @db.Uuid
  conversationId  String        @map("conversation_id") @db.Uuid
  speaker         Speaker
  originalText    String        @map("original_text") @db.Text
  translatedText  String        @map("translated_text") @db.Text
  sourceLanguage  Language      @map("source_language")
  targetLanguage  Language      @map("target_language")
  originalAudioUrl   String?    @map("original_audio_url")
  translatedAudioUrl String?    @map("translated_audio_url")
  durationMs      Int?          @map("duration_ms")
  confidence      Float?        // STT confidence score
  createdAt       DateTime      @default(now()) @map("created_at")

  // Relations
  conversation    Conversation  @relation(fields: [conversationId], references: [id], onDelete: Cascade)

  @@index([conversationId])
  @@index([createdAt])
  @@map("messages")
}

model SavedPhrase {
  id              String    @id @default(uuid()) @db.Uuid
  userId          String    @map("user_id") @db.Uuid
  originalText    String    @map("original_text")
  translatedText  String    @map("translated_text")
  sourceLanguage  Language  @map("source_language")
  targetLanguage  Language  @map("target_language")
  audioUrl        String?   @map("audio_url")
  category        String?
  isFavorite      Boolean   @default(false) @map("is_favorite")
  useCount        Int       @default(0) @map("use_count")
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @updatedAt @map("updated_at")

  // Relations
  user            User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([sourceLanguage, targetLanguage])
  @@index([isFavorite])
  @@map("saved_phrases")
}

model UsageRecord {
  id              String    @id @default(uuid()) @db.Uuid
  userId          String    @map("user_id") @db.Uuid
  date            DateTime  @db.Date
  translations    Int       @default(0)
  audioMinutes    Float     @default(0) @map("audio_minutes")
  ttsCharacters   Int       @default(0) @map("tts_characters")
  estimatedCost   Float     @default(0) @map("estimated_cost")
  createdAt       DateTime  @default(now()) @map("created_at")

  // Relations
  user            User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, date])
  @@index([date])
  @@map("usage_records")
}

// ============================================================================
// SYSTEM TABLES
// ============================================================================

model AppStoreTransaction {
  id                    String    @id @default(uuid()) @db.Uuid
  userId                String    @map("user_id") @db.Uuid
  originalTransactionId String    @unique @map("original_transaction_id")
  productId             String    @map("product_id")
  purchaseDate          DateTime  @map("purchase_date")
  expiresDate           DateTime? @map("expires_date")
  isTrialPeriod         Boolean   @default(false) @map("is_trial_period")
  environment           String    // sandbox or production
  createdAt             DateTime  @default(now()) @map("created_at")
  updatedAt             DateTime  @updatedAt @map("updated_at")

  @@index([userId])
  @@index([originalTransactionId])
  @@map("appstore_transactions")
}

model AuditLog {
  id          String    @id @default(uuid()) @db.Uuid
  userId      String?   @map("user_id") @db.Uuid
  action      String
  resource    String
  resourceId  String?   @map("resource_id")
  details     Json?
  ipAddress   String?   @map("ip_address")
  userAgent   String?   @map("user_agent")
  createdAt   DateTime  @default(now()) @map("created_at")

  @@index([userId])
  @@index([action])
  @@index([createdAt])
  @@map("audit_logs")
}
```

### 5.2 Redis Data Structures

```typescript
// Redis key patterns and data structures

// Rate limiting
`ratelimit:${userId}:translation` -> Counter with TTL
`ratelimit:${ip}:global` -> Counter with TTL
`ratelimit:${ip}:auth` -> Counter with TTL

// Session/Token management
`refresh_token_family:${userId}:${family}` -> Set of token JTIs
`blacklist:token:${jti}` -> Empty value with TTL

// Caching
`cache:user:${userId}` -> Hash {tier, dailyUsage, ...}
`cache:conversation:${conversationId}:context` -> List of recent messages
`cache:voices:${language}` -> JSON array of available voices

// Usage tracking (real-time)
`usage:${userId}:${date}` -> Hash {translations, audioMinutes, ttsChars}

// Temporary audio storage
`audio:pending:${requestId}` -> Base64 audio data with short TTL
```

### 5.3 Database Indexes Strategy

```sql
-- Performance indexes
CREATE INDEX CONCURRENTLY idx_messages_conversation_created
  ON messages (conversation_id, created_at DESC);

CREATE INDEX CONCURRENTLY idx_conversations_user_active
  ON conversations (user_id, is_active)
  WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY idx_users_subscription_expiry
  ON users (subscription_expiry)
  WHERE subscription_tier != 'FREE';

-- Full-text search for phrases
CREATE INDEX CONCURRENTLY idx_phrases_text_search
  ON saved_phrases USING gin(to_tsvector('english', original_text || ' ' || translated_text));
```

---

## 6. API Design

### 6.1 API Endpoints Overview

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/apple` | No | Sign in with Apple |
| POST | `/api/auth/refresh` | Refresh | Refresh access token |
| POST | `/api/auth/logout` | Yes | Logout and revoke tokens |
| POST | `/api/translate` | Yes | Translate audio |
| GET | `/api/conversations` | Yes | List conversations |
| POST | `/api/conversations` | Yes | Create conversation |
| GET | `/api/conversations/:id` | Yes | Get conversation |
| DELETE | `/api/conversations/:id` | Yes | Delete conversation |
| GET | `/api/conversations/:id/messages` | Yes | Get messages |
| GET | `/api/user` | Yes | Get user profile |
| PATCH | `/api/user` | Yes | Update user |
| GET | `/api/user/preferences` | Yes | Get preferences |
| PUT | `/api/user/preferences` | Yes | Update preferences |
| GET | `/api/user/usage` | Yes | Get usage stats |
| GET | `/api/phrases` | Yes | List saved phrases |
| POST | `/api/phrases` | Yes | Save phrase |
| DELETE | `/api/phrases/:id` | Yes | Delete phrase |
| POST | `/api/subscriptions/verify` | Yes | Verify App Store receipt |
| GET | `/api/subscriptions` | Yes | Get subscription status |
| POST | `/api/webhooks/appstore` | HMAC | App Store notifications |
| GET | `/api/health` | No | Health check |

### 6.2 Core API Contracts

#### Authentication

```typescript
// POST /api/auth/apple
interface AppleAuthRequest {
  identityToken: string;      // JWT from Apple
  authorizationCode: string;  // Code for token exchange
  firstName?: string;         // Only on first sign-in
  lastName?: string;
  deviceId: string;           // For device tracking
}

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;          // Seconds until access token expires
  user: {
    id: string;
    email: string;
    firstName?: string;
    lastName?: string;
    tier: 'free' | 'pro' | 'premium';
    dailyTranslationsRemaining: number;
  };
}

// POST /api/auth/refresh
interface RefreshRequest {
  refreshToken: string;
}

interface RefreshResponse {
  accessToken: string;
  refreshToken: string;       // New refresh token (rotation)
  expiresIn: number;
}
```

#### Translation

```typescript
// POST /api/translate
interface TranslateRequest {
  audio: string;              // Base64 encoded audio (WAV/M4A)
  sourceLanguage?: string;    // ISO 639-1 code, auto-detect if omitted
  targetLanguage: string;     // ISO 639-1 code
  conversationId?: string;    // For context-aware translation
  voiceId?: string;           // ElevenLabs voice ID override
}

interface TranslateResponse {
  id: string;                 // Message ID
  originalText: string;       // STT transcription
  translatedText: string;     // GPT-4o translation
  sourceLanguage: string;     // Detected or provided
  targetLanguage: string;
  audioUrl: string;           // ElevenLabs TTS audio URL
  confidence: number;         // STT confidence (0-1)
  durationMs: number;         // Audio duration
  usage: {
    dailyRemaining: number;
    tier: string;
  };
}

// Error responses
interface TranslateError {
  error: {
    code: 'QUOTA_EXCEEDED' | 'INVALID_AUDIO' | 'UNSUPPORTED_LANGUAGE' |
          'TRANSCRIPTION_FAILED' | 'TRANSLATION_FAILED' | 'TTS_FAILED';
    message: string;
    details?: Record<string, unknown>;
  };
}
```

#### Conversations

```typescript
// GET /api/conversations
interface ConversationsListResponse {
  conversations: {
    id: string;
    title?: string;
    sourceLanguage: string;
    targetLanguage: string;
    messageCount: number;
    lastMessageAt: string;    // ISO timestamp
    createdAt: string;
  }[];
  pagination: {
    total: number;
    page: number;
    pageSize: number;
    hasMore: boolean;
  };
}

// POST /api/conversations
interface CreateConversationRequest {
  sourceLanguage: string;
  targetLanguage: string;
  title?: string;
}

// GET /api/conversations/:id/messages
interface MessagesResponse {
  messages: {
    id: string;
    speaker: 'user' | 'other';
    originalText: string;
    translatedText: string;
    sourceLanguage: string;
    targetLanguage: string;
    audioUrl?: string;
    createdAt: string;
  }[];
  pagination: {
    cursor?: string;
    hasMore: boolean;
  };
}
```

#### User & Preferences

```typescript
// GET /api/user
interface UserResponse {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  subscription: {
    tier: 'free' | 'pro' | 'premium';
    status: 'active' | 'cancelled' | 'expired' | 'grace_period';
    expiresAt?: string;
  };
  usage: {
    dailyTranslations: number;
    dailyLimit: number;
    totalTranslations: number;
  };
  createdAt: string;
}

// GET/PUT /api/user/preferences
interface UserPreferences {
  preferredVoiceId: string;
  voiceName: string;
  speechRate: number;         // 0.5 - 2.0
  defaultSourceLanguage?: string;
  defaultTargetLanguage: string;
  autoDetectSource: boolean;
  notifications: {
    dailyReminder: boolean;
    newFeatures: boolean;
  };
}
```

### 6.3 Error Response Format

```typescript
// Standard error response
interface APIError {
  error: {
    code: string;             // Machine-readable error code
    message: string;          // Human-readable message
    details?: {
      field?: string;         // Field that caused error
      constraint?: string;    // Validation constraint
      [key: string]: unknown;
    };
    requestId: string;        // For support/debugging
  };
}

// HTTP Status Code Mapping
const errorStatusCodes = {
  // 4xx Client Errors
  VALIDATION_ERROR: 400,
  INVALID_TOKEN: 401,
  TOKEN_EXPIRED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  QUOTA_EXCEEDED: 429,
  RATE_LIMITED: 429,

  // 5xx Server Errors
  INTERNAL_ERROR: 500,
  TRANSCRIPTION_FAILED: 502,
  TRANSLATION_FAILED: 502,
  TTS_FAILED: 502,
  SERVICE_UNAVAILABLE: 503,
};
```

### 6.4 WebSocket API (Future: Real-time)

```typescript
// Future: WebSocket for real-time streaming
// wss://api.verbio.app/ws

interface WSMessage {
  type: 'audio_chunk' | 'transcription' | 'translation' | 'tts_chunk' | 'error';
  payload: unknown;
  sequence: number;
}

// Client -> Server
interface AudioChunkMessage {
  type: 'audio_chunk';
  payload: {
    data: string;             // Base64 chunk
    final: boolean;           // Last chunk flag
  };
}

// Server -> Client (streaming response)
interface TranscriptionMessage {
  type: 'transcription';
  payload: {
    text: string;
    isFinal: boolean;
    confidence: number;
  };
}
```

---

## 7. iOS Implementation

### 7.1 Core Services

#### AudioService

```swift
import AVFoundation
import Combine

@MainActor
final class AudioService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var levelTimer: Timer?

    private let audioSession = AVAudioSession.sharedInstance()

    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    func startRecording() async throws -> URL {
        try await configureAudioSession(for: .recording)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        audioRecorder = try AVAudioRecorder(url: url, settings: recordingSettings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        startLevelMonitoring()
        return url
    }

    func stopRecording() async throws -> Data {
        guard let recorder = audioRecorder, isRecording else {
            throw AudioError.notRecording
        }
        recorder.stop()
        stopLevelMonitoring()
        isRecording = false

        let data = try Data(contentsOf: recorder.url)
        try? FileManager.default.removeItem(at: recorder.url)
        audioRecorder = nil
        return data
    }

    func playAudio(from url: URL) async throws {
        try await configureAudioSession(for: .playback)
        let data = try await URLSession.shared.data(from: url).0
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.play()
    }

    private func configureAudioSession(for mode: AudioMode) async throws {
        try audioSession.setCategory(
            mode == .recording ? .playAndRecord : .playback,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try audioSession.setActive(true)
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }

    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        audioLevel = max(0, (level + 60) / 60)
        recordingDuration = audioRecorder?.currentTime ?? 0
    }

    enum AudioMode { case recording, playback }
}
```

#### NetworkClient (Excerpt)

```swift
actor NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    private let authStorage: AuthStorageProtocol
    private var refreshTask: Task<AuthTokens, Error>?

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws -> T {
        var request = try buildRequest(for: endpoint, body: body)

        if endpoint.requiresAuth {
            let token = try await getValidAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 && endpoint.requiresAuth {
            _ = try await refreshAccessToken()
            return try await self.request(endpoint, body: body)
        }

        try validateResponse(httpResponse, data: data)
        return try JSONDecoder.apiDecoder.decode(T.self, from: data)
    }

    private func getValidAccessToken() async throws -> String {
        guard let tokens = try? await authStorage.getTokens() else {
            throw NetworkError.unauthorized
        }
        if tokens.isAccessTokenExpiringSoon {
            return try await refreshAccessToken().accessToken
        }
        return tokens.accessToken
    }

    private func refreshAccessToken() async throws -> AuthTokens {
        if let existingTask = refreshTask { return try await existingTask.value }
        let task = Task<AuthTokens, Error> {
            defer { refreshTask = nil }
            // Token refresh implementation
            // ...
        }
        refreshTask = task
        return try await task.value
    }
}
```

### 7.2 MVVM Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        View Layer                            │
│  SwiftUI Views observe @Published properties                │
│  User interactions call ViewModel methods                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     ViewModel Layer                          │
│  @MainActor classes with @Published state                   │
│  Coordinates between Views and Services                     │
│  Handles error mapping and state management                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  Domain-specific business logic                             │
│  Protocol-based for testability                             │
│  AudioService, TranslationService, AuthService              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│  Data access abstraction                                    │
│  Combines remote (API) and local (SwiftData) sources        │
│  Handles caching and offline support                        │
└─────────────────────────────────────────────────────────────┘
```

### 7.3 Dependency Injection

```swift
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Core Services
    lazy var authStorage: AuthStorageProtocol = KeychainAuthStorage()
    lazy var networkClient: NetworkClient = NetworkClient(authStorage: authStorage)
    lazy var audioService: AudioService = AudioService()

    // MARK: - Domain Services
    lazy var authService: AuthServiceProtocol = AuthService(
        networkClient: networkClient,
        authStorage: authStorage
    )
    lazy var translationService: TranslationServiceProtocol = TranslationService(
        networkClient: networkClient
    )

    // MARK: - ViewModels
    func makeTranslationViewModel() -> TranslationViewModel {
        TranslationViewModel(
            audioService: audioService,
            translationService: translationService
        )
    }

    func makeConversationViewModel(id: String) -> ConversationViewModel {
        ConversationViewModel(
            conversationId: id,
            audioService: audioService,
            translationService: translationService
        )
    }
}

// Property wrapper for injection
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>
    var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
    init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}
```

---

## 8. Backend Implementation

### 8.1 Translation Service

```typescript
// src/lib/services/translation.ts
import OpenAI from 'openai';
import { ElevenLabsClient } from 'elevenlabs';
import { prisma } from '../db/prisma';
import { redis } from '../db/redis';
import { uploadToR2 } from './storage';
import { AppError } from '../errors/AppError';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const elevenlabs = new ElevenLabsClient({ apiKey: process.env.ELEVENLABS_API_KEY });

interface TranslationInput {
  audioBase64: string;
  sourceLanguage?: string;
  targetLanguage: string;
  conversationId?: string;
  userId: string;
  voiceId?: string;
}

interface TranslationResult {
  originalText: string;
  translatedText: string;
  sourceLanguage: string;
  targetLanguage: string;
  audioUrl: string;
  confidence: number;
  durationMs: number;
}

export async function translateAudio(input: TranslationInput): Promise<TranslationResult> {
  const { audioBase64, targetLanguage, conversationId, userId, voiceId } = input;

  // 1. Decode audio
  const audioBuffer = Buffer.from(audioBase64, 'base64');

  // 2. Speech-to-Text (Whisper)
  const transcription = await transcribeAudio(audioBuffer, input.sourceLanguage);

  // 3. Get conversation context if available
  const context = conversationId
    ? await getConversationContext(conversationId)
    : undefined;

  // 4. Translate with GPT-4o
  const translation = await translateText(
    transcription.text,
    transcription.language,
    targetLanguage,
    context
  );

  // 5. Generate speech (ElevenLabs)
  const audioStream = await generateSpeech(
    translation.text,
    targetLanguage,
    voiceId
  );

  // 6. Upload to R2
  const audioUrl = await uploadToR2(
    audioStream,
    `audio/${userId}/${Date.now()}.mp3`
  );

  // 7. Store message if part of conversation
  if (conversationId) {
    await prisma.message.create({
      data: {
        conversationId,
        speaker: 'USER',
        originalText: transcription.text,
        translatedText: translation.text,
        sourceLanguage: transcription.language,
        targetLanguage,
        translatedAudioUrl: audioUrl,
        confidence: transcription.confidence,
        durationMs: transcription.durationMs,
      },
    });
  }

  // 8. Update usage
  await updateUsage(userId);

  return {
    originalText: transcription.text,
    translatedText: translation.text,
    sourceLanguage: transcription.language,
    targetLanguage,
    audioUrl,
    confidence: transcription.confidence,
    durationMs: transcription.durationMs,
  };
}

async function transcribeAudio(
  audioBuffer: Buffer,
  language?: string
): Promise<{ text: string; language: string; confidence: number; durationMs: number }> {
  const file = new File([audioBuffer], 'audio.wav', { type: 'audio/wav' });

  const response = await openai.audio.transcriptions.create({
    file,
    model: 'whisper-1',
    language: language || undefined,
    response_format: 'verbose_json',
  });

  return {
    text: response.text,
    language: response.language || language || 'en',
    confidence: response.segments?.[0]?.no_speech_prob
      ? 1 - response.segments[0].no_speech_prob
      : 0.9,
    durationMs: (response.duration || 0) * 1000,
  };
}

async function translateText(
  text: string,
  sourceLanguage: string,
  targetLanguage: string,
  context?: string[]
): Promise<{ text: string }> {
  const systemPrompt = `You are a professional translator. Translate the following text from ${sourceLanguage} to ${targetLanguage}.
Maintain the original tone and intent. Only return the translated text, nothing else.
${context ? `\nConversation context:\n${context.join('\n')}` : ''}`;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: text },
    ],
    temperature: 0.3,
    max_tokens: 1000,
  });

  const translatedText = response.choices[0]?.message?.content;
  if (!translatedText) {
    throw new AppError('TRANSLATION_FAILED', 'Failed to generate translation');
  }

  return { text: translatedText };
}

async function generateSpeech(
  text: string,
  language: string,
  voiceId?: string
): Promise<Buffer> {
  const defaultVoices: Record<string, string> = {
    en: 'pNInz6obpgDQGcFmaJgB', // Adam
    es: 'EXAVITQu4vr4xnSDxMaL', // Bella
    fr: 'onwK4e9ZLuTAKqWW03F9', // Daniel
    de: 'g5CIjZEefAph4nQFvHAz', // Freya
    // Add more default voices per language
  };

  const selectedVoice = voiceId || defaultVoices[language] || defaultVoices.en;

  const audioStream = await elevenlabs.generate({
    voice: selectedVoice,
    text,
    model_id: 'eleven_multilingual_v2',
    output_format: 'mp3_44100_128',
  });

  // Convert stream to buffer
  const chunks: Buffer[] = [];
  for await (const chunk of audioStream) {
    chunks.push(Buffer.from(chunk));
  }

  return Buffer.concat(chunks);
}

async function getConversationContext(conversationId: string): Promise<string[]> {
  // Try cache first
  const cached = await redis.lrange(`context:${conversationId}`, 0, 4);
  if (cached.length > 0) {
    return cached;
  }

  // Fetch from DB
  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'desc' },
    take: 5,
    select: { originalText: true, translatedText: true },
  });

  const context = messages.map(m => `${m.originalText} -> ${m.translatedText}`);

  // Cache for 10 minutes
  if (context.length > 0) {
    await redis.lpush(`context:${conversationId}`, ...context);
    await redis.expire(`context:${conversationId}`, 600);
  }

  return context;
}

async function updateUsage(userId: string): Promise<void> {
  const today = new Date().toISOString().split('T')[0];

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: {
        dailyTranslations: { increment: 1 },
        totalTranslations: { increment: 1 },
      },
    }),
    prisma.usageRecord.upsert({
      where: { userId_date: { userId, date: new Date(today) } },
      create: { userId, date: new Date(today), translations: 1 },
      update: { translations: { increment: 1 } },
    }),
  ]);

  // Update Redis cache
  await redis.hincrby(`usage:${userId}:${today}`, 'translations', 1);
}
```

### 8.2 API Route Example

```typescript
// src/app/api/translate/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { translateAudio } from '@/lib/services/translation';
import { verifyAuth } from '@/lib/auth/middleware';
import { checkUsageQuota } from '@/lib/rate-limit/tiers';
import { AppError, handleApiError } from '@/lib/errors/handler';

const translateSchema = z.object({
  audio: z.string().min(1).max(10_000_000),
  sourceLanguage: z.enum(['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko']).optional(),
  targetLanguage: z.enum(['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko']),
  conversationId: z.string().uuid().optional(),
  voiceId: z.string().optional(),
});

export async function POST(request: NextRequest) {
  try {
    // 1. Authenticate
    const auth = await verifyAuth(request);
    if (!auth.success) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Invalid token' } },
        { status: 401 }
      );
    }

    // 2. Parse and validate body
    const body = await request.json();
    const validation = translateSchema.safeParse(body);
    if (!validation.success) {
      return NextResponse.json(
        {
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid request body',
            details: validation.error.flatten(),
          },
        },
        { status: 400 }
      );
    }

    // 3. Check usage quota
    const quotaCheck = await checkUsageQuota(auth.userId, auth.tier);
    if (!quotaCheck.allowed) {
      return NextResponse.json(
        {
          error: {
            code: 'QUOTA_EXCEEDED',
            message: `Daily translation limit reached. Upgrade to ${quotaCheck.suggestedTier} for more.`,
            details: { remaining: 0, limit: quotaCheck.limit },
          },
        },
        { status: 429 }
      );
    }

    // 4. Perform translation
    const result = await translateAudio({
      audioBase64: validation.data.audio,
      sourceLanguage: validation.data.sourceLanguage,
      targetLanguage: validation.data.targetLanguage,
      conversationId: validation.data.conversationId,
      userId: auth.userId,
      voiceId: validation.data.voiceId,
    });

    // 5. Return response
    return NextResponse.json({
      id: crypto.randomUUID(),
      ...result,
      usage: {
        dailyRemaining: quotaCheck.remaining - 1,
        tier: auth.tier,
      },
    });
  } catch (error) {
    return handleApiError(error);
  }
}
```

### 8.3 Authentication Middleware

```typescript
// src/lib/auth/middleware.ts
import { NextRequest } from 'next/server';
import { jwtVerify, importSPKI } from 'jose';
import { prisma } from '../db/prisma';
import { redis } from '../db/redis';

interface AuthResult {
  success: boolean;
  userId: string;
  email: string;
  tier: 'free' | 'pro' | 'premium';
}

const publicKey = await importSPKI(process.env.JWT_PUBLIC_KEY!, 'ES256');

export async function verifyAuth(request: NextRequest): Promise<AuthResult & { success: true } | { success: false }> {
  const authHeader = request.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return { success: false };
  }

  const token = authHeader.slice(7);

  try {
    // Verify JWT
    const { payload } = await jwtVerify(token, publicKey, {
      algorithms: ['ES256'],
      issuer: 'verbio-api',
      audience: 'verbio-ios',
    });

    // Check if token is blacklisted
    const isBlacklisted = await redis.exists(`blacklist:token:${payload.jti}`);
    if (isBlacklisted) {
      return { success: false };
    }

    return {
      success: true,
      userId: payload.sub as string,
      email: payload.email as string,
      tier: payload.tier as 'free' | 'pro' | 'premium',
    };
  } catch {
    return { success: false };
  }
}
```

---

## 9. Testing Strategy

### 9.1 iOS Testing

#### Unit Tests

```swift
// Tests/UnitTests/Services/TranslationServiceTests.swift
import XCTest
@testable import Verbio

final class TranslationServiceTests: XCTestCase {
    var sut: TranslationService!
    var mockNetworkClient: MockNetworkClient!

    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        sut = TranslationService(networkClient: mockNetworkClient)
    }

    func test_translate_success_returnsTranslationResult() async throws {
        // Given
        let expectedResult = TranslateResponse(
            id: "123",
            originalText: "Hello",
            translatedText: "Hola",
            sourceLanguage: "en",
            targetLanguage: "es",
            audioUrl: "https://example.com/audio.mp3",
            confidence: 0.95,
            durationMs: 1500
        )
        mockNetworkClient.mockResponse = expectedResult

        // When
        let result = try await sut.translate(
            audio: Data(),
            from: .english,
            to: .spanish
        )

        // Then
        XCTAssertEqual(result.originalText, "Hello")
        XCTAssertEqual(result.translatedText, "Hola")
        XCTAssertEqual(result.confidence, 0.95)
    }

    func test_translate_quotaExceeded_throwsQuotaError() async {
        // Given
        mockNetworkClient.mockError = NetworkError.apiError(
            APIError(code: "QUOTA_EXCEEDED", message: "Daily limit reached")
        )

        // When/Then
        do {
            _ = try await sut.translate(audio: Data(), from: .english, to: .spanish)
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .apiError(let apiError) = error {
                XCTAssertEqual(apiError.code, "QUOTA_EXCEEDED")
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
```

#### UI Tests

```swift
// Tests/UITests/TranslationUITests.swift
import XCTest

final class TranslationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func test_recordButton_changesStateWhileRecording() {
        // Given
        let recordButton = app.buttons["recordButton"]
        XCTAssertTrue(recordButton.exists)

        // When - press and hold
        recordButton.press(forDuration: 2.0)

        // Then - verify processing state appears
        let processingIndicator = app.activityIndicators["processingIndicator"]
        XCTAssertTrue(processingIndicator.waitForExistence(timeout: 5))
    }

    func test_languageSwap_swapsLanguages() {
        // Given
        let sourceButton = app.buttons["sourceLanguageButton"]
        let targetButton = app.buttons["targetLanguageButton"]
        let swapButton = app.buttons["swapLanguagesButton"]

        let initialSource = sourceButton.label
        let initialTarget = targetButton.label

        // When
        swapButton.tap()

        // Then
        XCTAssertEqual(sourceButton.label, initialTarget)
        XCTAssertEqual(targetButton.label, initialSource)
    }
}
```

### 9.2 Backend Testing

#### Unit Tests

```typescript
// tests/unit/services/translation.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { translateAudio } from '@/lib/services/translation';

// Mocks
vi.mock('openai');
vi.mock('elevenlabs');
vi.mock('@/lib/db/prisma');
vi.mock('@/lib/db/redis');

describe('TranslationService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('translateAudio', () => {
    it('should successfully translate audio', async () => {
      // Arrange
      const mockTranscription = { text: 'Hello', language: 'en', confidence: 0.95 };
      const mockTranslation = { text: 'Hola' };
      const mockAudioBuffer = Buffer.from('audio');

      vi.mocked(openai.audio.transcriptions.create).mockResolvedValue(mockTranscription);
      vi.mocked(openai.chat.completions.create).mockResolvedValue({
        choices: [{ message: { content: 'Hola' } }],
      });

      // Act
      const result = await translateAudio({
        audioBase64: Buffer.from('test').toString('base64'),
        targetLanguage: 'es',
        userId: 'user-123',
      });

      // Assert
      expect(result.originalText).toBe('Hello');
      expect(result.translatedText).toBe('Hola');
      expect(result.sourceLanguage).toBe('en');
    });

    it('should throw error when transcription fails', async () => {
      vi.mocked(openai.audio.transcriptions.create).mockRejectedValue(
        new Error('Transcription failed')
      );

      await expect(
        translateAudio({
          audioBase64: 'invalid',
          targetLanguage: 'es',
          userId: 'user-123',
        })
      ).rejects.toThrow();
    });
  });
});
```

#### Integration Tests

```typescript
// tests/integration/api/translate.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createServer } from 'http';
import { apiResolver } from 'next/dist/server/api-utils/node';
import { POST } from '@/app/api/translate/route';

describe('POST /api/translate', () => {
  let testServer: ReturnType<typeof createServer>;

  beforeAll(async () => {
    // Setup test database
    await setupTestDatabase();
  });

  afterAll(async () => {
    await cleanupTestDatabase();
  });

  it('should return 401 without auth token', async () => {
    const request = new Request('http://localhost/api/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ audio: 'base64...', targetLanguage: 'es' }),
    });

    const response = await POST(request as any);

    expect(response.status).toBe(401);
  });

  it('should return 400 with invalid body', async () => {
    const request = new Request('http://localhost/api/translate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${getTestToken()}`,
      },
      body: JSON.stringify({ audio: '', targetLanguage: 'invalid' }),
    });

    const response = await POST(request as any);

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it('should return 429 when quota exceeded', async () => {
    // Exhaust quota first
    await exhaustUserQuota('test-user-id');

    const request = new Request('http://localhost/api/translate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${getTestToken({ tier: 'free' })}`,
      },
      body: JSON.stringify({
        audio: validAudioBase64,
        targetLanguage: 'es',
      }),
    });

    const response = await POST(request as any);

    expect(response.status).toBe(429);
    const body = await response.json();
    expect(body.error.code).toBe('QUOTA_EXCEEDED');
  });
});
```

### 9.3 Test Coverage Targets

| Layer | Target | Tool |
|-------|--------|------|
| iOS Unit Tests | 80%+ | XCTest |
| iOS UI Tests | Critical flows | XCUITest |
| Backend Unit Tests | 85%+ | Vitest |
| Backend Integration | API routes | Vitest |
| E2E Tests | Happy paths | Playwright |

---

## 10. DevOps & CI/CD

### 10.1 Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            RAILWAY DEPLOYMENT                                │
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │  Next.js    │    │  PostgreSQL │    │    Redis    │                      │
│  │   (API)     │◄───│  (Primary)  │    │   (Cache)   │                      │
│  │             │    │             │    │             │                      │
│  └─────────────┘    └─────────────┘    └─────────────┘                      │
│         │                  │                  │                              │
│         └──────────────────┼──────────────────┘                              │
│                            │                                                 │
│                    Private Network                                           │
└────────────────────────────┼────────────────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
                    ┌─────────────────┐
                    │   Cloudflare    │
                    │   (CDN + WAF)   │
                    └─────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ iOS App  │  │ R2 Audio │  │ Webhooks │
        │          │  │ Storage  │  │          │
        └──────────┘  └──────────┘  └──────────┘
```

### 10.2 CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'

jobs:
  # Backend Tests
  backend-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: verbio_test
        ports:
          - 5432:5432
      redis:
        image: redis:7
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: verbio-backend/package-lock.json

      - name: Install dependencies
        working-directory: verbio-backend
        run: npm ci

      - name: Run Prisma migrations
        working-directory: verbio-backend
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/verbio_test

      - name: Run tests
        working-directory: verbio-backend
        run: npm run test:coverage
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/verbio_test
          REDIS_URL: redis://localhost:6379

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: verbio-backend/coverage/lcov.info

  # Backend Lint & Type Check
  backend-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: verbio-backend/package-lock.json

      - run: npm ci
        working-directory: verbio-backend

      - run: npm run lint
        working-directory: verbio-backend

      - run: npm run type-check
        working-directory: verbio-backend

  # iOS Build
  ios-build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Build iOS app
        run: |
          xcodebuild build \
            -project Verbio.xcodeproj \
            -scheme Verbio \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO

  # iOS Tests
  ios-test:
    runs-on: macos-14
    needs: ios-build
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run tests
        run: |
          xcodebuild test \
            -project Verbio.xcodeproj \
            -scheme Verbio \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -resultBundlePath TestResults

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults

  # Deploy to Railway (Production)
  deploy-production:
    runs-on: ubuntu-latest
    needs: [backend-test, backend-lint]
    if: github.ref == 'refs/heads/main'
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy to Railway
        working-directory: verbio-backend
        run: railway up --service verbio-api
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

      - name: Run migrations
        working-directory: verbio-backend
        run: railway run npx prisma migrate deploy
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

### 10.3 Environment Configuration

```bash
# .env.example (Backend)

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/verbio"

# Redis
REDIS_URL="redis://localhost:6379"

# JWT Keys (ES256)
JWT_PRIVATE_KEY="-----BEGIN EC PRIVATE KEY-----\n...\n-----END EC PRIVATE KEY-----"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"

# External APIs
OPENAI_API_KEY="sk-..."
ELEVENLABS_API_KEY="..."
DEEPL_API_KEY="..."

# Cloudflare R2
R2_ACCOUNT_ID="..."
R2_ACCESS_KEY_ID="..."
R2_SECRET_ACCESS_KEY="..."
R2_BUCKET_NAME="verbio-audio"

# Apple Sign In
APPLE_TEAM_ID="..."
APPLE_SERVICE_ID="..."
APPLE_KEY_ID="..."
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# App Store Server
APPSTORE_ISSUER_ID="..."
APPSTORE_KEY_ID="..."
APPSTORE_PRIVATE_KEY="..."

# Environment
NODE_ENV="development"
LOG_LEVEL="debug"
```

---

## 11. Phase Implementation

### Phase 1: Foundation (Weeks 1-2)

#### Week 1: Project Setup & Auth

| Task | Description | Priority |
|------|-------------|----------|
| iOS Project Structure | Set up MVVM folders, SPM packages | P0 |
| Backend Project Setup | Next.js 14, Prisma, TypeScript config | P0 |
| Database Schema | Create Prisma schema, initial migrations | P0 |
| Sign in with Apple (iOS) | AuthenticationServices integration | P0 |
| Sign in with Apple (Backend) | Token verification, JWT generation | P0 |
| Keychain Storage | Secure token storage implementation | P0 |
| Basic Navigation | Tab bar, navigation coordinator | P1 |

#### Week 2: Infrastructure

| Task | Description | Priority |
|------|-------------|----------|
| Railway Deployment | Set up production environment | P0 |
| Redis Integration | Cache layer setup | P0 |
| R2 Storage Setup | Audio file storage | P0 |
| CI/CD Pipeline | GitHub Actions workflow | P0 |
| Rate Limiting | Implement tier-based limits | P1 |
| Error Handling | Centralized error management | P1 |
| Logging | Structured logging setup | P1 |

### Phase 2: Core Translation (Weeks 3-4)

#### Week 3: Audio Pipeline

| Task | Description | Priority |
|------|-------------|----------|
| Audio Recording (iOS) | AVAudioRecorder implementation | P0 |
| Audio Playback (iOS) | AVAudioPlayer with streaming | P0 |
| Whisper Integration | OpenAI STT service | P0 |
| GPT-4o Translation | Context-aware translation | P0 |
| Translation API Route | POST /api/translate endpoint | P0 |
| Audio Level Visualization | Waveform component | P1 |

#### Week 4: TTS & Results

| Task | Description | Priority |
|------|-------------|----------|
| ElevenLabs Integration | TTS service implementation | P0 |
| Audio Caching | R2 upload, URL generation | P0 |
| Translation View | Main translation UI | P0 |
| Result Display | Translation result card | P0 |
| Language Picker | Language selection UI | P1 |
| Haptic Feedback | Recording/result feedback | P2 |

### Phase 3: Conversation Mode (Weeks 5-6)

#### Week 5: Conversation Backend

| Task | Description | Priority |
|------|-------------|----------|
| Conversation CRUD | API routes for conversations | P0 |
| Message Storage | Store messages with audio URLs | P0 |
| Context Building | Conversation context for GPT | P0 |
| Conversation List API | Pagination, filtering | P1 |
| SwiftData Models | Local conversation storage | P1 |

#### Week 6: Conversation UI

| Task | Description | Priority |
|------|-------------|----------|
| Conversation View | Bidirectional chat UI | P0 |
| Message Bubbles | Speaker attribution styling | P0 |
| Speaker Toggle | Switch between speakers | P0 |
| Conversation List | History with search | P1 |
| Offline Sync | Basic offline support | P2 |

### Phase 4: Polish & Monetization (Weeks 7-8)

#### Week 7: Subscription System

| Task | Description | Priority |
|------|-------------|----------|
| StoreKit 2 Integration | Product loading, purchasing | P0 |
| Receipt Verification | Server-side validation | P0 |
| Subscription Status API | Tier management endpoints | P0 |
| Paywall UI | Subscription upsell screen | P0 |
| Usage Tracking | Daily limits enforcement | P0 |
| Subscription Management | Cancel, restore flows | P1 |

#### Week 8: Launch Preparation

| Task | Description | Priority |
|------|-------------|----------|
| Onboarding Flow | First-time user experience | P0 |
| Settings Screen | Account, preferences | P0 |
| Voice Preferences | Voice selection, speed | P1 |
| Saved Phrases | Bookmark functionality | P1 |
| App Store Assets | Screenshots, descriptions | P0 |
| TestFlight Beta | Internal testing | P0 |
| Security Audit | Penetration testing | P0 |
| Performance Testing | Load testing API | P1 |

### Post-Launch Roadmap

| Feature | Timeline | Description |
|---------|----------|-------------|
| Analytics Dashboard | Week 9-10 | Usage metrics, revenue tracking |
| Offline Mode | Week 11-12 | Download voices, local translation |
| Apple Watch App | Week 13-14 | Quick translations from wrist |
| Widget Support | Week 15 | Home screen quick access |
| Siri Shortcuts | Week 16 | Voice-activated translation |
| Additional Languages | Ongoing | Expand to 20+ languages |

---

## Appendix A: Language Codes

| Code | Language | ElevenLabs Voice ID |
|------|----------|---------------------|
| en | English | pNInz6obpgDQGcFmaJgB |
| es | Spanish | EXAVITQu4vr4xnSDxMaL |
| fr | French | onwK4e9ZLuTAKqWW03F9 |
| de | German | g5CIjZEefAph4nQFvHAz |
| it | Italian | ThT5KcBeYPX3keUQqHPh |
| pt | Portuguese | TxGEqnHWrfWFTfGW9XjX |
| zh | Chinese | XB0fDUnXU5powFXDhCwa |
| ja | Japanese | iP95p4xoKVk53GoZ742B |
| ko | Korean | Xb7hH8MSUJpSbSDYk0k2 |

---

## Appendix B: Cost Estimation

### Per Translation Cost Breakdown

| Service | Unit | Cost | Avg Usage | Cost/Translation |
|---------|------|------|-----------|------------------|
| Whisper STT | minute | $0.006 | 15 sec | $0.0015 |
| GPT-4o | 1K tokens | $0.01 | 200 tokens | $0.002 |
| ElevenLabs | 1K chars | $0.30 | 50 chars | $0.015 |
| **Total** | | | | **~$0.0185** |

### Monthly Cost Projection (10K MAU)

| Tier | Users | Trans/User/Mo | Total Trans | Cost |
|------|-------|---------------|-------------|------|
| Free | 7,000 | 150 | 1,050,000 | $19,425 |
| Pro | 2,000 | 1,500 | 3,000,000 | $55,500 |
| Premium | 1,000 | 3,000 | 3,000,000 | $55,500 |
| **Total** | | | 7,050,000 | **$130,425** |

### Revenue Projection

| Tier | Users | Price | MRR |
|------|-------|-------|-----|
| Pro | 2,000 | $4.99 | $9,980 |
| Premium | 1,000 | $9.99 | $9,990 |
| **Total MRR** | | | **$19,970** |

**Note:** Costs exceed revenue at this scale. Optimization strategies needed:
1. Aggressive caching of common phrases
2. Batch processing for TTS
3. Tiered voice quality (cheaper voices for free tier)
4. Usage-based pricing adjustments
