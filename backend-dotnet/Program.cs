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

try
{
    await AuthDatabase.EnsureSchemaAsync(app.Configuration);
    await CommerceDatabase.EnsureSchemaAsync(app.Configuration);
}
catch (Exception ex)
{
    // Allow API to start even if DB is temporarily unreachable.
    app.Logger.LogError(ex, "Failed to ensure database schema on startup.");
}


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
    if (user is null)
    {
        return Results.Json(new { message = "Email atau password salah." }, statusCode: StatusCodes.Status401Unauthorized);
    }

    if (user.LockoutUntil.HasValue && user.LockoutUntil.Value > DateTimeOffset.UtcNow)
    {
        return Results.Json(
            new { message = $"Akun terkunci sementara sampai {user.LockoutUntil:dd MMM yyyy HH:mm} WIB." },
            statusCode: StatusCodes.Status423Locked);
    }

    if (!PasswordHasher.Verify(request.Password, user.PasswordSalt, user.PasswordHash))
    {
        var lockoutUntil = await AuthDatabase.RegisterFailedLoginAsync(connection, user.Id, cancellationToken);
        if (lockoutUntil.HasValue && lockoutUntil.Value > DateTimeOffset.UtcNow)
        {
            return Results.Json(
                new { message = $"Akun terkunci sementara sampai {lockoutUntil:dd MMM yyyy HH:mm} WIB." },
                statusCode: StatusCodes.Status423Locked);
        }

        return Results.Json(new { message = "Email atau password salah." }, statusCode: StatusCodes.Status401Unauthorized);
    }

    await AuthDatabase.ResetLoginAttemptsAsync(connection, user.Id, cancellationToken);

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

auth.MapPost("/register-transportir", async (RegisterTransportirRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
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

    var session = await AuthDatabase.CreateTransportirUserAsync(connection, request, email, cancellationToken);
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

auth.MapPost("/upload-ktp", async (HttpRequest request, IWebHostEnvironment environment, CancellationToken cancellationToken) =>
{
    if (!request.HasFormContentType)
    {
        return Results.BadRequest(new { message = "Request harus multipart/form-data." });
    }

    var form = await request.ReadFormAsync(cancellationToken);
    var file = form.Files["file"];
    if (file is null || file.Length == 0)
    {
        return Results.BadRequest(new { message = "File KTP wajib diunggah." });
    }

    var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
    if (extension is not ".jpg" and not ".jpeg" and not ".png")
    {
        return Results.BadRequest(new { message = "Format file harus JPG atau PNG." });
    }

    const long maxFileSize = 5 * 1024 * 1024;
    if (file.Length > maxFileSize)
    {
        return Results.BadRequest(new { message = "Ukuran file maksimal 5MB." });
    }

    var uploadRoot = Path.Combine(environment.ContentRootPath, "uploads", "ktp");
    Directory.CreateDirectory(uploadRoot);

    var safeName = $"{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid():N}{extension}";
    var destination = Path.Combine(uploadRoot, safeName);

    await using var stream = File.Create(destination);
    await file.CopyToAsync(stream, cancellationToken);

    return Results.Ok(new UploadKtpResponse(safeName, $"/uploads/ktp/{safeName}"));
});

app.MapGet("/dashboard/summary", async (IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var summary = await CommerceDatabase.GetDashboardSummaryAsync(configuration, cancellationToken);
    return Results.Ok(summary);
});

app.MapGet("/products", async (string? category, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var products = await CommerceDatabase.GetProductsAsync(configuration, category, cancellationToken);
    return Results.Ok(products);
});

var orders = app.MapGroup("/orders");

orders.MapGet("/", async (string? userEmail, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var data = await CommerceDatabase.GetOrdersAsync(configuration, userEmail, cancellationToken);
    return Results.Ok(data);
});

orders.MapPost("/", async (CreateOrderRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var validationError = request.Validate();
    if (validationError is not null)
    {
        return Results.BadRequest(new { message = validationError });
    }

    try
    {
        var order = await CommerceDatabase.CreateOrderAsync(configuration, request, cancellationToken);
        return Results.Ok(order);
    }
    catch (InvalidOperationException ex)
    {
        return Results.BadRequest(new { message = ex.Message });
    }
});

orders.MapGet("/{poNumber}", async (string poNumber, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var order = await CommerceDatabase.GetOrderDetailAsync(configuration, poNumber, cancellationToken);
    return order is null
        ? Results.NotFound(new { message = "Pesanan tidak ditemukan." })
        : Results.Ok(order);
});

orders.MapPost("/{poNumber}/payment", async (string poNumber, PaymentRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var payment = await CommerceDatabase.PayOrderAsync(configuration, poNumber, request, cancellationToken);
    return payment is null
        ? Results.NotFound(new { message = "Pesanan tidak ditemukan." })
        : Results.Ok(payment);
});

orders.MapPost("/{poNumber}/confirm-received", async (string poNumber, ConfirmReceivedRequest request, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var ok = await CommerceDatabase.ConfirmReceivedAsync(configuration, poNumber, request, cancellationToken);
    return ok
        ? Results.Ok(new { message = "Konfirmasi penerimaan barang tersimpan." })
        : Results.NotFound(new { message = "Pesanan tidak ditemukan." });
});

app.MapGet("/notifications", async (string? userEmail, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    var notifications = await CommerceDatabase.GetNotificationsAsync(configuration, userEmail, cancellationToken);
    return Results.Ok(notifications);
});

app.MapPost("/notifications/mark-all-read", async (string? userEmail, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    await CommerceDatabase.MarkAllNotificationsReadAsync(configuration, userEmail, cancellationToken);
    return Results.Ok(new { message = "Semua notifikasi ditandai dibaca." });
});

app.MapPost("/notifications/{id}/mark-read", async (int id, IConfiguration configuration, CancellationToken cancellationToken) =>
{
    await CommerceDatabase.MarkNotificationReadAsync(configuration, id, cancellationToken);
    return Results.Ok(new { message = "Notifikasi ditandai dibaca." });
});

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
