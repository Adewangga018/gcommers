using Microsoft.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

static class AuthDatabase
{
    public static async Task EnsureSchemaAsync(IConfiguration configuration)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        const string sql = """
        IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Users
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
                Email NVARCHAR(256) NOT NULL,
                PasswordHash VARBINARY(64) NOT NULL,
                PasswordSalt VARBINARY(32) NOT NULL,
                Role NVARCHAR(50) NOT NULL,
                DisplayName NVARCHAR(200) NOT NULL,
                KioskName NVARCHAR(200) NULL,
                PicName NVARCHAR(200) NULL,
                Phone NVARCHAR(50) NULL,
                TransportirName NVARCHAR(200) NULL,
                CompanyName NVARCHAR(200) NULL,
                PoliceNumber NVARCHAR(50) NULL,
                [Type] NVARCHAR(100) NULL,
                Address NVARCHAR(500) NULL,
                Region NVARCHAR(100) NULL,
                LicenseImageName NVARCHAR(260) NULL,
                ResetOtpHash VARBINARY(64) NULL,
                ResetOtpSalt VARBINARY(32) NULL,
                ResetOtpExpiresAt DATETIMEOFFSET NULL,
                ResetOtpVerifiedAt DATETIMEOFFSET NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT SYSUTCDATETIME(),
                CONSTRAINT CK_Users_Role CHECK (Role IN (N'kiosk', N'transportir', N'admin'))
            );

            CREATE UNIQUE INDEX UX_Users_Email ON dbo.Users(Email);
        END
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM sys.check_constraints
            WHERE name = N'CK_Users_Role'
              AND parent_object_id = OBJECT_ID(N'dbo.Users')
        )
        BEGIN
            ALTER TABLE dbo.Users
            ADD CONSTRAINT CK_Users_Role CHECK (Role IN (N'kiosk', N'transportir', N'admin'));
        END
        
        -- Add PoliceNumber column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'PoliceNumber'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD PoliceNumber NVARCHAR(50) NULL;
        END

        -- Add Type column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'Type'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD [Type] NVARCHAR(100) NULL;
        END

        -- Add TransportirName column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'TransportirName'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD TransportirName NVARCHAR(200) NULL;
        END

        -- Add CompanyName column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'CompanyName'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD CompanyName NVARCHAR(200) NULL;
        END
        """;

        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();
    }

    public static async Task<AuthUserRecord?> FindUserByEmailAsync(SqlConnection connection, string email, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT TOP 1
                Id,
                Email,
                PasswordHash,
                PasswordSalt,
                Role,
                DisplayName,
                TransportirName,
                CompanyName,
                PoliceNumber,
                [Type],
                ResetOtpHash,
                ResetOtpSalt,
                ResetOtpExpiresAt,
                ResetOtpVerifiedAt
            FROM dbo.Users
            WHERE Email = @Email;
            """;
        command.Parameters.AddWithValue("@Email", email);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AuthUserRecord(
            reader.GetInt32(0),
            reader.GetString(1),
            (byte[])reader[2],
            (byte[])reader[3],
            reader.GetString(4),
            reader.GetString(5),
            reader.IsDBNull(6) ? null : reader.GetString(6),
            reader.IsDBNull(7) ? null : reader.GetString(7),
            reader.IsDBNull(8) ? null : reader.GetString(8),
            reader.IsDBNull(9) ? null : reader.GetString(9),
            reader.IsDBNull(10) ? null : (byte[])reader[10],
            reader.IsDBNull(11) ? null : (byte[])reader[11],
            reader.IsDBNull(12) ? null : reader.GetFieldValue<DateTimeOffset>(12),
            reader.IsDBNull(13) ? null : reader.GetFieldValue<DateTimeOffset>(13));
    }

    public static async Task<AuthSession> CreateUserAsync(
        SqlConnection connection,
        RegisterKioskRequest request,
        string normalizedEmail,
        string role,
        CancellationToken cancellationToken)
    {
        var displayName = request.KioskName.Trim();
        var (passwordSalt, passwordHash) = PasswordHasher.Hash(request.Password);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO dbo.Users
            (
                Email,
                PasswordHash,
                PasswordSalt,
                Role,
                DisplayName,
                TransportirName,
                CompanyName,
                KioskName,
                PicName,
                Phone,
                PoliceNumber,
                [Type],
                Address,
                Region,
                LicenseImageName,
                CreatedAt,
                UpdatedAt
            )
            OUTPUT INSERTED.Id, INSERTED.Email, INSERTED.Role, INSERTED.DisplayName
            VALUES
            (
                @Email,
                @PasswordHash,
                @PasswordSalt,
                @Role,
                @DisplayName,
                NULL,
                NULL,
                @KioskName,
                @PicName,
                @Phone,
                @PoliceNumber,
                @Type,
                @Address,
                @Region,
                @LicenseImageName,
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            """;

        command.Parameters.AddWithValue("@Email", normalizedEmail);
        command.Parameters.AddWithValue("@PasswordHash", passwordHash);
        command.Parameters.AddWithValue("@PasswordSalt", passwordSalt);
        command.Parameters.AddWithValue("@Role", role);
        command.Parameters.AddWithValue("@DisplayName", displayName);
        command.Parameters.AddWithValue("@KioskName", request.KioskName.Trim());
        command.Parameters.AddWithValue("@PicName", request.PicName.Trim());
        command.Parameters.AddWithValue("@Phone", request.Phone.Trim());
        command.Parameters.AddWithValue("@PoliceNumber", DBNull.Value);
        command.Parameters.AddWithValue("@Type", DBNull.Value);
        command.Parameters.AddWithValue("@Address", request.Address.Trim());
        command.Parameters.AddWithValue("@Region", request.Region.Trim());
        command.Parameters.AddWithValue("@LicenseImageName", (object?)request.LicenseImageName ?? DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create kiosk user.");
        }

        return new AuthSession(normalizedEmail, reader.GetString(2), reader.GetString(3), Guid.NewGuid().ToString("N"));
    }

    public static Task<AuthSession> CreateKioskUserAsync(
        SqlConnection connection,
        RegisterKioskRequest request,
        string normalizedEmail,
        CancellationToken cancellationToken)
        => CreateUserAsync(connection, request, normalizedEmail, "kiosk", cancellationToken);

    public static async Task<AuthSession> CreateTransportirUserAsync(
        SqlConnection connection,
        RegisterTransportirRequest request,
        string normalizedEmail,
        CancellationToken cancellationToken)
    {
        var (passwordSalt, passwordHash) = PasswordHasher.Hash(request.Password);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO dbo.Users
            (
                Email,
                PasswordHash,
                PasswordSalt,
                Role,
                DisplayName,
                TransportirName,
                CompanyName,
                KioskName,
                PicName,
                Phone,
                PoliceNumber,
                [Type],
                Address,
                Region,
                LicenseImageName,
                CreatedAt,
                UpdatedAt
            )
            OUTPUT INSERTED.Id, INSERTED.Email, INSERTED.Role, INSERTED.DisplayName
            VALUES
            (
                @Email,
                @PasswordHash,
                @PasswordSalt,
                @Role,
                @DisplayName,
                @TransportirName,
                @CompanyName,
                NULL,
                NULL,
                @Phone,
                @PoliceNumber,
                @Type,
                NULL,
                NULL,
                NULL,
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            """;

        command.Parameters.AddWithValue("@Email", normalizedEmail);
        command.Parameters.AddWithValue("@PasswordHash", passwordHash);
        command.Parameters.AddWithValue("@PasswordSalt", passwordSalt);
        command.Parameters.AddWithValue("@Role", "transportir");
        command.Parameters.AddWithValue("@DisplayName", request.CompanyName.Trim());
        command.Parameters.AddWithValue("@TransportirName", request.TransportirName.Trim());
        command.Parameters.AddWithValue("@CompanyName", request.CompanyName.Trim());
        command.Parameters.AddWithValue("@Phone", request.Phone.Trim());
        command.Parameters.AddWithValue("@PoliceNumber", request.PoliceNumber.Trim());
        command.Parameters.AddWithValue("@Type", request.Type.Trim());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create transportir user.");
        }

        return new AuthSession(
            normalizedEmail,
            reader.GetString(2),
            reader.GetString(3),
            Guid.NewGuid().ToString("N"),
            request.TransportirName.Trim(),
            request.CompanyName.Trim(),
            request.PoliceNumber.Trim(),
            request.Type.Trim());
    }

    public static async Task StoreResetOtpAsync(SqlConnection connection, int userId, string otp, CancellationToken cancellationToken)
    {
        var (salt, hash) = OtpHasher.Hash(otp);
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(10);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Users
            SET ResetOtpHash = @ResetOtpHash,
                ResetOtpSalt = @ResetOtpSalt,
                ResetOtpExpiresAt = @ResetOtpExpiresAt,
                ResetOtpVerifiedAt = NULL,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id;
            """;

        command.Parameters.AddWithValue("@Id", userId);
        command.Parameters.AddWithValue("@ResetOtpHash", hash);
        command.Parameters.AddWithValue("@ResetOtpSalt", salt);
        command.Parameters.AddWithValue("@ResetOtpExpiresAt", expiresAt);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public static async Task MarkOtpVerifiedAsync(SqlConnection connection, int userId, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Users
            SET ResetOtpVerifiedAt = SYSUTCDATETIME(),
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id;
            """;
        command.Parameters.AddWithValue("@Id", userId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public static async Task UpdatePasswordAsync(SqlConnection connection, int userId, string password, CancellationToken cancellationToken)
    {
        var (salt, hash) = PasswordHasher.Hash(password);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Users
            SET PasswordHash = @PasswordHash,
                PasswordSalt = @PasswordSalt,
                ResetOtpHash = NULL,
                ResetOtpSalt = NULL,
                ResetOtpExpiresAt = NULL,
                ResetOtpVerifiedAt = NULL,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id;
            """;
        command.Parameters.AddWithValue("@Id", userId);
        command.Parameters.AddWithValue("@PasswordHash", hash);
        command.Parameters.AddWithValue("@PasswordSalt", salt);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}

static class PasswordHasher
{
    private const int Iterations = 100_000;
    private const int SaltSize = 16;
    private const int KeySize = 32;

    public static (byte[] Salt, byte[] Hash) Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            KeySize);

        return (salt, hash);
    }

    public static bool Verify(string password, byte[] salt, byte[] expectedHash)
    {
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            expectedHash.Length);

        return CryptographicOperations.FixedTimeEquals(hash, expectedHash);
    }
}

static class OtpHasher
{
    private const int Iterations = 50_000;
    private const int SaltSize = 16;
    private const int KeySize = 32;

    public static (byte[] Salt, byte[] Hash) Hash(string otp)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            otp,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            KeySize);

        return (salt, hash);
    }

    public static bool Verify(string otp, byte[]? salt, byte[]? expectedHash, DateTimeOffset? expiresAt)
    {
        if (salt is null || expectedHash is null || expiresAt is null)
        {
            return false;
        }

        if (expiresAt <= DateTimeOffset.UtcNow)
        {
            return false;
        }

        var hash = Rfc2898DeriveBytes.Pbkdf2(
            otp,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            expectedHash.Length);

        return CryptographicOperations.FixedTimeEquals(hash, expectedHash);
    }
}

static class OtpGenerator
{
    public static string Create()
    {
        var value = RandomNumberGenerator.GetInt32(0, 1_000_000);
        return value.ToString("D6");
    }
}
