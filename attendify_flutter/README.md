# Attendify Flutter - Mobile Application

Flutter mobile application for the Attendify attendance management system with Supabase backend and Ollama AI integration.

## Features

- 🔐 **Authentication**: Login/register with role-based access (Student/Teacher/Admin)
- 📱 **Role-Based Dashboards**: Customized interfaces for each user type
- 📊 **Attendance Management**: Mark, track, and analyze attendance
- 📅 **Schedule Management**: View class schedules and upcoming sessions
- 📝 **Excuse Requests**: Submit and manage absence excuses
- 🤖 **AI Chatbot**: Integrated Ollama-powered chatbot for quick queries (requires internet)
- 📱 **QR Code Scanning**: Quick attendance check-in via QR codes
- 🔔 **Push Notifications**: Real-time alerts and reminders (FCM)
- 📴 **Offline Support**: Works offline with local SQLite caching for read operations
- ☁️ **Supabase Backend**: Cloud PostgreSQL database for scalability and real-time capabilities

## Tech Stack

### Frontend
- **Framework**: Flutter 3.10+
- **State Management**: flutter_bloc (BLoC pattern)
- **Networking**: Dio + Retrofit
- **Local Storage**: flutter_secure_storage, shared_preferences, sqflite
- **Navigation**: go_router
- **QR Scanning**: qr_code_scanner, qr_flutter
- **Notifications**: Firebase Cloud Messaging
- **UI**: Material Design 3

### Backend
- **Database**: Supabase (PostgreSQL)
- **API**: Laravel 11
- **Authentication**: Laravel Sanctum
- **AI**: Ollama (Local LLM)
- **Real-time**: Supabase Realtime (optional)

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Mobile)       │
└────────┬────────┘
         │
         │ HTTPS/REST
         │
┌────────▼────────┐
│  Laravel API    │
│  (Backend)      │
└────┬───────┬────┘
     │       │
     │       │ Streaming SSE
     │       │
     │       ├──────────┐
     │       │          │
┌────▼───────▼──┐  ┌───▼──────┐
│   Supabase    │  │  Ollama  │
│  PostgreSQL   │  │ (Local)  │
└───────────────┘  └──────────┘
```

## Setup Instructions

### Prerequisites

- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for mobile development
- **Laravel backend** with Supabase connection
- **Ollama** installed and running (for AI chatbot)

### Installation

1. **Navigate to Flutter project**:
   ```bash
   cd attendify_flutter
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**:
   Edit `lib/core/constants/app_constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-api-url:8000'; // Update this
   ```

4. **Set up Backend (Laravel + Supabase)**:
   See [SUPABASE_AND_OLLAMA.md](SUPABASE_AND_OLLAMA.md) for detailed setup instructions:
   - Create Supabase project
   - Configure Laravel to connect to Supabase PostgreSQL
   - Run database migrations
   - Start Laravel API server

5. **Set up Ollama (AI Chatbot)**:
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.com/install.sh | sh
   
   # Pull a model (Mistral recommended for best performance)
   ollama pull mistral
   
   # Start Ollama server
   ollama serve
   ```
   
   Configure Laravel `.env`:
   ```env
   OLLAMA_URL=http://localhost:11434
   OLLAMA_MODEL=mistral
   ```

6. **Firebase Setup (Push Notifications)**:
   - Create Firebase project
   - Add Android/iOS apps
   - Download `google-services.json` and `GoogleService-Info.plist`
   - Place in `android/app/` and `ios/Runner/` respectively

7. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants
│   ├── theme/          # Theme configuration
│   ├── network/        # API client setup
│   ├── database/       # SQLite database helper
│   ├── services/       # Offline, connectivity, notification services
│   ├── models/         # Shared data models
│   └── utils/          # Utility functions
├── features/
│   ├── auth/           # Authentication feature
│   │   ├── bloc/       # BLoC state management
│   │   ├── data/       # Repository & data sources
│   │   └── presentation/ # UI screens
│   ├── student/        # Student-specific features
│   ├── teacher/        # Teacher-specific features
│   ├── admin/          # Admin-specific features
│   └── chatbot/        # AI chatbot feature (Ollama-powered)
└── main.dart           # App entry point
```

## Backend Architecture

### Database: Supabase PostgreSQL
- Cloud-hosted PostgreSQL database
- Scalable and reliable
- Real-time subscriptions support
- Automatic backups
- See [SUPABASE_AND_OLLAMA.md](SUPABASE_AND_OLLAMA.md) for details

### AI Chatbot: Ollama
- Runs locally for privacy and control
- **Requires internet connection** to reach Laravel API
- Supports multiple models (Mistral, Llama 2, etc.)
- Streaming responses via SSE
- Context-aware answers about attendance, classes, and schedules

### Offline Support
- **Read Operations**: Cached locally in SQLite when offline
  - View classes, attendance records, schedules
  - View excuse requests and history
  - Browse cached data with "offline" indicator
  
- **Write Operations**: Require internet connection
  - Submit excuse requests
  - QR code check-in
  - Create attendance sessions
  - User/class management

- **AI Chatbot**: Requires internet (displays offline banner)

See [OFFLINE_AND_NOTIFICATIONS.md](OFFLINE_AND_NOTIFICATIONS.md) for implementation details.

## Current Status

✅ **Complete (97%)**:
- ✅ Project structure and core infrastructure
- ✅ Authentication with BLoC pattern and role-based routing
- ✅ Student module (dashboard, QR scanner, classes, excuses)
- ✅ Teacher module (dashboard, sessions, QR display, excuse approval)
- ✅ Admin module (dashboard, user management, class management)
- ✅ AI Chatbot with Ollama streaming integration
- ✅ Offline support with SQLite caching
- ✅ Connectivity monitoring with real-time indicators

🔄 **In Progress (3%)**:
- Push notifications (FCM infrastructure ready, needs Firebase config)
- Extended offline support for teacher/admin repositories
- Testing and polish

## Documentation

- **[SUPABASE_AND_OLLAMA.md](SUPABASE_AND_OLLAMA.md)** - Backend setup and configuration
- **[OFFLINE_AND_NOTIFICATIONS.md](OFFLINE_AND_NOTIFICATIONS.md)** - Offline mode and push notifications
- **[PROGRESS.md](PROGRESS.md)** - Detailed development progress and statistics

## Key Features Explained

### 🔐 Authentication
- Email/password login via Laravel Sanctum
- Role selection: Student, Teacher, or Admin
- Secure token storage with flutter_secure_storage
- Automatic token refresh

### 📴 Offline Mode
- Automatic cache of data from Supabase
- Seamless fallback to cached data when offline
- Real-time connectivity status indicator
- Smart sync when connection restored

### 🤖 AI Chatbot (Ollama)
- Natural language queries about your attendance
- Context-aware responses using Ollama
- Streaming responses for immediate feedback
- **Note**: Requires internet connection to Laravel API

### 📱 QR Code Features
- Generate QR codes for attendance sessions (teachers)
- Scan QR codes to check in (students)
- Real-time attendance tracking

### 🔔 Push Notifications (Coming Soon)
- Attendance session reminders
- Excuse approval/rejection notifications
- Class schedule updates
- System announcements

## Next Steps

Continue development in phases as outlined in the main project README.
