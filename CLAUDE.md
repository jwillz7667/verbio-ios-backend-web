# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Verbio is a real-time voice translation app with three components:
- **iOS app** (`Verbio/`) — SwiftUI, MVVM + Clean Architecture, Swift 6
- **Backend API** (`verbio-backend/`) — Next.js 14, TypeScript, Prisma + PostgreSQL, deployed on Railway
- **Marketing site** (`web/`) — Next.js 15, Tailwind CSS v4, Framer Motion

## Build & Run Commands

### iOS App
```bash
xcodebuild build -scheme Verbio -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet
```
- Requires Xcode 2 / iOS 26.1 SDK
- Swift 6 language mode (warnings only, not errors)
- Only iOS 26.1 simulators available (iPhone 17 Pro, iPhone 17, iPhone Air)

### Backend
```bash
cd verbio-backend && npm run dev          # Local dev server
cd verbio-backend && npm run build        # Production build
cd verbio-backend && npm run lint         # ESLint
cd verbio-backend && npm run test         # Vitest
cd verbio-backend && npm run test:coverage
cd verbio-backend && npx prisma studio    # DB GUI
cd verbio-backend && npx prisma migrate dev  # Run migrations
cd verbio-backend && npx prisma generate  # Regenerate client
```

### Web Landing Page
```bash
cd web && npm run dev    # Dev with Turbopack
cd web && npm run build  # Production build
cd web && npm run lint
```

## iOS Architecture

### Layer Structure
```
Verbio/
├── App/             # Entry point (VerbioApp.swift), AppConfiguration
├── Core/            # DI container, error types, extensions
├── Domain/          # Models + service protocols (business logic layer)
│   ├── Models/      # User, Conversation, Translation, Language, Subscription, SavedPhrase
│   └── Services/    # Protocol definitions (actors conforming to Sendable)
├── Data/            # Implementations (networking, repositories, StoreKit, keychain)
│   ├── Network/     # NetworkClient actor, APIEndpoints
│   ├── Repositories/# Protocol implementations (Auth, Translation, Conversation, Phrases, User)
│   ├── StoreKit/    # StoreKitManager actor
│   └── Local/       # KeychainService
└── Presentation/    # UI layer
    ├── Navigation/  # AppRouter (auth state, tab routing)
    ├── Screens/     # View + ViewModel pairs per screen
    ├── Components/  # Reusable UI (GlassCard, GlassButton, AudioWaveform, etc.)
    └── Theme/       # VerbioColorScheme, VerbioTypography, VerbioSpacing, Animations
```

### Key Patterns
- **DI**: `DependencyContainer` singleton with `@Injected`, `@LazyInjected`, `@OptionalInjected` property wrappers. All services registered as lazy singletons in `Container.swift`. Uses NSLock for thread safety and unlocks before calling factories to avoid deadlock.
- **ViewModels**: Always `@MainActor @Observable final class`, no Combine
- **Services**: Actor-based, conforming to `Sendable` protocols (e.g., `AudioServiceProtocol`, `TranslationServiceProtocol`)
- **Repositories**: Protocol in Data layer, wrapping `NetworkClient` calls
- **NetworkClient**: Actor with JWT auth, automatic token refresh, retry logic. Stores tokens in Keychain.
- **Onboarding state**: `@AppStorage("hasSeenOnboarding")` in AppRouter

### Design System
- Brand color: Warm Amber (#FABF24)
- Light mode: Cream background (#FFFEF7), dark mode: system black
- Glass UI via `GlassCard`, `InteractiveGlassCard`, `GlassButton` (iOS 26 glassEffect with fallback)
- Theme types: `VerbioColorScheme`, `VerbioTypography`, `VerbioSpacing`, `VerbioAnimations`

### StoreKit 2 Subscriptions
- Tiers: `.free`, `.pro`, `.premium` (iOS models)
- Product IDs: `com.verbio.app.{pro|premium}.{monthly|yearly}`
- 7-day free trial on yearly plans
- `StoreKitManager` actor in `Data/StoreKit/`

### Conversation Model
- Speaker enum: `.user` / `.other`
- Backend handles language direction flipping for OTHER speaker
- 12 supported languages: EN, ES, FR, DE, IT, PT, ZH, JA, KO, AR, HI, RU

### Sign in with Apple Flow

```
┌─────────────┐        ┌──────────────┐        ┌─────────────────┐        ┌───────────┐
│  SignInView  │───────▶│ SignInVM      │───────▶│  AuthService    │───────▶│  Backend  │
│  (button)   │        │  .signIn()   │        │  (actor)        │        │  /api/auth│
└─────────────┘        └──────────────┘        └─────────────────┘        └───────────┘
```

1. **UI → ViewModel**: `SignInViewModel.signInWithApple()` sets state to `.loading`
2. **Apple Sheet**: `AppleSignInCoordinator.signIn()` uses `ASAuthorizationController` with `CheckedContinuation` to bridge the delegate callback to async/await. Requests `.fullName` and `.email` scopes.
3. **Credential extraction** (`AuthService.signInWithApple`): Pulls `identityToken`, `authorizationCode`, `firstName`, `lastName`, `email` from `ASAuthorizationAppleIDCredential`. Name/email are only provided on **first** sign-in.
4. **Backend call** (`AuthRepository.signInWithApple`): POSTs `AppleAuthRequest` to `/api/auth/apple`
5. **Backend verification** (`apple.ts`): Fetches Apple's JWKS from `appleid.apple.com/auth/keys` (cached 1hr), verifies the identity token signature (RS256) with `jose.jwtVerify`, checks issuer/audience/expiry
6. **User upsert**: Finds user by `appleUserId` or creates new row. Updates name if provided and missing.
7. **Token generation**: Creates JWT access token (short-lived) + opaque refresh token. Refresh token hash stored in DB with a `family` UUID for rotation detection.
8. **Response**: Returns `{ user, accessToken, refreshToken, expiresIn }`
9. **Token storage** (`AuthRepository`): Saves `accessToken`, `refreshToken`, `userId`, `userEmail` to Keychain via `KeychainService`
10. **State update**: ViewModel transitions to `.authenticated(user)`

**Token refresh** (`/api/auth/refresh`):
- Refresh tokens are single-use. On each refresh, the old token is revoked and a new one is issued in the same family.
- If a revoked token is reused, **all tokens in that family are revoked** (token theft detection).
- `NetworkClient` handles refresh automatically when access token expires.

**Keychain keys**:
- `com.verbio.accessToken` / `com.verbio.refreshToken` / `com.verbio.userId` / `com.verbio.userEmail`
- Accessibility: `kSecAttrAccessibleAfterFirstUnlock` (persists across reboots)

**Startup auth check** (`AuthService.checkAuthStatus`): Loads tokens from Keychain. If access token is expired but refresh token exists, considers user authenticated (NetworkClient will handle refresh on next API call). Decodes JWT claims for user info.

**Backend env vars required**: `APPLE_SERVICE_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (ES256 PEM)

## Backend Architecture

- API routes under `src/app/api/` (Next.js App Router)
- Key routes: `/api/auth/apple`, `/api/translate`, `/api/conversations`, `/api/phrases`, `/api/user/profile`, `/api/health`
- Auth: Sign in with Apple → JWT access/refresh token rotation
- Translation: GPT-4o via OpenAI SDK with conversation context
- STT: Whisper API, TTS: ElevenLabs
- Storage: S3/R2 for audio files
- Rate limiting: Redis-based (`ioredis`)
- Validation: Zod schemas in `src/lib/validation/schemas.ts`
- Deployed on Railway (`railway.toml`)

## Known Issues

- Prisma schema subscription tiers are outdated (`BASIC`/`ENTERPRISE`) vs iOS app which uses `FREE`/`PRO`/`PREMIUM`
- DEBUG mode bypasses auth in `AppRouter.swift`
- SourceKit LSP diagnostics frequently show false "Cannot find X in scope" errors across files — these are indexing noise, not real build errors. Always verify with `xcodebuild`.

## Environment Configuration

`AppConfiguration.swift` singleton determines API base URL:
- Development: `https://verbio-ios-backend-web-production.up.railway.app`
- Staging: `https://staging-api.verbio.app`
- Production: `https://api.verbio.app`
