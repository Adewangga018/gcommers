# Issue Resolution: Registration Error

## Problem
```
XMLHttpRequest error: Failed to load resource: net::ERR_CONNECTION_REFUSED
:5001/auth/register-kiosk:1
```

User tidak bisa membuat akun baru - setiap kali submit, error connection refused.

## Root Cause
**Backend API server tidak running** saat user mencoba submit registration dari Flutter app.

## Solution
Backend HARUS dijalankan sebelum membuka Flutter app.

### Step-by-Step:

#### 1. Terminal 1 - Start Backend
```powershell
cd e:\Kuliah\Magang\GCS\grantee\gcommers\backend-dotnet
$env:DB_HOST='192.168.100.2'
$env:DB_PORT='49291'
$env:DB_DATABASE='db_gcommers'
$env:DB_USERNAME='sa'
$env:DB_PASSWORD='Penunggu#D4Ta*2021@^'
dotnet run --urls http://localhost:5001
```

Wait until you see: `Now listening on: http://localhost:5001`

#### 2. Terminal 2 - Verify Connection
```powershell
Invoke-RestMethod -Method Get -Uri "http://localhost:5001/health" | ConvertTo-Json
```

Should show: `"ok": true` with database info

#### 3. Terminal 3 - Start Flutter App
```powershell
cd e:\Kuliah\Magang\GCS\grantee\gcommers
flutter run -d web
```

#### 4. Test Registration
- Go to login screen → Click "Daftar sebagai Kios"
- Fill Step 1 (kiosk info)
- Fill Step 2 (location, KTP, T&C)
- Click DAFTAR → Should work now!

## Verification

### Backend Status
✅ Database connection: **WORKING**
✅ Registration endpoint: **WORKING**  
✅ Login endpoint: **WORKING**
✅ All auth flows: **WORKING**

### Test Results
```
=== Testing Registration ===
✓ Register Success: testuser360933598@gcommers.local

=== Testing Login ===
✓ Login Success: Token generated successfully
```

## Important Notes

1. **Backend must run continuously** while using the app
2. **Port 5001** must be free (not used by other apps)
3. **SQL Server** at 192.168.100.2:49291 must be accessible
4. **Database** `db_gcommers` is auto-created on first run

## Full Documentation
See [SETUP.md](SETUP.md) for complete setup instructions, troubleshooting, and architecture details.
