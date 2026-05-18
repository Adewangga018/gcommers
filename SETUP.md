# GCommers Setup & Run Guide

## Prerequisites
- Flutter 3.8.1+
- .NET 10.0 SDK
- SQL Server 2019+ (accessible at `192.168.100.2:49291`)
- SQL Server credentials: `sa` / `Penunggu#D4Ta*2021@^`

## Database Setup

The application automatically creates the required schema on first run. No manual database setup needed.

**Database**: `db_gcommers`
**Table**: `dbo.Users` (auto-created with columns for auth, kiosk data, KTP info)

## Running the Application

### Step 1: Start Backend API Server

Open PowerShell and run:

```powershell
cd e:\Kuliah\Magang\GCS\grantee\gcommers\backend-dotnet

# Set environment variables
$env:DB_HOST='192.168.100.2'
$env:DB_PORT='49291'
$env:DB_DATABASE='db_gcommers'
$env:DB_USERNAME='sa'
$env:DB_PASSWORD='Penunggu#D4Ta*2021@^'

# Start backend
dotnet run --urls http://localhost:5001
```

Expected output:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5001
```

### Step 2: Verify Backend Connectivity

In another PowerShell terminal:

```powershell
Invoke-RestMethod -Method Get -Uri "http://localhost:5001/health" | ConvertTo-Json
```

Should return:
```json
{
    "ok": true,
    "database": "db_gcommers",
    "server": "192.168.100.2,49291"
}
```

### Step 3: Start Flutter App

In another terminal:

```powershell
cd e:\Kuliah\Magang\GCS\grantee\gcommers

# Get dependencies
flutter pub get

# Run app (choose your target)
flutter run -d web          # For web/localhost
flutter run -d chrome       # For Chrome browser
flutter run -d windows      # For Windows desktop (requires Visual Studio)
flutter run -d android      # For Android device/emulator
```

## Testing the Application

### Manual Test Flow

1. **Splash Screen**: Wait 1.8 seconds
2. **Login Screen**: Click "Daftar sebagai Kios" (register link)
3. **Registration Step 1**: Fill in kiosk details
   - Nama Kios: e.g., "Kios Jaya"
   - Nama Pemilik: e.g., "Budi"
   - No. Telepon: e.g., "08123456789"
   - Email: e.g., "kioskjaya@gcommers.local"
   - Password: e.g., "Secret123!"
4. **Registration Step 2**: Complete registration
   - Alamat: e.g., "Jl. Sudirman No. 123"
   - Kode Wilayah: Select from dropdown
   - Upload Foto KTP: Click upload box, select image from gallery
   - Accept T&C: Check checkbox
   - Click "DAFTAR" button
5. **Home Screen**: Should see welcome message and user details
6. **Logout**: Click logout button in top-right, confirm

### Automated Test Flow

Run all tests:
```powershell
flutter test
```

Expected: `All tests passed!`

## Architecture

```
Frontend (Flutter)
├── lib/src/
│   ├── screens/          # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── otp_screen.dart
│   │   ├── reset_password_screen.dart
│   │   ├── kiosk_register_step1_screen.dart
│   │   ├── kiosk_register_step2_screen.dart
│   │   ├── home_screen.dart
│   │   └── app_shell.dart
│   ├── services/         # Business Logic
│   │   ├── auth_service.dart        # API calls
│   │   └── session_manager.dart     # Local storage
│   ├── models/
│   │   └── auth_models.dart         # Data models
│   ├── widgets/
│   │   └── auth_widgets.dart        # Reusable components
│   └── theme/
│       └── app_theme.dart           # Theming
├── test/
│   └── widget_test.dart

Backend (.NET)
├── Program.cs                  # Main entry, all endpoints
├── AuthDatabase.cs             # Database schema, queries
├── AuthContracts.cs            # Request/response models
└── backend-dotnet.csproj
```

## API Endpoints

All endpoints return JSON. Base URL: `http://localhost:5001`

### Auth Endpoints
- `POST /auth/login` - Login with email/password
- `POST /auth/register-kiosk` - Register new kiosk user
- `POST /auth/forgot-password` - Request password reset OTP
- `POST /auth/verify-otp` - Verify OTP code
- `POST /auth/reset-password` - Update password

### Utility Endpoints
- `GET /health` - Check database connectivity
- `GET /tables` - List all database tables
- `GET /` - API status

## Features Implemented

✅ User Authentication
- Login with email & password
- Register as kiosk operator
- Password reset with OTP verification
- Session management & persistence
- Auto-login on app startup
- Logout with session cleanup

✅ KTP Management
- Image picker from device gallery
- Image preview in registration form
- Filename metadata storage in database
- Support for all platforms (web, mobile, desktop)

✅ Security
- PBKDF2-SHA256 password hashing (100,000 iterations)
- OTP generation & verification with 10-minute expiry
- Session tokens
- CORS enabled for development

✅ Database
- SQL Server integration
- Auto-schema creation on startup
- User role management (kiosk, admin)
- Registration metadata storage

## Troubleshooting

### "Failed to load resource: net::ERR_CONNECTION_REFUSED"
**Problem**: Backend server is not running
**Solution**: 
1. Make sure backend is running on port 5001
2. Check terminal shows "Now listening on: http://localhost:5001"

### "Login failed for user 'sa'"
**Problem**: Database credentials incorrect
**Solution**:
1. Verify SQL Server is running at 192.168.100.2:49291
2. Check credentials: sa / Penunggu#D4Ta*2021@^
3. Ensure database `db_gcommers` exists (auto-created if missing)

### "All tests passed!" but app doesn't run
**Problem**: Visual Studio toolchain missing (for Windows desktop)
**Solution**: 
1. Use web platform: `flutter run -d web`
2. Or use Chrome: `flutter run -d chrome`
3. Or install Visual Studio Build Tools for desktop support

### Image upload not working
**Note**: File upload to cloud storage can be added later
**Current State**: Filename is stored in database, full file upload deferred to production phase

## Development Workflow

1. **Make code changes**
2. **Run tests**: `flutter test` (catches compilation errors)
3. **Hot reload**: Press 'r' in Flutter terminal
4. **Full restart**: Press 'R' in Flutter terminal
5. **Stop app**: Press 'q' in Flutter terminal

## Production Deployment

### Frontend
- Build web: `flutter build web`
- Build Android: `flutter build apk`
- Build iOS: `flutter build ios`

### Backend
- Publish: `dotnet publish -c Release`
- Configure environment variables for production database
- Deploy to app server (IIS, Azure, Docker, etc.)

## Future Enhancements

1. Cloud file storage for KTP images (Azure Blob, S3, GCS)
2. Email verification for registration
3. Admin dashboard for user management
4. Advanced role-based access control
5. Two-factor authentication
6. User profile management
7. Transaction logging & audit trail
