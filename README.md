# Secure Notes App - Flutter & Firebase

A secure note-taking application built with Flutter and Firebase that allows users to create, edit, delete, and search their personal notes with proper authentication and data isolation.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (>=3.32.8)
- Firebase account
- Android Studio / VS Code / IntelliJ IDEA

### Project Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/gopalkrushnas063/secure_notes.git
   cd secure_notes
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication with Email/Password provider
   - Enable Firestore Database
   - Register your app (Android/iOS/Web) and download the configuration files
   
   For Flutter:
   ```bash
   flutterfire configure
   ```
   This will generate `firebase_options.dart` in your `lib/` directory.

4. **Configure Firestore Rules**
   Copy the following security rules to your Firestore Console → Rules tab:
   ```javascript
    rules_version = '2';
        service cloud.firestore {
        match /databases/{database}/documents {
            match /notes/{noteId} {
            // Allow read if authenticated and document belongs to user
            allow read: if request.auth != null && 
                request.auth.uid == resource.data.user_id;
            
            // Allow write (create, update) if authenticated and document belongs to user
            allow write: if request.auth != null && (
                // For create: user_id in new data must match auth uid
                request.resource.data.user_id == request.auth.uid ||
                // For update: existing user_id must match auth uid
                resource.data.user_id == request.auth.uid
            );
            
            // Allow delete if authenticated and document belongs to user
            allow delete: if request.auth != null && 
                resource.data.user_id == request.auth.uid;
            }
        }
    }
   ```

5. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## 📱 Features

- 🔐 **Secure Authentication** - Email/password based authentication
- 📝 **CRUD Operations** - Create, Read, Update, Delete notes
- 🔍 **Search Functionality** - Real-time search by note title
- 📱 **Responsive Design** - Works on mobile and web
- 🔄 **Real-time Updates** - Notes sync instantly across devices
- 🎨 **Clean UI** - Material Design with modern aesthetics

## 🏗️ Architecture

The app follows Clean Architecture with MVVM pattern:

```
lib/
├── data/
│   ├── repositories/    # Data sources (Firebase)
│   └── services/       # Business logic
├── domain/
│   └── models/         # Entity classes
├── presentation/
│   ├── screens/        # UI pages
│   ├── view_models/    # State management
│   └── widgets/        # Reusable components
└── providers/          # Riverpod providers
```

## 🔐 Authentication Approach

### Method
- **Email/Password Authentication** using Firebase Auth
- **Session Management** with automatic token refresh
- **Secure Data Isolation** - Users can only access their own notes

### Flow
1. User signs up with email and password
2. Firebase creates a user with unique UID
3. User ID is used to tag all notes (`user_id` field)
4. Firestore rules ensure users can only access their own notes
5. Session persists until explicit logout

## 🗄️ Database Schema

### Firestore Collections

#### `notes` Collection
```javascript
{
  "id": "auto-generated-doc-id",      // Firestore document ID
  "title": "Note Title",              // Note title (string)
  "content": "Note content...",       // Note body (string)
  "created_at": Timestamp,            // Creation timestamp
  "updated_at": Timestamp,            // Last update timestamp
  "user_id": "firebase-user-uid"      // Owner's Firebase UID
}
```

#### Indexes Required
Create the following Firestore indexes:
- `notes` collection: `user_id` Ascending, `updated_at` Descending

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── data/
│   ├── repositories/
│   │   ├── auth_repository.dart       # Authentication operations
│   │   └── notes_repository.dart      # Notes CRUD operations
│   └── services/
│       └── notes_service.dart         # Notes business logic
├── domain/
│   └── models/
│       ├── note_model.dart            # Note entity
│       └── user_model.dart            # User entity
├── presentation/
│   ├── screens/
│   │   ├── auth_screen.dart           # Login/Signup screen
│   │   └── notes_screen.dart          # Main notes screen
│   ├── view_models/
│   │   ├── auth_view_model.dart       # Auth state management
│   │   └── notes_view_model.dart      # Notes state management
│   └── widgets/
│       ├── note_card.dart             # Note list item
│       └── search_bar.dart            # Search component
└── providers/
    ├── providers.dart                 # Riverpod providers
    └── auth_provider.dart             # Auth stream provider
```

## 🛠️ Dependencies

Key packages used:
- **firebase_core**: Firebase integration
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **flutter_riverpod**: State management
- **equatable**: Value equality
- **intl**: Date formatting

## ⚙️ Environment Configuration

1. **Android Setup** (`android/app/build.gradle`):
   - Add `google-services.json` to `android/app/`
   - Apply Google Services plugin

2. **iOS Setup** (`ios/Runner/`):
   - Add `GoogleService-Info.plist` via Xcode
   - Enable Keychain Sharing capability

3. **Web Setup** (`web/`):
   - Add Firebase config to `index.html`
   - Enable Firebase hosting if deploying

## 🔧 Development Commands

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/notes_repository_test.dart
```

### Integration Tests
```bash
# Run integration tests
flutter test integration_test/
```

## 🚀 Deployment

### Web Deployment
```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### App Store Deployment
1. Build release APK/IPA
2. Follow Flutter deployment guides for [Android](https://flutter.dev/docs/deployment/android) and [iOS](https://flutter.dev/docs/deployment/ios)

### Common Issues

1. **Firebase not initialized**
   ```
   Ensure firebase_options.dart exists
   Run `flutterfire configure` again
   ```

2. **Permission denied errors**
   ```
   Check Firestore security rules
   Verify user is authenticated
   ```

3. **Notes not loading**
   ```
   Check network connection
   Verify Firestore indexes are created
   ```

4. **Build errors**
   ```
   Run `flutter clean`
   Run `flutter pub get`
   Delete `pubspec.lock` and re-run
   ```

### Debug Mode
Enable verbose logging:
```dart
// In main.dart, before runApp()
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

