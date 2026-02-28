# Product & Category Management — Full Stack App

A production-ready full-stack application featuring **Node.js + SQL Server** backend and **Flutter** frontend, with support for Khmer (ភាសាខ្មែរ) and English.

## 📁 Repository Structure

```
/tonaire_assignment
├── backend/                 ← Node.js + Express REST API
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js  ← SQL Server connection
│   │   ├── middleware/
│   │   │   └── auth.js      ← JWT middleware
│   │   ├── routes/
│   │   │   ├── auth.js      ← Login, Signup, Forgot Password
│   │   │   ├── categories.js← Category CRUD
│   │   │   └── products.js  ← Product CRUD + image upload
│   │   └── server.js        ← Express app entry
│   ├── uploads/images/      ← Uploaded product images
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
├── tonaire_testfront/                ← Flutter App
│   ├── lib/
│   │   ├── main.dart        ← Entry point + auth gate
│   │   ├── utils/
│   │   │   └── app_theme.dart
│   │   ├── services/
│   │   │   ├── api_service.dart      ← HTTP API calls
│   │   │   └── auth_provider.dart    ← Auth state
│   │   └── screens/
│   │       ├── auth/
│   │       │   ├── login_screen.dart
│   │       │   ├── signup_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       ├── home_screen.dart
│   │       ├── categories/
│   │       │   └── categories_screen.dart
│   │       └── products/
│   │           └── products_screen.dart
│   ├── pubspec.yaml
│   └── README.md
│
├── sql/
│   └── schema.sql           ← DB schema + sample data
│
└── docs/
    └── README.md
```

## 🚀 Setup & Run

### Prerequisites
- Node.js 18+
- SQL Server (or SQL Server Express)
- Flutter SDK 3.0+
- Android Studio / VS Code

### Step 1 — Database
```bash
sqlcmd -S YOUR_SERVER -U sa -P YOUR_PASSWORD -i sql/schema.sql
```

### Step 2 — Backend
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your SQL Server and email credentials
npm run dev
```
API Base URL: `http://localhost:3000`

### Step 3 — Flutter Frontend
```bash
cd frontend
flutter pub get
# Edit lib/services/api_service.dart
# Change baseUrl to match your machine:
#   Android emulator: http://10.0.2.2:3000
#   Real device: http://YOUR_LOCAL_IP:3000
flutter run
```

## 🔐 Default Credentials
| Email | Password |
|-------|----------|
| admin@example.com | Admin@1234 |

## 🌐 API Endpoints
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /auth/signup | — | Register |
| POST | /auth/login | — | Login → JWT |
| POST | /auth/forgot-password | — | Send OTP |
| POST | /auth/verify-otp | — | Reset password |
| GET | /categories | ✅ | List (with search) |
| POST | /categories | ✅ | Create |
| PUT | /categories/:id | ✅ | Update |
| DELETE | /categories/:id | ✅ | Delete |
| GET | /products | ✅ | List (pagination/sort/filter) |
| POST | /products | ✅ | Create |
| PUT | /products/:id | ✅ | Update |
| DELETE | /products/:id | ✅ | Delete |

## 📱 App Screens
1. **Login** — Email/password + JWT
2. **Sign Up** — Username, email, password
3. **Home** — Bottom nav (Products / Categories)
4. **Products** — Paginated list, infinite scroll, sort, filter, search
5. **Categories** — CRUD with debounced search 