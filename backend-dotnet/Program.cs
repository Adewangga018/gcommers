using Microsoft.Data.SqlClient;
using System.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());
});

builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseCors("AllowAll");

await AuthDatabase.EnsureSchemaAsync(app.Configuration);

var auth = app.MapGroup("/auth");

app.MapGet("/health", async (IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var connectionString = ConnectionStringFactory.Build(configuration);

    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    await using var command = connection.CreateCommand();
    command.CommandText = "SELECT 1";

    var result = await command.ExecuteScalarAsync(cancellationToken);
    var ok = Convert.ToInt32(result) == 1;

    return Results.Ok(new
    {
        ok,
        database = connection.Database,
        server = connection.DataSource
    });
});

app.MapGet("/tables", async (IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var connectionString = ConnectionStringFactory.Build(configuration);
    var tables = new List<object>();

    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    await using var command = connection.CreateCommand();
    command.CommandText = """
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME;
        """;

    await using var reader = await command.ExecuteReaderAsync(CommandBehavior.CloseConnection, cancellationToken);
    while (await reader.ReadAsync(cancellationToken))
    {
        tables.Add(new
        {
            schema = reader.GetString(0),
            name = reader.GetString(1)
        });
    }

    return Results.Ok(tables);
});

auth.MapPost("/login", async (LoginRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var email = NormalizeEmail(request.Email);
    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email dan password wajib diisi." });
    }

    var connectionString = ConnectionStringFactory.Build(configuration);
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    var user = await AuthDatabase.FindUserByEmailAsync(connection, email, cancellationToken);
    if (user is null || !PasswordHasher.Verify(request.Password, user.PasswordSalt, user.PasswordHash))
    {
        return Results.Unauthorized();
    }

    return Results.Ok(AuthSession.FromUser(user));
});

auth.MapPost("/register-kiosk", async (RegisterKioskRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var validationError = request.Validate();
    if (validationError is not null)
    {
        return Results.BadRequest(new { message = validationError });
    }

    var connectionString = ConnectionStringFactory.Build(configuration);
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    var email = NormalizeEmail(request.Email);
    var existing = await AuthDatabase.FindUserByEmailAsync(connection, email, cancellationToken);
    if (existing is not null)
    {
        return Results.Conflict(new { message = "Email sudah terdaftar." });
    }

    var session = await AuthDatabase.CreateKioskUserAsync(connection, request, email, cancellationToken);
    return Results.Ok(session);
});

auth.MapPost("/forgot-password", async (ForgotPasswordRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var email = NormalizeEmail(request.Email);
    if (string.IsNullOrWhiteSpace(email))
    {
        return Results.BadRequest(new { message = "Email wajib diisi." });
    }

    var connectionString = ConnectionStringFactory.Build(configuration);
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    var user = await AuthDatabase.FindUserByEmailAsync(connection, email, cancellationToken);
    if (user is null)
    {
        return Results.NotFound(new { message = "Akun tidak ditemukan." });
    }

    var otp = OtpGenerator.Create();
    await AuthDatabase.StoreResetOtpAsync(connection, user.Id, otp, cancellationToken);

    return Results.Ok(new ForgotPasswordResponse(
        Email: user.Email,
        Otp: otp,
        ExpiresInSeconds: 600));
});

auth.MapPost("/verify-otp", async (VerifyOtpRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var email = NormalizeEmail(request.Email);
    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Otp))
    {
        return Results.BadRequest(new { message = "Email dan OTP wajib diisi." });
    }

    var connectionString = ConnectionStringFactory.Build(configuration);
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    var user = await AuthDatabase.FindUserByEmailAsync(connection, email, cancellationToken);
    if (user is null)
    {
        return Results.NotFound(new { message = "Akun tidak ditemukan." });
    }

    if (!OtpHasher.Verify(request.Otp, user.ResetOtpSalt, user.ResetOtpHash, user.ResetOtpExpiresAt))
    {
        return Results.BadRequest(new { message = "OTP tidak valid atau sudah kedaluwarsa." });
    }

    await AuthDatabase.MarkOtpVerifiedAsync(connection, user.Id, cancellationToken);
    return Results.Ok(new { message = "OTP valid." });
});

auth.MapPost("/reset-password", async (ResetPasswordRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var email = NormalizeEmail(request.Email);
    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email dan password wajib diisi." });
    }

    if (request.Password != request.ConfirmPassword)
    {
        return Results.BadRequest(new { message = "Konfirmasi password tidak cocok." });
    }

    var connectionString = ConnectionStringFactory.Build(configuration);
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync(cancellationToken);

    var user = await AuthDatabase.FindUserByEmailAsync(connection, email, cancellationToken);
    if (user is null)
    {
        return Results.NotFound(new { message = "Akun tidak ditemukan." });
    }

    if (!user.ResetOtpVerifiedAt.HasValue || user.ResetOtpExpiresAt is null || user.ResetOtpExpiresAt <= DateTimeOffset.UtcNow)
    {
        return Results.BadRequest(new { message = "OTP belum diverifikasi atau sudah kedaluwarsa." });
    }

    await AuthDatabase.UpdatePasswordAsync(connection, user.Id, request.Password, cancellationToken);
    return Results.Ok(new { message = "Password berhasil diperbarui." });
});

// Note: KTP file upload endpoint can be added later with cloud storage (Azure Blob, S3)
// For now, KTP filename is stored in registration via licenseImageName field

app.MapGet("/", () => Results.Ok(new
{
    service = "Gcommers API",
    status = "running"
}));

app.Run();

static string NormalizeEmail(string? email)
{
    return email?.Trim().ToLowerInvariant() ?? string.Empty;
}

static class ConnectionStringFactory
{
    public static string Build(IConfiguration configuration)
    {
        var direct = configuration.GetConnectionString("DefaultConnection");
        if (!string.IsNullOrWhiteSpace(direct))
        {
            return direct;
        }

        var host = configuration["DB_HOST"];
        var port = configuration["DB_PORT"];
        var database = configuration["DB_DATABASE"];
        var username = configuration["DB_USERNAME"];
        var password = configuration["DB_PASSWORD"];
        var instanceName = configuration["DB_INSTANCE_NAME"];
        var encrypt = configuration.GetValue("DB_ENCRYPT", false);
        var trustServerCertificate = configuration.GetValue("DB_TRUST_SERVER_CERTIFICATE", true);

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(database))
        {
            throw new InvalidOperationException("Connection string is missing. Set ConnectionStrings:DefaultConnection or DB_HOST/DB_DATABASE.");
        }

        var builder = new SqlConnectionStringBuilder
        {
            DataSource = string.IsNullOrWhiteSpace(instanceName)
                ? ComposeDataSource(host!, port)
                : $"{host}\\{instanceName}",
            InitialCatalog = database,
            Encrypt = encrypt,
            TrustServerCertificate = trustServerCertificate
        };

        if (!string.IsNullOrWhiteSpace(username))
        {
            builder.UserID = username;
            builder.Password = password ?? string.Empty;
            builder.IntegratedSecurity = false;
        }
        else
        {
            builder.IntegratedSecurity = true;
        }

        return builder.ConnectionString;
    }

    private static string ComposeDataSource(string host, string? port)
    {
        if (string.IsNullOrWhiteSpace(port))
        {
            return host;
        }

        return $"{host},{port}";
    }
}
