# Frontend - Task Management System

Flutter application with role-based dashboards and in-app notifications.

## 📦 Technologies

- **Flutter** - Cross-platform UI framework
- **http** - HTTP requests
- **flutter_secure_storage** - Secure token storage
- **provider** - State management

## 🏗️ Architecture

```
frontend/lib/
├── config/                  # Configuration files
│   ├── api_config.dart     # API endpoints
│   └── app_theme.dart      # App theme & colors
│
├── models/                  # Data models
│   ├── user_model.dart
│   ├── project_model.dart
│   ├── task_model.dart
│   └── notification_model.dart
│
├── services/                # Business logic
│   ├── storage_service.dart      # Secure storage
│   ├── api_service.dart          # HTTP client
│   ├── auth_service.dart         # Authentication
│   └── notification_service.dart # Notification polling
│
├── screens/                 # UI screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── admin/
│   │   └── admin_dashboard.dart
│   ├── manager/
│   │   └── manager_dashboard.dart
│   └── member/
│       └── member_dashboard.dart
│
└── main.dart                # App entry point
```

## 🚀 Running the App

### 1. Install Flutter
```bash
# Check Flutter installation
flutter doctor

# If not installed, visit: https://flutter.dev/docs/get-started/install
```

### 2. Get Dependencies
```bash
cd frontend
flutter pub get
```

### 3. Configure Backend URL
Edit `lib/config/api_config.dart`:

```dart
// For local development
const String baseUrl = 'http://localhost:3000/api';

// For Android emulator accessing local backend
// const String baseUrl = 'http://10.0.2.2:3000/api';

// For physical device (replace with your IP)
// const String baseUrl = 'http://192.168.1.100:3000/api';
```

### 4. Run the App
```bash
# Run on Chrome (web)
flutter run -d chrome

# Run on Android emulator
flutter run

# Run on iOS simulator (macOS only)
flutter run -d ios

# List available devices
flutter devices
```

## 🔐 Authentication Flow

```dart
// 1. User enters credentials
email: admin@123
password: admin123

// 2. Login button pressed
AuthService().login(email, password)

// 3. Backend returns JWT + user data
{
  "token": "eyJhbGciOi...",
  "user": {
    "id": "...",
    "role": "admin"
  }
}

// 4. Token and user stored securely
StorageService().saveToken(token)
StorageService().saveUser(user)

// 5. Navigate to role-based dashboard
- Admin → AdminDashboard
- Manager → ManagerDashboard
- Member → MemberDashboard
```

## 📱 Screen Hierarchy

### Login Screen
- Email and password fields
- Login button with loading state
- Demo credentials displayed
- Error handling with Snackbar

### Admin Dashboard
Features:
- Overview stats (users, projects, tasks)
- Quick actions (create user, manage projects, audit logs)
- Notification badge
- Logout button

### Manager Dashboard
Features:
- Projects managed by the user
- Task statistics
- Quick action to create tasks
- Notification badge
- Logout button

### Member Dashboard
Features:
- Tasks assigned to user
- Due today count
- Task list
- Notification badge
- Logout button

## 🔔 Notification System

### How It Works

```dart
// 1. Service starts polling on login
NotificationService().startPolling()

// 2. Polls every 15 seconds
Timer.periodic(Duration(seconds: 15), (timer) {
  fetchNotifications();
});

// 3. Fetches unread notifications
GET /api/notifications?unreadOnly=true

// 4. Displays as in-app toast/snackbar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(notification.message))
);

// 5. Marks as read when user interacts
PATCH /api/notifications/:id/read
```

### Listening to Notifications

```dart
// In any widget
final notificationService = Provider.of<NotificationService>(context);

// Listen to notification stream
notificationService.notificationStream.listen((notifications) {
  final unread = notifications.where((n) => !n.isRead).toList();
  // Update UI badge
});
```

## 🎨 Theming

Custom theme defined in `lib/config/app_theme.dart`:

### Colors by Role
```dart
Admin:   Purple (#9C27B0)
Manager: Blue   (#2196F3)
Member:  Green  (#4CAF50)
```

### Status Colors
```dart
Pending:     Orange (#FF9800)
In-Progress: Blue   (#2196F3)
Completed:   Green  (#4CAF50)
Blocked:     Red    (#F44336)
```

### Priority Colors
```dart
Low:     Gray   (#9E9E9E)
Medium:  Blue   (#2196F3)
High:    Orange (#FF9800)
Urgent:  Red    (#F44336)
```

## 🔒 Secure Storage

JWT tokens and user data are stored encrypted using `flutter_secure_storage`:

```dart
// Save
await StorageService().saveToken(token);
await StorageService().saveUser(user);

// Retrieve
final token = await StorageService().getToken();
final user = await StorageService().getUser();

// Clear (logout)
await StorageService().clearAll();
```

## 🌐 API Integration

All HTTP requests go through `ApiService`:

```dart
// Automatically includes JWT token
final api = ApiService();

// GET request
final data = await api.get(ApiEndpoints.tasks);

// POST request
final result = await api.post(
  ApiEndpoints.tasks,
  {'title': 'New Task', ...}
);

// PATCH request
await api.patch(
  ApiEndpoints.taskStatus('task_id'),
  {'status': 'completed'}
);
```

## 📐 Widget Structure

### Reusable Components

**StatCard** - Display statistics
```dart
_StatCard(
  title: 'Total Users',
  count: '10',
  icon: Icons.people,
  color: AppTheme.primaryColor,
)
```

**ActionButton** - Quick action card
```dart
_ActionButton(
  icon: Icons.add,
  title: 'Create User',
  subtitle: 'Add new user to system',
  onTap: () { ... },
)
```

## 🛠️ Development Tips

### Hot Reload
```bash
# In terminal while app is running
r  # Hot reload
R  # Hot restart (clears state)
q  # Quit
```

### Debugging
```dart
// Print to console
print('Debug: $variable');

// Debug paint (show widget boundaries)
// In terminal: p

// Performance overlay
// In terminal: P
```

### Common Issues

**Cannot connect to backend:**
```dart
// Android emulator: use 10.0.2.2 instead of localhost
const String baseUrl = 'http://10.0.2.2:3000/api';

// iOS simulator: localhost works
const String baseUrl = 'http://localhost:3000/api';

// Physical device: use computer's IP address
const String baseUrl = 'http://192.168.1.100:3000/api';
```

**FlutterSecureStorage error:**
```bash
# iOS: Add keychain entitlements (already configured)
# Android: Minimum SDK 18 (already configured)
```

**Package version conflicts:**
```bash
flutter pub upgrade
flutter clean
flutter pub get
```

## 📱 Platform Support

This app runs on:
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Android** (5.0+)
- ✅ **iOS** (11.0+)
- ✅ **macOS**
- ✅ **Windows**
- ✅ **Linux**

## 🚀 Building for Production

### Web
```bash
flutter build web
# Output in build/web/
```

### Android APK
```bash
flutter build apk
# Output in build/app/outputs/flutter-apk/
```

### iOS (macOS required)
```bash
flutter build ios
# Then open in Xcode to sign and archive
```

## 📦 Dependencies

```yaml
dependencies:
  http: ^1.1.0                      # HTTP requests
  flutter_secure_storage: ^9.0.0   # Encrypted storage
  provider: ^6.1.1                  # State management
```

## 🎯 Extending the Frontend

### Adding a New Screen
1. Create file in `lib/screens/`
2. Import models and services
3. Add navigation from dashboard

### Adding a New API Call
1. Add endpoint to `api_config.dart`
2. Create method in service
3. Call from screen

### Adding a New Model
1. Create file in `lib/models/`
2. Add `fromJson()` and `toJson()` methods
3. Use in services and screens

## 📚 Learn More

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)

---

**Need help? Check the main README or Flutter documentation!**
