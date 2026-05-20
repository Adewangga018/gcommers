using Microsoft.Data.SqlClient;
using System.Data;

static class CommerceDatabase
{
    public static async Task EnsureSchemaAsync(IConfiguration configuration)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await ExecuteAsync(connection, """
        IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Products
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
                Name NVARCHAR(200) NOT NULL,
                Description NVARCHAR(1000) NOT NULL,
                Category NVARCHAR(50) NOT NULL,
                Price DECIMAL(18,2) NOT NULL,
                Stock INT NOT NULL,
                MinimumOrder INT NOT NULL,
                Unit NVARCHAR(100) NOT NULL,
                IconName NVARCHAR(100) NOT NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME()
            );
        END

        IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Orders
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
                PoNumber NVARCHAR(50) NOT NULL,
                UserEmail NVARCHAR(256) NULL,
                Status NVARCHAR(50) NOT NULL,
                Vendor NVARCHAR(200) NOT NULL,
                PaymentMethod NVARCHAR(100) NOT NULL,
                Subtotal DECIMAL(18,2) NOT NULL,
                TaxAmount DECIMAL(18,2) NOT NULL,
                ShippingAmount DECIMAL(18,2) NOT NULL,
                TotalAmount DECIMAL(18,2) NOT NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Orders_UpdatedAt DEFAULT SYSUTCDATETIME(),
                PaidAt DATETIMEOFFSET NULL,
                DeliveredAt DATETIMEOFFSET NULL
            );

            CREATE UNIQUE INDEX UX_Orders_PoNumber ON dbo.Orders(PoNumber);
        END

        IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.OrderItems
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrderItems PRIMARY KEY,
                OrderId INT NOT NULL,
                ProductId INT NULL,
                ProductName NVARCHAR(200) NOT NULL,
                Unit NVARCHAR(100) NOT NULL,
                Quantity INT NOT NULL,
                UnitPrice DECIMAL(18,2) NOT NULL,
                TotalPrice DECIMAL(18,2) NOT NULL,
                CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id)
            );
        END

        IF OBJECT_ID(N'dbo.OrderEvents', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.OrderEvents
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrderEvents PRIMARY KEY,
                OrderId INT NOT NULL,
                Title NVARCHAR(200) NOT NULL,
                Subtitle NVARCHAR(300) NOT NULL,
                EventType NVARCHAR(50) NOT NULL,
                IsActive BIT NOT NULL,
                SortOrder INT NOT NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_OrderEvents_CreatedAt DEFAULT SYSUTCDATETIME(),
                CONSTRAINT FK_OrderEvents_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id)
            );
        END

        IF OBJECT_ID(N'dbo.Notifications', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Notifications
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Notifications PRIMARY KEY,
                Title NVARCHAR(200) NOT NULL,
                Description NVARCHAR(500) NOT NULL,
                IsRead BIT NOT NULL CONSTRAINT DF_Notifications_IsRead DEFAULT 0,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT SYSUTCDATETIME()
            );
        END
        """);

        await SeedAsync(connection);
    }

    public static async Task<IReadOnlyList<ProductDto>> GetProductsAsync(
        IConfiguration configuration,
        string? category,
        CancellationToken cancellationToken)
    {
        var products = new List<ProductDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT Id, Name, Description, Category, Price, Stock, MinimumOrder, Unit, IconName
            FROM dbo.Products
            WHERE @Category IS NULL OR Category = @Category
            ORDER BY Id;
            """;
        command.Parameters.AddWithValue("@Category", string.IsNullOrWhiteSpace(category) ? DBNull.Value : category);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            products.Add(new ProductDto(
                reader.GetInt32(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetDecimal(4),
                reader.GetInt32(5),
                reader.GetInt32(6),
                reader.GetString(7),
                reader.GetString(8)));
        }

        return products;
    }

    public static async Task<OrderDetailDto> CreateOrderAsync(
        IConfiguration configuration,
        CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        try
        {
            var orderItems = new List<(int ProductId, string Name, string Unit, int Quantity, decimal UnitPrice, decimal TotalPrice)>();
            foreach (var item in request.Items)
            {
                await using var productCommand = connection.CreateCommand();
                productCommand.Transaction = (SqlTransaction)transaction;
                productCommand.CommandText = "SELECT Name, Unit, Price, Stock FROM dbo.Products WHERE Id = @Id;";
                productCommand.Parameters.AddWithValue("@Id", item.ProductId);

                await using var reader = await productCommand.ExecuteReaderAsync(cancellationToken);
                if (!await reader.ReadAsync(cancellationToken))
                {
                    throw new InvalidOperationException($"Produk {item.ProductId} tidak ditemukan.");
                }

                var name = reader.GetString(0);
                var unit = reader.GetString(1);
                var price = reader.GetDecimal(2);
                var stock = reader.GetInt32(3);
                await reader.CloseAsync();

                if (stock < item.Quantity)
                {
                    throw new InvalidOperationException($"Stok {name} tidak cukup.");
                }

                orderItems.Add((item.ProductId, name, unit, item.Quantity, price, price * item.Quantity));
            }

            var subtotal = orderItems.Sum(item => item.TotalPrice);
            var tax = Math.Round(subtotal * 0.11m, 2);
            var shipping = 250000m;
            var total = subtotal + tax + shipping;
            var poNumber = $"PO-{DateTimeOffset.UtcNow:yyyyMMdd-HHmmss}";

            await using var orderCommand = connection.CreateCommand();
            orderCommand.Transaction = (SqlTransaction)transaction;
            orderCommand.CommandText = """
                INSERT INTO dbo.Orders
                (PoNumber, UserEmail, Status, Vendor, PaymentMethod, Subtotal, TaxAmount, ShippingAmount, TotalAmount)
                OUTPUT INSERTED.Id
                VALUES
                (@PoNumber, @UserEmail, 'pending_payment', 'PT Global Logistik Nusantara', '-', @Subtotal, @TaxAmount, @ShippingAmount, @TotalAmount);
                """;
            orderCommand.Parameters.AddWithValue("@PoNumber", poNumber);
            orderCommand.Parameters.AddWithValue("@UserEmail", (object?)request.UserEmail ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@Subtotal", subtotal);
            orderCommand.Parameters.AddWithValue("@TaxAmount", tax);
            orderCommand.Parameters.AddWithValue("@ShippingAmount", shipping);
            orderCommand.Parameters.AddWithValue("@TotalAmount", total);
            var orderId = Convert.ToInt32(await orderCommand.ExecuteScalarAsync(cancellationToken));

            foreach (var item in orderItems)
            {
                await using var itemCommand = connection.CreateCommand();
                itemCommand.Transaction = (SqlTransaction)transaction;
                itemCommand.CommandText = """
                    INSERT INTO dbo.OrderItems
                    (OrderId, ProductId, ProductName, Unit, Quantity, UnitPrice, TotalPrice)
                    VALUES
                    (@OrderId, @ProductId, @ProductName, @Unit, @Quantity, @UnitPrice, @TotalPrice);

                    UPDATE dbo.Products
                    SET Stock = Stock - @Quantity
                    WHERE Id = @ProductId;
                    """;
                itemCommand.Parameters.AddWithValue("@OrderId", orderId);
                itemCommand.Parameters.AddWithValue("@ProductId", item.ProductId);
                itemCommand.Parameters.AddWithValue("@ProductName", item.Name);
                itemCommand.Parameters.AddWithValue("@Unit", item.Unit);
                itemCommand.Parameters.AddWithValue("@Quantity", item.Quantity);
                itemCommand.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);
                itemCommand.Parameters.AddWithValue("@TotalPrice", item.TotalPrice);
                await itemCommand.ExecuteNonQueryAsync(cancellationToken);
            }

            await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId, "Pesanan Dibuat", "Menunggu pembayaran", "created", true, 10, cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return await GetOrderDetailAsync(configuration, poNumber, cancellationToken)
                ?? throw new InvalidOperationException("Pesanan gagal dibuat.");
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public static async Task<IReadOnlyList<OrderSummaryDto>> GetOrdersAsync(
        IConfiguration configuration,
        string? userEmail,
        CancellationToken cancellationToken)
    {
        var orders = new List<OrderSummaryDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT
                o.PoNumber,
                o.Status,
                o.TotalAmount,
                o.CreatedAt,
                o.PaymentMethod,
                COUNT(oi.Id) AS ItemCount
            FROM dbo.Orders o
            LEFT JOIN dbo.OrderItems oi ON oi.OrderId = o.Id
            WHERE @UserEmail IS NULL OR o.UserEmail = @UserEmail
            GROUP BY o.PoNumber, o.Status, o.TotalAmount, o.CreatedAt, o.PaymentMethod
            ORDER BY o.CreatedAt DESC;
            """;
        command.Parameters.AddWithValue("@UserEmail", string.IsNullOrWhiteSpace(userEmail) ? DBNull.Value : userEmail);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var status = reader.GetString(1);
            orders.Add(new OrderSummaryDto(
                reader.GetString(0),
                status,
                ToStatusLabel(status),
                reader.GetDecimal(2),
                reader.GetFieldValue<DateTimeOffset>(3),
                reader.GetString(4),
                reader.GetInt32(5)));
        }

        return orders;
    }

    public static async Task<OrderDetailDto?> GetOrderDetailAsync(
        IConfiguration configuration,
        string poNumber,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT Id, PoNumber, Status, Vendor, PaymentMethod, Subtotal, TaxAmount, ShippingAmount,
                   TotalAmount, CreatedAt, PaidAt, DeliveredAt
            FROM dbo.Orders
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        var orderId = reader.GetInt32(0);
        var status = reader.GetString(2);
        var detail = new
        {
            PoNumber = reader.GetString(1),
            Status = status,
            Vendor = reader.GetString(3),
            PaymentMethod = reader.GetString(4),
            Subtotal = reader.GetDecimal(5),
            TaxAmount = reader.GetDecimal(6),
            ShippingAmount = reader.GetDecimal(7),
            TotalAmount = reader.GetDecimal(8),
            CreatedAt = reader.GetFieldValue<DateTimeOffset>(9),
            PaidAt = reader.IsDBNull(10) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(10),
            DeliveredAt = reader.IsDBNull(11) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(11)
        };
        await reader.CloseAsync();

        var items = await GetOrderItemsAsync(connection, orderId, cancellationToken);
        var timeline = await GetOrderTimelineAsync(connection, orderId, cancellationToken);

        return new OrderDetailDto(
            detail.PoNumber,
            detail.Status,
            ToStatusLabel(detail.Status),
            detail.Vendor,
            detail.PaymentMethod,
            detail.Subtotal,
            detail.TaxAmount,
            detail.ShippingAmount,
            detail.TotalAmount,
            detail.CreatedAt,
            detail.PaidAt,
            detail.DeliveredAt,
            items,
            timeline);
    }

    public static async Task<PaymentResponse?> PayOrderAsync(
        IConfiguration configuration,
        string poNumber,
        PaymentRequest request,
        CancellationToken cancellationToken)
    {
        var method = string.IsNullOrWhiteSpace(request.Method) ? "BRI" : request.Method.Trim().ToUpperInvariant();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.Transaction = (SqlTransaction)transaction;
        command.CommandText = """
            UPDATE dbo.Orders
            SET Status = 'paid',
                PaymentMethod = @PaymentMethod,
                PaidAt = COALESCE(PaidAt, SYSUTCDATETIME()),
                UpdatedAt = SYSUTCDATETIME()
            OUTPUT INSERTED.Id, INSERTED.TotalAmount
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);
        command.Parameters.AddWithValue("@PaymentMethod", method);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            await transaction.RollbackAsync(cancellationToken);
            return null;
        }

        var orderId = reader.GetInt32(0);
        var total = reader.GetDecimal(1);
        await reader.CloseAsync();

        await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId, "Pembayaran Berhasil", $"Metode {method}", "paid", true, 20, cancellationToken);
        await AddNotificationAsync(connection, (SqlTransaction)transaction, "Pembayaran berhasil", $"Pembayaran {poNumber} melalui {method} telah diterima.", cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new PaymentResponse(poNumber, method, BuildVirtualAccount(method, poNumber), total, "paid");
    }

    public static async Task<bool> ConfirmReceivedAsync(
        IConfiguration configuration,
        string poNumber,
        ConfirmReceivedRequest request,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.Transaction = (SqlTransaction)transaction;
        command.CommandText = """
            UPDATE dbo.Orders
            SET Status = @Status,
                DeliveredAt = CASE WHEN @Accepted = 1 THEN COALESCE(DeliveredAt, SYSUTCDATETIME()) ELSE DeliveredAt END,
                UpdatedAt = SYSUTCDATETIME()
            OUTPUT INSERTED.Id
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);
        command.Parameters.AddWithValue("@Accepted", request.Accepted);
        command.Parameters.AddWithValue("@Status", request.Accepted ? "received" : "delivery_issue");

        var result = await command.ExecuteScalarAsync(cancellationToken);
        if (result is null)
        {
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }

        var orderId = Convert.ToInt32(result);
        var title = request.Accepted ? "Barang Diterima" : "Barang Bermasalah";
        var subtitle = string.IsNullOrWhiteSpace(request.Notes) ? "Konfirmasi dari kios" : request.Notes!;
        await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId, title, subtitle, "received", true, 40, cancellationToken);
        await AddNotificationAsync(connection, (SqlTransaction)transaction, title, $"{poNumber}: {subtitle}", cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return true;
    }

    public static async Task<DashboardSummaryDto> GetDashboardSummaryAsync(
        IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        var orders = await GetOrdersAsync(configuration, null, cancellationToken);
        var active = orders.Count(order => order.Status is "pending_payment" or "paid" or "shipping");
        var completed = orders.Count(order => order.Status is "received" or "completed");
        var monthlySales = orders.Sum(order => order.TotalAmount);
        return new DashboardSummaryDto(active, completed, monthlySales, orders.Take(5).ToList());
    }

    public static async Task<IReadOnlyList<NotificationDto>> GetNotificationsAsync(
        IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        var items = new List<NotificationDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT TOP 30 Id, Title, Description, CreatedAt, IsRead
            FROM dbo.Notifications
            ORDER BY CreatedAt DESC;
            """;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new NotificationDto(
                reader.GetInt32(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetFieldValue<DateTimeOffset>(3),
                reader.GetBoolean(4)));
        }

        return items;
    }

    private static async Task<IReadOnlyList<OrderItemDto>> GetOrderItemsAsync(SqlConnection connection, int orderId, CancellationToken cancellationToken)
    {
        var items = new List<OrderItemDto>();
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT ProductName, Unit, Quantity, UnitPrice, TotalPrice
            FROM dbo.OrderItems
            WHERE OrderId = @OrderId
            ORDER BY Id;
            """;
        command.Parameters.AddWithValue("@OrderId", orderId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new OrderItemDto(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetInt32(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4)));
        }

        return items;
    }

    private static async Task<IReadOnlyList<OrderTimelineDto>> GetOrderTimelineAsync(SqlConnection connection, int orderId, CancellationToken cancellationToken)
    {
        var items = new List<OrderTimelineDto>();
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT Title, Subtitle, EventType, IsActive
            FROM dbo.OrderEvents
            WHERE OrderId = @OrderId
            ORDER BY SortOrder DESC, CreatedAt DESC;
            """;
        command.Parameters.AddWithValue("@OrderId", orderId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new OrderTimelineDto(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetBoolean(3)));
        }

        return items;
    }

    private static async Task SeedAsync(SqlConnection connection)
    {
        await ExecuteAsync(connection, """
        IF NOT EXISTS (SELECT 1 FROM dbo.Products)
        BEGIN
            INSERT INTO dbo.Products (Name, Description, Category, Price, Stock, MinimumOrder, Unit, IconName)
            VALUES
            ('Pupuk Urea Prill 50kg', 'Pupuk nitrogen tinggi untuk mempercepat pertumbuhan vegetatif tanaman dan meningkatkan hasil panen.', 'Subsidi', 112500, 120, 1, 'Karung (50kg)', 'water_drop'),
            ('NPK Phonska 15-15-15', 'Pupuk majemuk seimbang yang membantu pertumbuhan akar, batang, dan kualitas hasil panen.', 'Subsidi', 115000, 85, 1, 'Karung (50kg)', 'eco'),
            ('Benih Padi Inpari 32', 'Varietas benih unggul dengan daya hasil tinggi dan adaptif untuk berbagai kondisi lahan sawah.', 'Retail', 65000, 40, 1, 'Pack (5kg)', 'spa');
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE PoNumber = 'PO-2026-10-9842')
        BEGIN
            INSERT INTO dbo.Orders
            (PoNumber, UserEmail, Status, Vendor, PaymentMethod, Subtotal, TaxAmount, ShippingAmount, TotalAmount, PaidAt)
            VALUES
            ('PO-2026-10-9842', NULL, 'shipping', 'PT Global Logistik Nusantara', 'Bank Transfer (Mandiri)', 12150000, 1336500, 250000, 13736500, SYSUTCDATETIME());

            DECLARE @OrderId INT = SCOPE_IDENTITY();

            INSERT INTO dbo.OrderItems (OrderId, ProductName, Unit, Quantity, UnitPrice, TotalPrice)
            VALUES
            (@OrderId, 'Pupuk Urea Prill 50kg', 'Sak', 100, 55000, 5500000),
            (@OrderId, 'NPK Phonska 15-15-15', 'Btg', 50, 85000, 4250000),
            (@OrderId, 'Benih Padi Inpari 32', 'Btg', 20, 120000, 2400000);

            INSERT INTO dbo.OrderEvents (OrderId, Title, Subtitle, EventType, IsActive, SortOrder)
            VALUES
            (@OrderId, 'Dalam Perjalanan', 'Estimasi kirim: 25 Okt', 'shipping', 1, 30),
            (@OrderId, 'Pembayaran Berhasil', 'Bank Transfer (Mandiri)', 'paid', 1, 20),
            (@OrderId, 'Pesanan Dibuat', '24 Okt, 14:30', 'created', 1, 10);
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Notifications)
        BEGIN
            INSERT INTO dbo.Notifications (Title, Description)
            VALUES
            ('PO Baru #PO-2026-10-9842', 'Purchase order baru dengan nilai Rp 13.736.500.'),
            ('Pembayaran berhasil', 'Pembayaran PO-2026-10-9842 telah diterima.'),
            ('Pesanan dalam perjalanan', 'Kurir sedang mengantar pesanan ke kios.');
        END
        """);
    }

    private static async Task ExecuteAsync(SqlConnection connection, string sql)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();
    }

    private static async Task AddOrderEventAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int orderId,
        string title,
        string subtitle,
        string eventType,
        bool isActive,
        int sortOrder,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """
            INSERT INTO dbo.OrderEvents
            (OrderId, Title, Subtitle, EventType, IsActive, SortOrder)
            VALUES
            (@OrderId, @Title, @Subtitle, @EventType, @IsActive, @SortOrder);
            """;
        command.Parameters.AddWithValue("@OrderId", orderId);
        command.Parameters.AddWithValue("@Title", title);
        command.Parameters.AddWithValue("@Subtitle", subtitle);
        command.Parameters.AddWithValue("@EventType", eventType);
        command.Parameters.AddWithValue("@IsActive", isActive);
        command.Parameters.AddWithValue("@SortOrder", sortOrder);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task AddNotificationAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        string title,
        string description,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """
            INSERT INTO dbo.Notifications (Title, Description)
            VALUES (@Title, @Description);
            """;
        command.Parameters.AddWithValue("@Title", title);
        command.Parameters.AddWithValue("@Description", description);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static string ToStatusLabel(string status) => status switch
    {
        "pending_payment" => "PENDING",
        "paid" => "DIBAYAR",
        "shipping" => "DIPROSES",
        "received" => "DITERIMA",
        "completed" => "SELESAI",
        "delivery_issue" => "BERMASALAH",
        _ => status.ToUpperInvariant()
    };

    private static string BuildVirtualAccount(string method, string poNumber)
    {
        var digits = new string(poNumber.Where(char.IsDigit).ToArray());
        return method switch
        {
            "MANDIRI" => $"88908{digits[^Math.Min(digits.Length, 10)..]}",
            _ => $"77788{digits[^Math.Min(digits.Length, 10)..]}"
        };
    }
}
