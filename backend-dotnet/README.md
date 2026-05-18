# Gcommers API (.NET)

Minimal ASP.NET Core Web API for connecting the Flutter app to SQL Server.

## Features
- `GET /health` checks SQL Server connectivity
- `GET /tables` returns database table list
- `POST /auth/login` authenticates against SQL Server
- `POST /auth/register-kiosk` creates kiosk users in SQL Server
- `POST /auth/forgot-password` generates a reset OTP stored in SQL Server
- `POST /auth/verify-otp` verifies the reset OTP
- `POST /auth/reset-password` updates the password in SQL Server
- Supports SQL login via environment variables or a direct connection string

## Connection options
### Option 1: direct connection string
Set `ConnectionStrings__DefaultConnection`:

```powershell
$env:ConnectionStrings__DefaultConnection = "Server=192.168.100.2,49291;Database=db_gcommers;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=False;"
```

### Option 2: separate variables
- `DB_HOST`
- `DB_PORT`
- `DB_DATABASE`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_INSTANCE_NAME` (optional)
- `DB_ENCRYPT` (optional, default `false`)
- `DB_TRUST_SERVER_CERTIFICATE` (optional, default `true`)

## Run
```powershell
cd backend-dotnet
dotnet restore
dotnet run --urls http://localhost:5000
```

This project targets `.NET 10.0`, which matches the runtime installed on this machine.

## Test
```powershell
Invoke-RestMethod http://localhost:5000/health
Invoke-RestMethod http://localhost:5000/tables
```

Example auth calls:
```powershell
Invoke-RestMethod http://localhost:5000/auth/login -Method Post -ContentType 'application/json' -Body '{"email":"user@example.com","password":"Secret123!"}'
```

## Notes
- If login fails for `sa`, verify SQL Authentication is enabled and the password is correct.
- If the server uses a named instance, set `DB_INSTANCE_NAME` instead of `DB_PORT`.
- If you want the Flutter app to point here, update the base URL in `lib/services/api_service.dart` to `http://localhost:5000` for local testing.
