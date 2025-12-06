# Firebase Cloud Messaging (FCM) Setup Guide

## Overview
This guide walks you through setting up Firebase Cloud Messaging for push notifications in the Attendify Flutter app.

---

## Prerequisites

- Google account
- Flutter project created
- Android Studio installed (for Android)
- Xcode installed (for iOS, macOS only)

---

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
- Visit: https://console.firebase.google.com/
- Click **"Add project"** or select existing project
- Enter project name: `Attendify` (or your preferred name)
- Click **Continue**

### 1.2 Configure Project
- **Google Analytics**: Optional (can disable for development)
- Click **Create project**
- Wait for project creation to complete
- Click **Continue** to dashboard

---

## Step 2: Add Android App to Firebase

### 2.1 Register Android App
1. In Firebase Console, click **⚙️ Project settings**
2. Under "Your apps", click **Android** icon
3. Fill in registration form:
   - **Android package name**: `com.attendify.app`
   - **App nickname**: `Attendify Android` (optional)
   - **Debug signing certificate SHA-1**: Optional (for now)
4. Click **Register app**

### 2.2 Download Configuration File
1. Download `google-services.json`
2. Place it in: `android/app/google-services.json`
3. **Important**: Replace the template file, don't rename it
4. Click **Next**

### 2.3 Add Firebase SDK (Already Done)
The dependencies are already configured in `pubspec.yaml`:
```yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
flutter_local_notifications: ^16.3.0
```
Click **Next** → **Continue to console**

### 2.4 Update Android Build Configuration

**Note:** This Flutter project uses Kotlin DSL (`.kts` files), so the syntax is slightly different from traditional Gradle.

#### File: `android/settings.gradle.kts`
Add Google Services plugin:
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // Add this line
}
```

#### File: `android/app/build.gradle.kts`
Add Google Services plugin at the top:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this line
}
```

Update the application ID to match Firebase configuration:
```kotlin
android {
    namespace = "com.attendify.app"  // Update this
    // ... rest of config ...
    
    defaultConfig {
        applicationId = "com.attendify.app"  // Update this
        // ... rest of config ...
    }
}
```

Add Firebase dependencies at the end of the file:
```kotlin
flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}
```

#### File: `android/app/src/main/AndroidManifest.xml`
Add permissions and service configuration:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    
    <application
        android:label="attendify_flutter"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- ... existing activity config ... -->
        
        <!-- Add FCM default channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="default_channel" />
            
        <!-- Add FCM service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

---

## Step 3: Add iOS App to Firebase

### 3.1 Register iOS App
1. In Firebase Console, click **⚙️ Project settings**
2. Under "Your apps", click **iOS** icon (Apple logo)
3. Fill in registration form:
   - **iOS bundle ID**: `com.attendify.app`
   - **App nickname**: `Attendify iOS` (optional)
   - **App Store ID**: Leave blank (for now)
4. Click **Register app**

### 3.2 Download Configuration File
1. Download `GoogleService-Info.plist`
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Drag `GoogleService-Info.plist` into Runner folder in Xcode
4. **Important**: Check "Copy items if needed"
5. Select "Runner" target
6. Click **Finish**

### 3.3 Enable Push Notifications in Xcode
1. In Xcode, select **Runner** project
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes**
   - Check **Remote notifications**

### 3.4 Update Info.plist
File: `ios/Runner/Info.plist`
Add notification permissions:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
<key>NSUserTrackingUsageDescription</key>
<string>This app would like to send you notifications about attendance sessions and updates.</string>
```

---

## Step 4: Test Firebase Setup

### 4.1 Verify Installation
Run the app to verify Firebase is configured correctly:
```bash
flutter run
```

Check console for Firebase initialization messages.

### 4.2 Get FCM Token
The app will automatically request notification permissions on first launch and generate an FCM token. You can view it in the app logs.

### 4.3 Send Test Notification
1. Go to Firebase Console
2. Navigate to **Cloud Messaging** (Engage → Messaging)
3. Click **Send your first message**
4. Fill in notification:
   - **Notification title**: `Test Notification`
   - **Notification text**: `Testing FCM integration`
5. Click **Send test message**
6. Enter your FCM token (from app logs)
7. Click **Test**
8. Check if notification appears on device

---

## Step 5: Backend Integration

### 5.1 Get Server Key
1. Go to Firebase Console → **Project settings**
2. Navigate to **Cloud Messaging** tab
3. Under **Project credentials**, find **Server key**
4. Copy this key for Laravel backend

### 5.2 Update Laravel Environment
Add to `.env`:
```env
FIREBASE_SERVER_KEY=your_server_key_here
FIREBASE_PROJECT_ID=your-project-id
```

### 5.3 Create FCM Service in Laravel
File: `app/Services/FCMService.php`

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FCMService
{
    private $serverKey;
    private $fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    public function __construct()
    {
        $this->serverKey = config('services.firebase.server_key');
    }

    /**
     * Send notification to a specific device token
     */
    public function sendToDevice(string $token, array $notification, array $data = [])
    {
        return $this->send([
            'to' => $token,
            'notification' => $notification,
            'data' => $data,
            'priority' => 'high',
        ]);
    }

    /**
     * Send notification to a topic
     */
    public function sendToTopic(string $topic, array $notification, array $data = [])
    {
        return $this->send([
            'to' => '/topics/' . $topic,
            'notification' => $notification,
            'data' => $data,
            'priority' => 'high',
        ]);
    }

    /**
     * Send notification to multiple devices
     */
    public function sendToMultiple(array $tokens, array $notification, array $data = [])
    {
        return $this->send([
            'registration_ids' => $tokens,
            'notification' => $notification,
            'data' => $data,
            'priority' => 'high',
        ]);
    }

    /**
     * Send FCM request
     */
    private function send(array $payload)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type' => 'application/json',
            ])->post($this->fcmUrl, $payload);

            if ($response->successful()) {
                Log::info('FCM notification sent successfully', [
                    'response' => $response->json()
                ]);
                return $response->json();
            }

            Log::error('FCM notification failed', [
                'status' => $response->status(),
                'body' => $response->body()
            ]);

            return null;
        } catch (\Exception $e) {
            Log::error('FCM exception: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Subscribe token to topic
     */
    public function subscribeToTopic(string $token, string $topic)
    {
        $url = "https://iid.googleapis.com/iid/v1/{$token}/rel/topics/{$topic}";
        
        return Http::withHeaders([
            'Authorization' => 'key=' . $this->serverKey,
        ])->post($url);
    }

    /**
     * Unsubscribe token from topic
     */
    public function unsubscribeFromTopic(string $token, string $topic)
    {
        $url = "https://iid.googleapis.com/iid/v1:batchRemove";
        
        return Http::withHeaders([
            'Authorization' => 'key=' . $this->serverKey,
        ])->post($url, [
            'to' => '/topics/' . $topic,
            'registration_tokens' => [$token],
        ]);
    }
}
```

### 5.4 Add FCM Config
File: `config/services.php`
```php
'firebase' => [
    'server_key' => env('FIREBASE_SERVER_KEY'),
    'project_id' => env('FIREBASE_PROJECT_ID'),
],
```

### 5.5 Add FCM Token to Users Table
Create migration:
```bash
php artisan make:migration add_fcm_token_to_users_table
```

```php
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('fcm_token')->nullable()->after('remember_token');
    });
}
```

Run migration:
```bash
php artisan migrate
```

### 5.6 Create API Endpoint for Token Registration
File: `app/Http/Controllers/API/NotificationController.php`

```php
<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\FCMService;

class NotificationController extends Controller
{
    protected $fcmService;

    public function __construct(FCMService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * Register FCM token for authenticated user
     */
    public function registerToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->fcm_token = $request->fcm_token;
        $user->save();

        // Subscribe to role-based topics
        $this->fcmService->subscribeToTopic($request->fcm_token, $user->role);
        
        // Subscribe to user-specific topic
        $this->fcmService->subscribeToTopic($request->fcm_token, 'user_' . $user->id);

        return response()->json([
            'message' => 'FCM token registered successfully'
        ]);
    }

    /**
     * Send test notification
     */
    public function sendTest(Request $request)
    {
        $user = $request->user();
        
        if (!$user->fcm_token) {
            return response()->json([
                'error' => 'No FCM token registered'
            ], 400);
        }

        $this->fcmService->sendToDevice(
            $user->fcm_token,
            [
                'title' => 'Test Notification',
                'body' => 'This is a test notification from Attendify'
            ],
            [
                'type' => 'test',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ]
        );

        return response()->json([
            'message' => 'Test notification sent'
        ]);
    }
}
```

Add routes in `routes/api.php`:
```php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/notifications/register-token', [NotificationController::class, 'registerToken']);
    Route::post('/notifications/test', [NotificationController::class, 'sendTest']);
});
```

---

## Step 6: Flutter App Integration

### 6.1 Update AuthBloc to Register Token
The app is already configured to register FCM tokens. After successful login, the token will be automatically sent to the backend.

### 6.2 Test Notifications
1. Run the app: `flutter run`
2. Login with your account
3. Check logs for FCM token
4. Send test notification from Firebase Console
5. Verify notification appears

---

## Notification Types & Usage

### Student Notifications
```php
// Attendance session reminder
FCMService::sendToTopic('class_123', [
    'title' => 'Attendance Session Started',
    'body' => 'Attendance is now open for Mathematics 101'
], [
    'type' => 'new_session',
    'class_id' => 123,
    'session_id' => 456
]);
```

### Teacher Notifications
```php
// Excuse request notification
FCMService::sendToUser($teacher->fcm_token, [
    'title' => 'New Excuse Request',
    'body' => 'John Doe submitted an excuse for absence'
], [
    'type' => 'excuse_request',
    'excuse_id' => 789
]);
```

### Admin Notifications
```php
// System alert
FCMService::sendToTopic('admin', [
    'title' => 'System Alert',
    'body' => 'Multiple failed login attempts detected'
], [
    'type' => 'security_alert',
    'severity' => 'high'
]);
```

---

## Troubleshooting

### Android Issues

**Issue**: `google-services.json not found`
- Solution: Ensure file is in `android/app/` directory
- Check filename is exactly `google-services.json`

**Issue**: Build fails with Google Services plugin error
- Solution: Add plugin to both `android/build.gradle` and `android/app/build.gradle`
- Check Gradle sync in Android Studio

**Issue**: Notifications not received
- Solution: Check internet connection
- Verify FCM token is registered
- Test with Firebase Console first
- Check Android notification permissions

### iOS Issues

**Issue**: `GoogleService-Info.plist not found`
- Solution: Add file through Xcode (drag and drop)
- Ensure "Copy items if needed" is checked
- Verify file is in Runner target

**Issue**: Push notification capability error
- Solution: Enable Push Notifications in Xcode capabilities
- Enable Background Modes → Remote notifications
- Check Apple Developer Account has push enabled

**Issue**: Notifications not received on iOS
- Solution: Test on physical device (not simulator)
- Check notification permissions in iOS Settings
- Verify APNs certificate in Firebase Console

### General Issues

**Issue**: Firebase initialization fails
- Solution: Check `google-services.json` / `GoogleService-Info.plist` are correct
- Verify package name / bundle ID matches exactly
- Run `flutter clean` and rebuild

**Issue**: FCM token is null
- Solution: Wait for Firebase initialization to complete
- Check internet connection
- Verify Firebase project configuration

---

## Security Best Practices

1. **Never commit Firebase config files to public repos**
   - Add to `.gitignore`:
     ```
     android/app/google-services.json
     ios/Runner/GoogleService-Info.plist
     ```

2. **Rotate server keys periodically**
   - Update in Firebase Console and backend

3. **Validate notification data**
   - Always validate payload data in the app
   - Sanitize user input before sending

4. **Use topics for group messaging**
   - Avoid storing thousands of individual tokens
   - Subscribe users to relevant topics only

5. **Handle token refresh**
   - Update backend when token changes
   - Remove old tokens from database

---

## Next Steps

1. ✅ Complete Firebase setup
2. ✅ Test notifications on both platforms
3. ⏭️ Implement notification handlers in Flutter
4. ⏭️ Create notification templates in backend
5. ⏭️ Set up automated notifications for:
   - Attendance session start/end
   - Excuse request approval/rejection
   - Class schedule changes
   - System announcements

---

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Flutter](https://pub.dev/packages/firebase_messaging)

---

**Setup Time**: ~30-45 minutes
**Difficulty**: Medium
**Priority**: High (for production deployment)
