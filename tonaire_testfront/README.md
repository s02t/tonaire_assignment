# Frontend — Flutter App

## Requirements
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android API 36 

## Setup

### 1. Install dependencies
```bash
cd frontend
flutter pub get
```

### 2. Configure API base URL
Edit `lib/services/api_service.dart`:
```dart
// Android emulator
const String baseUrl = 'http://10.0.2.2:3000';

// Desktop
const String baseUrl = 'http://localhost:3000';

```

### 3. Run the app
```bash
# Check connected devices
flutter devices

# Run on Android
flutter run -d android

# Run on Desktop (linux)
flutter run -d linux
```

## App Structure

```
lib/
├── main.dart                  # Entry point with auth gate
├── utils/
│   └── app_theme.dart         # Theme, colors, routes
├── services/
│   ├── api_service.dart       # All API calls
│   └── auth_provider.dart     # Auth state management
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── forgot_password_screen.dart
    ├── home_screen.dart        # Bottom nav shell
    ├── categories/
    │   └── categories_screen.dart
    └── products/
        └── products_screen.dart
```

## Features

### Authentication
- Login with JWT token (persisted securely)
- Sign up with validation
- Auto-login on app start
- Logout

### Categories
- Create, Read, Update, Delete
- Debounced search (400ms) in English
- Pull-to-refresh

### Products
- Paginated list (20 per page)
- Infinite scroll auto-load
- Sort by name (ASC/DESC)
- Filter by category (dropdown)
- Debounced search (English)
- Product images via CachedNetworkImage
- Fallback placeholder for missing images
- Create / Edit / Delete

## Khmer Language Support
- All text fields accept Unicode Khmer characters 
- Search and sort use `COLLATE Latin1_General_CI_AI` on backend
- Keyboard supports Khmer input on Android API 36+
