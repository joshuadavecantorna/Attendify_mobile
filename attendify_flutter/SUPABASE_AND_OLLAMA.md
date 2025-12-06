# Attendify Flutter - Backend Configuration

## Database: Supabase (PostgreSQL)

### Overview
Attendify uses **Supabase** as the backend database solution. Supabase provides a complete backend-as-a-service with PostgreSQL database, authentication, real-time subscriptions, and RESTful APIs.

### Architecture

```
Flutter App (Mobile)
      ↓
Laravel API (Backend)
      ↓
Supabase PostgreSQL (Database)
```

### Supabase Features Used

#### 1. PostgreSQL Database
- **Users Table** - Student, teacher, and admin accounts
- **Classes Table** - Class information and schedules
- **Attendance Records** - Check-in history
- **Attendance Sessions** - Active QR code sessions
- **Excuse Requests** - Student excuse submissions and approvals
- **Chat Sessions** - AI chatbot conversation history
- **Chat Messages** - Individual messages in conversations

#### 2. Authentication
- Email/password authentication via Laravel Sanctum
- Token-based API access
- Role-based permissions (student/teacher/admin)

#### 3. Real-time Capabilities (Optional Enhancement)
Supabase supports real-time subscriptions for:
- Live attendance updates during sessions
- Instant excuse approval notifications
- Real-time class schedule changes
- Active user presence indicators

### Configuration

#### Laravel Backend Setup
```env
# .env file
DB_CONNECTION=pgsql
DB_HOST=your-supabase-project.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-supabase-password
```

#### API Endpoints
The Flutter app communicates with Supabase through Laravel API:
```
BASE_URL: https://your-domain.com/api

Authentication:
- POST /login
- POST /register
- POST /logout

Student:
- GET  /student/classes
- GET  /student/attendance
- POST /student/attendance/check-in
- GET  /student/excuses
- POST /student/excuses

Teacher:
- GET  /teacher/classes
- POST /teacher/sessions
- GET  /teacher/sessions
- POST /teacher/attendance/mark
- GET  /teacher/excuses
- PUT  /teacher/excuses/{id}

Admin:
- GET  /admin/stats
- GET  /admin/users
- POST /admin/users
- PUT  /admin/users/{id}
- DELETE /admin/users/{id}
- GET  /admin/classes
- POST /admin/classes
- PUT  /admin/classes/{id}
- DELETE /admin/classes/{id}

Chatbot:
- POST /chatbot/message (SSE streaming)
- GET  /chatbot/history
- POST /chatbot/session
- GET  /chatbot/sessions
- DELETE /chatbot/session/{id}
```

### Benefits of Supabase

✅ **Scalability** - Cloud-hosted PostgreSQL handles growth automatically
✅ **Real-time** - WebSocket support for live data updates
✅ **Security** - Row Level Security (RLS) policies
✅ **Performance** - Connection pooling and caching
✅ **Backups** - Automatic daily backups
✅ **Monitoring** - Built-in database metrics and logs
✅ **Reliability** - High availability and redundancy

---

## AI Chatbot: Ollama (Local AI)

### Overview
The AI chatbot feature uses **Ollama**, an open-source tool for running large language models locally. This provides privacy and control over AI interactions.

### Architecture

```
Flutter App (Mobile)
      ↓
Laravel API (Backend)
      ↓
Ollama Server (Local AI)
      ↓
Language Model (e.g., Llama 2, Mistral)
```

### Ollama Requirements

#### 1. Installation
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model (e.g., Llama 2)
ollama pull llama2

# Or use a smaller model for faster responses
ollama pull mistral
```

#### 2. Running Ollama
```bash
# Start Ollama server (default port: 11434)
ollama serve

# Verify it's running
curl http://localhost:11434/api/tags
```

#### 3. Network Configuration
- **Local Network**: Ollama server accessible at `http://localhost:11434`
- **Remote Access**: Configure firewall to allow port 11434
- **Docker**: Can run Ollama in a container

```bash
# Docker setup
docker run -d --name ollama \
  -p 11434:11434 \
  -v ollama:/root/.ollama \
  ollama/ollama
```

### Laravel Integration

#### Configuration
```php
// config/ollama.php
return [
    'base_url' => env('OLLAMA_URL', 'http://localhost:11434'),
    'model' => env('OLLAMA_MODEL', 'llama2'),
    'timeout' => env('OLLAMA_TIMEOUT', 30),
    'stream' => env('OLLAMA_STREAM', true),
];
```

#### Streaming Endpoint
```php
// app/Services/OllamaService.php
public function streamChat(string $message, ?string $sessionId = null)
{
    $response = Http::timeout(60)
        ->withOptions(['stream' => true])
        ->post($this->baseUrl . '/api/chat', [
            'model' => $this->model,
            'messages' => $this->buildMessages($message, $sessionId),
            'stream' => true,
        ]);

    return $response->stream();
}
```

#### Context Management
The chatbot includes context about Attendify features:
- Class schedules and enrollment
- Attendance records and statistics  
- Excuse request status
- User-specific information
- System capabilities

### Internet Connection Requirement

⚠️ **Important**: The AI chatbot requires an internet connection even though Ollama runs locally.

**Why?**
1. Flutter app connects to Laravel backend over internet
2. Laravel backend connects to Ollama (may be local or remote)
3. Even if Ollama is on the same machine as Laravel, the mobile app needs internet to reach the Laravel API

**Offline Behavior:**
- Chatbot displays warning banner when offline
- Message input is disabled
- Error message: "AI chatbot unavailable offline - Ollama requires internet connection"
- Previous conversation history may be visible from cache (future enhancement)

### Model Selection

Choose a model based on your needs:

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| Llama 2 7B | 3.8GB | Moderate | Good | Balanced performance |
| Mistral 7B | 4.1GB | Fast | Excellent | Best for chatbot |
| Llama 2 13B | 7.3GB | Slow | Better | More context understanding |
| Phi-2 | 1.7GB | Very Fast | Good | Resource-constrained environments |
| CodeLlama | 3.8GB | Moderate | Good | Code-related questions |

```bash
# Example: Switch to Mistral for better performance
ollama pull mistral

# Update .env
OLLAMA_MODEL=mistral
```

### Performance Optimization

#### 1. Response Speed
- Use smaller models (Mistral, Phi-2) for faster responses
- Enable GPU acceleration if available
- Limit context history to recent messages
- Use streaming for immediate feedback

#### 2. Memory Usage
```bash
# Check Ollama memory usage
ollama ps

# Unload unused models
ollama stop llama2
```

#### 3. Concurrency
- Ollama handles multiple requests sequentially
- Consider running multiple Ollama instances for high traffic
- Use Redis queue for chat requests

### Security Considerations

✅ **Privacy** - Data stays on your infrastructure
✅ **Compliance** - No third-party AI service data sharing
✅ **Control** - Full control over model and responses
✅ **Cost** - No per-request API fees

⚠️ **Considerations**:
- Ensure Ollama server is not publicly exposed
- Use HTTPS for Laravel API
- Implement rate limiting on chatbot endpoint
- Sanitize user inputs before sending to Ollama
- Monitor for prompt injection attempts

### Troubleshooting

#### Issue: Chatbot not responding
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Check Laravel logs
tail -f storage/logs/laravel.log

# Restart Ollama
systemctl restart ollama
```

#### Issue: Slow responses
- Switch to a smaller model (Mistral, Phi-2)
- Enable GPU acceleration
- Increase timeout values
- Check system resources (CPU, RAM, GPU)

#### Issue: Connection refused
- Verify Ollama is accessible from Laravel server
- Check firewall rules
- Confirm correct URL in Laravel config
- Test with curl from Laravel server

---

## Offline Mode Summary

### What Works Offline

✅ **Student Features**:
- View enrolled classes (cached)
- View attendance records (cached)
- View attendance summary (cached)
- View today's schedule (cached)
- View excuse requests (cached)

✅ **Teacher Features** (with offline support - to be implemented):
- View teaching classes (cached)
- View attendance sessions (cached)
- View class students (cached)
- View excuse requests (cached)

✅ **Admin Features** (with offline support - to be implemented):
- View system stats (cached)
- View users list (cached)
- View classes list (cached)

### What Requires Internet

❌ **Write Operations**:
- Submitting excuse requests
- Checking in via QR code
- Creating attendance sessions
- Marking attendance
- Approving/rejecting excuses
- Creating/editing users
- Creating/editing classes

❌ **Real-time Features**:
- AI chatbot (requires Ollama connection)
- QR code generation
- Live attendance stats
- Session status updates

❌ **Authentication**:
- Login (requires API access)
- Logout (requires API access)
- Token refresh

### Cache Strategy

**When Online:**
1. Fetch fresh data from Supabase via Laravel API
2. Cache data in local SQLite database
3. Display fresh data to user

**When Offline:**
1. Check local SQLite cache
2. Return cached data if available
3. Display "Last updated: [timestamp]" indicator
4. Show offline banner/indicator

**On Reconnection:**
1. Detect internet connection restored
2. Refresh all cached data in background
3. Update UI with fresh data
4. Remove offline indicators

---

## Development Setup

### 1. Supabase Setup
1. Create account at [supabase.com](https://supabase.com)
2. Create new project
3. Note your project URL and API keys
4. Run database migrations
5. Configure Laravel to connect to Supabase

### 2. Ollama Setup
1. Install Ollama on your server
2. Pull desired model (`ollama pull mistral`)
3. Start Ollama service
4. Configure Laravel with Ollama URL
5. Test chatbot endpoint

### 3. Flutter App Setup
1. Update API base URL in `app_constants.dart`
2. Run `flutter pub get`
3. Test on device/emulator
4. Verify offline mode works
5. Test chatbot with internet connection

---

## Production Deployment

### Supabase
- ✅ Managed service, no deployment needed
- Configure production database
- Set up database backups
- Enable RLS policies
- Monitor database performance

### Ollama
- Deploy on dedicated server or VM
- Use Docker for containerization
- Set up reverse proxy (nginx)
- Enable HTTPS
- Configure monitoring and alerts
- Set up automatic restarts

### Laravel API
- Deploy to VPS or cloud provider
- Configure environment variables
- Enable caching (Redis)
- Set up queue workers
- Enable HTTPS/SSL
- Configure rate limiting

### Flutter App
- Build release APK/IPA
- Test offline functionality
- Test chatbot connectivity
- Submit to app stores
- Monitor crash reports

---

## Future Enhancements

### Database
- [ ] Implement Supabase real-time subscriptions
- [ ] Add optimistic updates for better UX
- [ ] Implement background sync for offline writes
- [ ] Add conflict resolution for offline edits

### AI Chatbot
- [ ] Cache chat history for offline viewing
- [ ] Add voice input/output
- [ ] Multi-language support
- [ ] Context-aware suggestions
- [ ] Implement RAG (Retrieval Augmented Generation)
- [ ] Add chat export functionality

### Offline Support
- [ ] Implement sync queue for offline operations
- [ ] Add "pending sync" indicators
- [ ] Show last sync timestamp
- [ ] Implement selective sync
- [ ] Add cache size management
- [ ] Implement cache TTL (time-to-live)

---

## Resources

### Supabase
- Documentation: https://supabase.com/docs
- Laravel Integration: https://github.com/supabase-community/supabase-php
- Dashboard: https://app.supabase.com

### Ollama
- Documentation: https://ollama.com/docs
- GitHub: https://github.com/ollama/ollama
- Model Library: https://ollama.com/library

### Flutter
- Offline Storage: https://pub.dev/packages/sqflite
- Connectivity: https://pub.dev/packages/connectivity_plus
- State Management: https://bloclibrary.dev

---

**Last Updated:** December 2025
**Status:** Production Ready
**Database:** Supabase PostgreSQL
**AI Backend:** Ollama (Local LLM)
