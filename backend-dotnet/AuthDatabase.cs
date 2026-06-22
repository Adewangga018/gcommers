using System.Data;
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
                FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_FailedLoginCount DEFAULT 0,
                LastFailedLoginAt DATETIMEOFFSET NULL,
                LockoutUntil DATETIMEOFFSET NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT SYSUTCDATETIME(),
                CONSTRAINT CK_Users_Role CHECK (Role IN (N'kiosk', N'transportir', N'admin', N'superadmin'))
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
            ADD CONSTRAINT CK_Users_Role CHECK (Role IN (N'kiosk', N'transportir', N'admin', N'superadmin'));
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND EXISTS (
            SELECT 1
            FROM sys.check_constraints
            WHERE name = N'CK_Users_Role'
              AND parent_object_id = OBJECT_ID(N'dbo.Users')
        )
        BEGIN
            ALTER TABLE dbo.Users DROP CONSTRAINT CK_Users_Role;
            ALTER TABLE dbo.Users
            ADD CONSTRAINT CK_Users_Role CHECK (Role IN (N'kiosk', N'transportir', N'admin', N'superadmin'));
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
        -- Add FailedLoginCount / Lockout columns if missing (for brute-force protection)
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'FailedLoginCount'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_FailedLoginCount DEFAULT 0;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'LastFailedLoginAt'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD LastFailedLoginAt DATETIMEOFFSET NULL;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'LockoutUntil'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD LockoutUntil DATETIMEOFFSET NULL;
        END

        -- Migrate AvatarImage from NVARCHAR(MAX) to VARBINARY(MAX) if it was added with wrong type
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND EXISTS (
            SELECT 1 FROM sys.columns c
            JOIN sys.types t ON c.user_type_id = t.user_type_id
            WHERE c.object_id = OBJECT_ID(N'dbo.Users') AND c.name = N'AvatarImage' AND t.name = N'nvarchar'
        )
        BEGIN
            ALTER TABLE dbo.Users DROP COLUMN AvatarImage;
        END

        -- Add AvatarImage as VARBINARY(MAX) if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'AvatarImage'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD AvatarImage VARBINARY(MAX) NULL;
        END

        -- Add id_kab column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'id_kab'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD id_kab INT NULL;
        END

        -- Add kode_kec column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'kode_kec'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD kode_kec NVARCHAR(20) NULL;
        END

        -- Add nama_kec column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'nama_kec'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD nama_kec NVARCHAR(150) NULL;
        END

        -- Add nama_kab column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'nama_kab'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD nama_kab NVARCHAR(150) NULL;
        END

        -- Add ProvinsiId / KabupatenId / KecamatanId columns if missing (administrative location, FK to propinsi/kabupaten/kecamatan)
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'ProvinsiId'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD ProvinsiId BIGINT NULL;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'KabupatenId'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD KabupatenId BIGINT NULL;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'KecamatanId'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD KecamatanId BIGINT NULL;
        END

        -- Add Kecamatan (plain text name) column if missing
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'Kecamatan'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD Kecamatan NVARCHAR(150) NULL;
        END
        """;

        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();

        await SeedAdminUsersAsync(connection);
    }

    private static async Task SeedAdminUsersAsync(SqlConnection connection)
    {
        await EnsureAdminUserAsync(connection, "superadmin@gcommers.id", "Super Admin", "superadmin", null);

        foreach (var region in new[] { "Makassar", "Medan", "Lampung", "Gresik" })
        {
            await EnsureAdminUserAsync(
                connection,
                $"admin.{region.ToLowerInvariant()}@gcommers.id",
                $"Admin {region}",
                "admin",
                region);
        }
    }

    private static async Task EnsureAdminUserAsync(
        SqlConnection connection,
        string email,
        string displayName,
        string role,
        string? region)
    {
        await using var existsCommand = connection.CreateCommand();
        existsCommand.CommandText = "SELECT 1 FROM dbo.Users WHERE Email = @Email;";
        existsCommand.Parameters.AddWithValue("@Email", email);
        if (await existsCommand.ExecuteScalarAsync() is not null)
        {
            return;
        }

        var (passwordSalt, passwordHash) = PasswordHasher.Hash("Admin123!");
        await using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO dbo.Users
            (
                Email,
                PasswordHash,
                PasswordSalt,
                Role,
                DisplayName,
                Region,
                CreatedAt,
                UpdatedAt
            )
            VALUES
            (
                @Email,
                @PasswordHash,
                @PasswordSalt,
                @Role,
                @DisplayName,
                @Region,
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );
            """;
        command.Parameters.AddWithValue("@Email", email);
        command.Parameters.AddWithValue("@PasswordHash", passwordHash);
        command.Parameters.AddWithValue("@PasswordSalt", passwordSalt);
        command.Parameters.AddWithValue("@Role", role);
        command.Parameters.AddWithValue("@DisplayName", displayName);
        command.Parameters.AddWithValue("@Region", (object?)region ?? DBNull.Value);
        await command.ExecuteNonQueryAsync();
    }

    public static async Task<AuthUserRecord?> FindUserByEmailAsync(SqlConnection connection, string email, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT TOP 1
                u.Id,
                u.Email,
                u.PasswordHash,
                u.PasswordSalt,
                u.Role,
                u.DisplayName,
                u.Phone,
                u.PicName,
                u.Address,
                u.Region,
                u.TransportirName,
                u.CompanyName,
                u.PoliceNumber,
                u.[Type],
                u.ResetOtpHash,
                u.ResetOtpSalt,
                u.ResetOtpExpiresAt,
                u.ResetOtpVerifiedAt,
                u.FailedLoginCount,
                u.LastFailedLoginAt,
                u.LockoutUntil,
                u.AvatarImage,
                u.ProvinsiId,
                u.KabupatenId,
                u.KecamatanId,
                p.nama_pro,
                k.nama_kab,
                c.nama_kec
            FROM dbo.Users u
            LEFT JOIN dbo.propinsi p ON p.id = u.ProvinsiId
            LEFT JOIN dbo.kabupaten k ON k.id = u.KabupatenId
            LEFT JOIN dbo.kecamatan c ON c.id = u.KecamatanId
            WHERE u.Email = @Email;
            """;
        command.Parameters.AddWithValue("@Email", email);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AuthUserRecord(
            reader.GetInt32(0),                 // Id
            reader.GetString(1),                // Email
            (byte[])reader[2],                   // PasswordHash
            (byte[])reader[3],                   // PasswordSalt
            reader.GetString(4),                // Role
            reader.GetString(5),                // DisplayName
            reader.IsDBNull(6) ? null : reader.GetString(6),   // Phone
            reader.IsDBNull(7) ? null : reader.GetString(7),   // PicName
            reader.IsDBNull(8) ? null : reader.GetString(8),   // Address
            reader.IsDBNull(9) ? null : reader.GetString(9),   // Region
            reader.IsDBNull(10) ? null : reader.GetString(10), // TransportirName
            reader.IsDBNull(11) ? null : reader.GetString(11), // CompanyName
            reader.IsDBNull(12) ? null : reader.GetString(12), // PoliceNumber
            reader.IsDBNull(13) ? null : reader.GetString(13), // VehicleType ([Type])
            reader.IsDBNull(14) ? null : (byte[])reader[14],    // ResetOtpHash
            reader.IsDBNull(15) ? null : (byte[])reader[15],    // ResetOtpSalt
            reader.IsDBNull(16) ? null : reader.GetFieldValue<DateTimeOffset>(16), // ResetOtpExpiresAt
            reader.IsDBNull(17) ? null : reader.GetFieldValue<DateTimeOffset>(17), // ResetOtpVerifiedAt
            reader.GetInt32(18),                                // FailedLoginCount
            reader.IsDBNull(19) ? null : reader.GetFieldValue<DateTimeOffset>(19), // LastFailedLoginAt
            reader.IsDBNull(20) ? null : reader.GetFieldValue<DateTimeOffset>(20), // LockoutUntil
            reader.IsDBNull(21) ? null : (byte[])reader[21],   // AvatarImage
            reader.IsDBNull(22) ? null : reader.GetInt64(22),  // ProvinsiId
            reader.IsDBNull(23) ? null : reader.GetInt64(23),  // KabupatenId
            reader.IsDBNull(24) ? null : reader.GetInt64(24),  // KecamatanId
            reader.IsDBNull(25) ? null : reader.GetString(25), // ProvinsiNama
            reader.IsDBNull(26) ? null : reader.GetString(26), // KabupatenNama
            reader.IsDBNull(27) ? null : reader.GetString(27)); // KecamatanNama
    }

    public static async Task ResetLoginAttemptsAsync(SqlConnection connection, int userId, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Users
            SET FailedLoginCount = 0,
                LastFailedLoginAt = NULL,
                LockoutUntil = NULL,
                UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id;
            """;
        command.Parameters.AddWithValue("@Id", userId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public static async Task<DateTimeOffset?> RegisterFailedLoginAsync(SqlConnection connection, int userId, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            DECLARE @Now DATETIMEOFFSET = SYSUTCDATETIME();
            DECLARE @AttemptCount INT;

            UPDATE dbo.Users
            SET FailedLoginCount = CASE
                    WHEN LastFailedLoginAt IS NULL OR LastFailedLoginAt < DATEADD(MINUTE, -15, @Now) THEN 1
                    ELSE FailedLoginCount + 1
                END,
                LastFailedLoginAt = @Now,
                LockoutUntil = CASE
                    WHEN LastFailedLoginAt IS NULL OR LastFailedLoginAt < DATEADD(MINUTE, -15, @Now) THEN NULL
                    WHEN FailedLoginCount + 1 >= 5 THEN DATEADD(MINUTE, 15, @Now)
                    ELSE LockoutUntil
                END,
                UpdatedAt = @Now
            OUTPUT INSERTED.LockoutUntil
            WHERE Id = @Id;
            """;
        command.Parameters.AddWithValue("@Id", userId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return reader.IsDBNull(0) ? null : reader.GetFieldValue<DateTimeOffset>(0);
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
        var kecamatanNama = await GetKecamatanNamaAsync(connection, request.KecamatanId, cancellationToken);

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
                ProvinsiId,
                KabupatenId,
                KecamatanId,
                Kecamatan,
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
                @ProvinsiId,
                @KabupatenId,
                @KecamatanId,
                @Kecamatan,
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
        command.Parameters.AddWithValue("@Kecamatan", (object?)kecamatanNama ?? DBNull.Value);
        command.Parameters.AddWithValue("@ProvinsiId", request.ProvinsiId);
        command.Parameters.AddWithValue("@KabupatenId", request.KabupatenId);
        command.Parameters.AddWithValue("@KecamatanId", request.KecamatanId);
        command.Parameters.AddWithValue("@LicenseImageName", (object?)request.LicenseImageName ?? DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create kiosk user.");
        }

        return new AuthSession(normalizedEmail, reader.GetString(2), reader.GetString(3), Guid.NewGuid().ToString("N"));
    }

    private static async Task<string?> GetKecamatanNamaAsync(SqlConnection connection, long kecamatanId, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT nama_kec FROM dbo.kecamatan WHERE id = @Id;";
        command.Parameters.AddWithValue("@Id", kecamatanId);
        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result as string;
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
                @Region,
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
        command.Parameters.AddWithValue("@Region", request.Region.Trim());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create transportir user.");
        }

        return new AuthSession(
            Email: normalizedEmail,
            Role: reader.GetString(2),
            DisplayName: reader.GetString(3),
            Token: Guid.NewGuid().ToString("N"),
            Phone: request.Phone.Trim(),
            Region: request.Region.Trim(),
            TransportirName: request.TransportirName.Trim(),
            CompanyName: request.CompanyName.Trim(),
            PoliceNumber: request.PoliceNumber.Trim(),
            VehicleType: request.Type.Trim());
    }

    public static async Task<List<string>> GetTransportirCompanyNamesAsync(
        IConfiguration configuration,
        string? region,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT DISTINCT CompanyName
            FROM dbo.Users
            WHERE Role = N'transportir'
              AND CompanyName IS NOT NULL
              AND (@Region IS NULL OR Region = @Region)
            ORDER BY CompanyName;
            """;
        command.Parameters.AddWithValue("@Region", string.IsNullOrWhiteSpace(region) ? DBNull.Value : region);

        var result = new List<string>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(reader.GetString(0));
        }

        return result;
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

    public static async Task UpdateProfileAsync(
        SqlConnection connection,
        string email,
        UpdateProfileRequest request,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Users
            SET DisplayName  = @DisplayName,
                KioskName    = CASE WHEN Role = N'kiosk' THEN @DisplayName ELSE KioskName END,
                CompanyName  = CASE WHEN Role = N'transportir' THEN @DisplayName ELSE CompanyName END,
                PicName      = CASE WHEN Role = N'kiosk' THEN @PicName ELSE PicName END,
                TransportirName = CASE WHEN Role = N'transportir' THEN @PicName ELSE TransportirName END,
                Phone        = @Phone,
                Address      = @Address,
                AvatarImage  = COALESCE(@AvatarImage, AvatarImage),
                UpdatedAt    = SYSUTCDATETIME()
            WHERE Email = @Email;
            """;
        command.Parameters.AddWithValue("@Email", email);
        command.Parameters.AddWithValue("@DisplayName", request.DisplayName.Trim());
        command.Parameters.AddWithValue("@PicName", (object?)request.PicName?.Trim() ?? DBNull.Value);
        command.Parameters.AddWithValue("@Phone", (object?)request.Phone?.Trim() ?? DBNull.Value);
        command.Parameters.AddWithValue("@Address", (object?)request.Address?.Trim() ?? DBNull.Value);

        // Use explicit VarBinary(MAX) — AddWithValue can silently truncate large base64 strings
        var avatarParam = command.Parameters.Add("@AvatarImage", SqlDbType.VarBinary, -1);
        if (!string.IsNullOrEmpty(request.AvatarImageBase64))
        {
            try { avatarParam.Value = Convert.FromBase64String(request.AvatarImageBase64); }
            catch { avatarParam.Value = DBNull.Value; }
        }
        else
        {
            avatarParam.Value = DBNull.Value;
        }

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public static async Task<bool> ChangePasswordAsync(
        SqlConnection connection,
        string email,
        string currentPassword,
        string newPassword,
        CancellationToken cancellationToken)
    {
        var user = await FindUserByEmailAsync(connection, email, cancellationToken);
        if (user is null) return false;

        if (!PasswordHasher.Verify(currentPassword, user.PasswordSalt, user.PasswordHash))
            return false;

        await UpdatePasswordAsync(connection, user.Id, newPassword, cancellationToken);
        return true;
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
