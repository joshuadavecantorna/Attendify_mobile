# Attendify Flutter - Offline Support & Push Notifications

## Database Architecture

### Backend: Supabase (PostgreSQL)
This app uses **Supabase** as the backend database, which provides:
- PostgreSQL database hosted in the cloud
- Real-time subscriptions
- Row Level Security (RLS)
- RESTful API endpoints
- Authentication and user management

All data (users, classes, attendance, excuses) is stored in Supabase and accessed via API calls.

### Local: SQLite (Offline Cache)
For offline functionality, the app uses **SQLite** to cache data locally:
- Temporary storage for when internet is unavailable
- Automatic sync when connection is restored
- Read-only offline access (no local writes)

## AI Chatbot Requirements

### Ollama (Local AI Server)
The AI chatbot feature uses **Ollama** running locally, which requires:
- ✅ **Internet connection required** - Cannot function offline
- Ollama server running on your local machine or network
- Network connectivity to reach the Ollama API endpoint
- Streaming responses via Server-Sent Events (SSE)

**Note:** When offline, the chatbot will display a banner: "AI chatbot unavailable offline - Ollama requires internet connection"

---

## Offline Support Implementation

### Overview
The app now includes comprehensive offline support using SQLite database caching. This enables the app to function even when internet connectivity is limited or unavailable.

### Features

#### 1. Database Helper (`lib/core/database/database_helper.dart`)
- SQLite database initialization
- 7 tables for caching different data types:
  - `classes` - Student's enrolled classes
  - `attendance_records` - Attendance history
  - `attendance_summary` - Attendance statistics
  - `excuse_requests` - Excuse request submissions
  - `schedule` - Daily class schedule
  - `chat_messages` - Chatbot conversation history
  - `sync_queue` - Pending operations to sync when online

#### 2. Offline Service (`lib/core/services/offline_service.dart`)
High-level caching service providing:
- `cacheClasses()` / `getCachedClasses()` - Cache enrolled classes
- `cacheAttendanceRecords()` / `getCachedAttendanceRecords()` - Cache attendance history
- `cacheAttendanceSummary()` / `getCachedAttendanceSummary()` - Cache statistics
- `cacheExcuseRequests()` / `getCachedExcuseRequests()` - Cache excuse requests
- `cacheSchedule()` / `getCachedSchedule()` - Cache daily schedule
- `queueForSync()` - Queue operations for later sync
- `clearAllCache()` - Clear all cached data

#### 3. Connectivity Service (`lib/core/services/connectivity_service.dart`)
Network connectivity monitoring:
- Real-time connectivity status via `connectivityStream`
- `isOnline` property for checking current status
- `checkConnection()` for manual connectivity checks

#### 4. Repository Integration
Updated `StudentRepository` to:
- Check connectivity before API calls
- Return cached data when offline
- Cache fresh data after successful API calls
- Fall back to cache on network errors
- Block write operations when offline

### Usage Pattern

```dart
// In repository:
Future<List<ClassModel>> getStudentClasses() async {
  // 1. Check if offline
  if (!_connectivityService.isOnline) {
    return getCachedData();
  }
  
  // 2. Fetch from API
  final response = await _dioClient.get('/student/classes');
  
  // 3. Cache the fresh data
  await _offlineService.cacheClasses(response.data);
  
  return parseData(response.data);
}
```

### Benefits
- ✅ App works with poor connectivity
- ✅ View classes, attendance, and schedule offline
- ✅ Automatic fallback to cache on errors
- ✅ Seamless online/offline transitions
- ✅ Reduced server load and bandwidth usage

---

## Push Notifications Implementation

### Overview
Firebase Cloud Messaging (FCM) integration for real-time notifications about attendance sessions, excuse approvals, and system updates.

### Features

#### Notification Service (`lib/core/services/notification_service.dart`)
Comprehensive notification handling:
- FCM initialization and permission requests
- Foreground message handling with local notifications
- Background message processing
- Topic subscriptions for group notifications
- Local notification display
- Notification tap navigation

#### Notification Types
1. **Attendance Reminders** - Notify students of upcoming sessions
2. **Excuse Status** - Approved/rejected excuse request notifications
3. **New Sessions** - Teachers create new attendance sessions
4. **Class Updates** - Changes to class schedule or details
5. **System Announcements** - Admin broadcasts

#### Key Methods
```dart
// Get FCM token for device
String? token = await NotificationService.instance.getToken();

// Subscribe to topics
await NotificationService.instance.subscribeToTopic('student_123');
await NotificationService.instance.subscribeToTopic('class_456');

// Schedule local notifications
await NotificationService.instance.scheduleLocalNotification(
  title: 'Attendance Reminder',
  body: 'Your class starts in 15 minutes!',
  scheduledTime: DateTime.now().add(Duration(minutes: 15)),
);
```

#### Notification Channels
- **Default Channel** - General notifications
- **Scheduled Channel** - Time-based reminders

### Backend Integration Required

#### 1. Store FCM Tokens
After user login, send FCM token to backend:
```dart
final token = await NotificationService.instance.getToken();
await authRepository.updateFcmToken(token);
```

Backend should store this in `users` table:
```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255);
```

#### 2. Send Notifications from Backend
Use Firebase Admin SDK to send notifications:

```php
// When teacher creates attendance session
FCMService::sendToTopic('class_' . $classId, [
    'type' => 'new_session',
    'title' => 'New Attendance Session',
    'body' => 'Attendance is now open for ' . $className,
    'class_id' => $classId,
    'session_id' => $sessionId,
]);

// When excuse is approved/rejected
FCMService::sendToUser($studentId, [
    'type' => 'excuse_' . $status,
    'title' => 'Excuse Request ' . ucfirst($status),
    'body' => 'Your excuse for ' . $date . ' was ' . $status,
    'excuse_id' => $excuseId,
]);
```

#### 3. Topic Management
Subscribe users to relevant topics:
- Students: `student_{user_id}`, `class_{class_id}` for each enrolled class
- Teachers: `teacher_{user_id}`, `class_{class_id}` for each teaching class
- Admins: `admin`, `system`

### Firebase Setup Steps

#### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project or select existing
3. Add Android app with package name: `com.attendify.app`
4. Add iOS app with bundle ID: `com.attendify.app`
5. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

#### 2. Add Configuration Files
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

#### 3. Update Android Configuration
In `android/app/build.gradle`:
```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

In `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Apply plugin in `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### 4. Update iOS Configuration
No additional setup needed, GoogleService-Info.plist is sufficient.

#### 5. Notification Permissions
Android: Automatic for API < 33
iOS: Requested automatically on first launch

---

## Testing Offline Features

### 1. Test Offline Mode
```bash
# Enable airplane mode on device/emulator
# Open app and navigate to dashboard
# Verify cached data is displayed
# Try to submit excuse (should show error)
```

### 2. Test Cache Updates
```bash
# With internet on, view classes
# Turn off internet
# Navigate away and back
# Verify same data is shown from cache
```

### 3. Test Connectivity Transitions
```bash
# Start with internet on
# Navigate around the app
# Turn off internet mid-session
# Verify graceful fallback to cache
# Turn internet back on
# Verify automatic refresh
```

## Testing Push Notifications

### 1. Test FCM Token
```dart
// In a test screen, print the token:
final token = await NotificationService.instance.getToken();
print('FCM Token: $token');
```

### 2. Send Test Notification
Use Firebase Console:
1. Go to Cloud Messaging
2. Send test message
3. Paste FCM token
4. Send notification
5. Verify app receives and displays it

### 3. Test Notification Tap
Send notification with data payload:
```json
{
  "notification": {
    "title": "Test",
    "body": "Tap to test navigation"
  },
  "data": {
    "type": "new_session",
    "class_id": "123"
  }
}
```
Tap notification and verify correct screen opens.

---

## Next Steps

### For Complete Implementation:
1. ✅ Database helper created
2. ✅ Offline service implemented
3. ✅ Connectivity monitoring added
4. ✅ Student repository updated with offline support
5. ⏳ Update Teacher repository with offline support
6. ⏳ Update Admin repository with offline support
7. ⏳ Update Chat repository with offline support
8. ⏳ Add Firebase configuration files
9. ⏳ Implement FCM token registration in AuthBloc
10. ⏳ Build backend FCM service
11. ⏳ Add notification navigation handlers
12. ⏳ Test all offline scenarios
13. ⏳ Test all notification types

---

## Dependencies Added
```yaml
# In pubspec.yaml
connectivity_plus: ^5.0.2        # Network connectivity monitoring
firebase_core: ^2.24.2           # Firebase initialization
firebase_messaging: ^14.7.10     # Push notifications
flutter_local_notifications: ^16.3.0  # Local notifications
path: ^1.8.3                     # Path utilities for database
```

## Performance Considerations

### Database Size
- Cache is cleared and refreshed on each API call
- Old data is automatically overwritten
- Consider implementing TTL (time-to-live) for cache entries
- Add periodic cleanup for old chat messages

### Sync Strategy
- Current: Optimistic caching (cache after successful API call)
- Future enhancement: Background sync queue for offline operations
- Implement retry logic for failed sync operations

### Memory Usage
- Database operations are asynchronous
- Large result sets should be paginated
- Consider implementing lazy loading for chat history

---

## Troubleshooting

### Offline Mode Not Working
- Check `_connectivityService.isOnline` value
- Verify database tables are created
- Check if data was cached before going offline
- Review error logs for database errors

### Notifications Not Received
- Verify Firebase project is configured
- Check FCM token is generated and sent to backend
- Ensure notification permissions are granted
- Test with Firebase Console first
- Check background message handler is registered

### Cache Not Updating
- Verify API calls are successful
- Check cache methods are called after API success
- Review database write permissions
- Check for SQLite errors in logs
