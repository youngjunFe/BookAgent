# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **BookClub (북클럽)**, an AI-powered reading management Flutter app that allows users to:
- Chat with AI to create book reviews and discussion prompts
- Manage personal e-book library with reading progress tracking
- Set and track various reading goals (daily/weekly/monthly/yearly/consecutive/pages/hours)
- Chat with book characters
- Earn achievement badges for reading milestones

## Technology Stack

- **Frontend**: Flutter 3.8.1+ (cross-platform app)
- **Backend**: Node.js/Express server with OpenAI API integration
- **Database**: Supabase (PostgreSQL with real-time features)
- **State Management**: Provider pattern
- **Authentication**: Supabase Auth with Google OAuth and Apple Sign-In
- **Deployment**: Vercel (frontend), Railway (backend APIs)

## Architecture

The project follows **Feature-First Architecture**:

```
lib/
├── core/                     # Core configuration and shared services
│   ├── config/              # App configuration (Supabase, API endpoints)
│   ├── constants/           # Colors, strings, spacing, animations
│   ├── theme/               # Material Design 3 theme system
│   ├── services/            # Core services (nickname generator, time-based messages)
│   ├── supabase/           # Supabase client provider
│   └── utils/              # Utilities (web cleanup)
│
├── features/               # Feature modules
│   ├── auth/              # Authentication (Google/Apple login)
│   ├── chat/              # AI chat system with character chat
│   ├── home/              # Main dashboard
│   ├── library/           # Personal library management
│   ├── ebook/             # E-book reader and management
│   ├── review/            # Review creation with AI assistance
│   ├── reading_goals/     # Goal setting and achievement tracking
│   ├── profile/           # User profile management
│   ├── admin/             # Admin panel functionality
│   ├── splash/            # Splash screen and intro
│   ├── guest/             # Guest mode functionality
│   ├── weather/           # Weather integration
│   └── book_search/       # Book search functionality
│
└── shared/                # Shared widgets and utilities
    └── widgets/           # Reusable UI components
```

Each feature follows the **Presentation-Model** pattern:
- `presentation/`: UI pages and widgets
- `models/`: Data models and DTOs
- `services/`: Feature-specific business logic

## Key Configuration Files

- **Flutter App**: `pubspec.yaml` - Main app dependencies and configuration
- **Backend Server**: `package.json` - Node.js server with OpenAI integration
- **Supabase**: Configuration in `lib/core/config/app_config.dart`
- **Vercel**: `vercel.json` - Frontend deployment configuration
- **Railway**: Backend APIs deployment (server.js + api/ directory)

## Development Commands

### Flutter Development
```bash
# Install dependencies
flutter pub get

# Run on web (Chrome)
flutter run -d chrome

# Run on mobile (requires device/emulator)
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean
```

### Build Commands
```bash
# Web build for production
flutter build web --release

# Android APK
flutter build apk --release

# iOS build (requires macOS)
flutter build ios --release
```

### Backend Server (Node.js)
```bash
# Install server dependencies
npm install

# Start development server
npm run dev
# or
npm start
```

## Important Implementation Details

### Supabase Integration
- Client initialization in `SupabaseClientProvider`
- Authentication handled by `SupabaseAuthService`
- Graceful fallback to offline mode if Supabase unavailable
- Real-time subscriptions for live data updates

### AI Integration
- Primary AI endpoint: Vercel functions (`/api/chat`, `/api/generate-review`, `/api/character-chat`)
- Fallback Railway backend server for redundancy
- OpenAI GPT integration for chat and review generation
- Character-based chat with personality prompts

### Multi-platform Deployment
- **Web**: Vercel static hosting with SPA routing
- **Mobile**: Standard Flutter mobile builds
- **Backend**: Railway for API endpoints with Express server

### Database Schema
The app uses Supabase with the following key tables:
- User profiles with nickname generation
- Reading goals with various types and progress tracking
- Achievement system with badge categories
- Chat history and review storage

### Authentication Flow
1. Splash screen with intro
2. Login page with Google/Apple OAuth
3. Profile setup with auto-generated Korean nicknames
4. Main navigation with bottom tabs

### Error Handling
- Graceful degradation when APIs are unavailable
- Fallback between Vercel and Railway backends
- Offline-first approach for core functionality
- User-friendly error messages throughout

## Environment Setup

The app requires:
- **Supabase**: Database URL and anon key (hardcoded in app_config.dart)
- **OpenAI API**: Key for AI functionality (server environment)
- **Google OAuth**: Client IDs for authentication
- **Apple Sign-In**: Configured for iOS authentication

## Testing
- Unit tests in `test/` directory
- Widget tests for UI components
- Integration tests for full user flows
- Manual testing scenarios documented in `test_scenario.md`

## Deployment Notes

### Vercel (Frontend)
- Automatic deployment from main branch
- Static site with SPA routing configuration
- Build command: `flutter build web --release`

### Railway (Backend)
- Node.js server with OpenAI integration
- Auto-deployment from repository
- Environment variables for API keys

### Database Migrations
Multiple SQL migration files exist for Supabase schema updates. Check files matching patterns like `*_FIX.sql`, `*_SETUP.sql` for database schema evolution.