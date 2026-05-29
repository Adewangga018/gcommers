using Microsoft.Data.SqlClient;
using Microsoft.VisualBasic.FileIO;
using System.Globalization;

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
                ProductCode NVARCHAR(50) NULL,
                SourceProductId INT NULL,
                Name NVARCHAR(200) NOT NULL,
                Description NVARCHAR(MAX) NOT NULL,
                Category NVARCHAR(50) NOT NULL,
                Price DECIMAL(18,2) NOT NULL,
                Stock INT NOT NULL,
                MinimumOrder INT NOT NULL,
                Unit NVARCHAR(100) NOT NULL,
                IconName NVARCHAR(100) NOT NULL,
                Status NVARCHAR(50) NOT NULL CONSTRAINT DF_Products_Status DEFAULT N'Aktif',
                Rating DECIMAL(3,1) NOT NULL CONSTRAINT DF_Products_Rating DEFAULT 0,
                Specification NVARCHAR(MAX) NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NULL
            );
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'ProductCode')
                ALTER TABLE dbo.Products ADD ProductCode NVARCHAR(50) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'SourceProductId')
                ALTER TABLE dbo.Products ADD SourceProductId INT NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'Status')
                ALTER TABLE dbo.Products ADD Status NVARCHAR(50) NOT NULL CONSTRAINT DF_Products_Status DEFAULT N'Aktif';
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'Rating')
                ALTER TABLE dbo.Products ADD Rating DECIMAL(3,1) NOT NULL CONSTRAINT DF_Products_Rating DEFAULT 0;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'Specification')
                ALTER TABLE dbo.Products ADD Specification NVARCHAR(MAX) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = 'UpdatedAt')
                ALTER TABLE dbo.Products ADD UpdatedAt DATETIMEOFFSET NULL;
            IF EXISTS (
                SELECT 1
                FROM sys.columns c
                JOIN sys.types t ON c.user_type_id = t.user_type_id
                WHERE c.object_id = OBJECT_ID(N'dbo.Products')
                  AND c.name = N'Description'
                  AND t.name = N'nvarchar'
                  AND c.max_length <> -1
            )
                ALTER TABLE dbo.Products ALTER COLUMN Description NVARCHAR(MAX) NOT NULL;
        END

        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Products_ProductCode' AND object_id = OBJECT_ID(N'dbo.Products'))
            EXEC(N'CREATE UNIQUE INDEX UX_Products_ProductCode ON dbo.Products(ProductCode) WHERE ProductCode IS NOT NULL;');

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
                VirtualAccount NVARCHAR(30) NULL,
                VaExpiredAt DATETIMEOFFSET NULL,
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
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'VirtualAccount')
                ALTER TABLE dbo.Orders ADD VirtualAccount NVARCHAR(30) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'VaExpiredAt')
                ALTER TABLE dbo.Orders ADD VaExpiredAt DATETIMEOFFSET NULL;
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
                UserEmail NVARCHAR(256) NULL,
                Title NVARCHAR(200) NOT NULL,
                Description NVARCHAR(500) NOT NULL,
                IsRead BIT NOT NULL CONSTRAINT DF_Notifications_IsRead DEFAULT 0,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT SYSUTCDATETIME()
            );
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Notifications') AND name = 'UserEmail')
        BEGIN
            -- Migration to add UserEmail if table exists from previous version
            ALTER TABLE dbo.Notifications ADD UserEmail NVARCHAR(256) NULL;
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
            SELECT Id, COALESCE(ProductCode, ''), Name, Description, Category, Price, Stock,
                   MinimumOrder, Unit, IconName, Status, Rating, Specification
            FROM dbo.Products
            WHERE (@Category IS NULL OR Category = @Category)
              AND Status = N'Aktif'
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
                reader.GetString(4),
                reader.GetDecimal(5),
                reader.GetInt32(6),
                reader.GetInt32(7),
                reader.GetString(8),
                reader.GetString(9),
                reader.GetString(10),
                reader.GetDecimal(11),
                reader.IsDBNull(12) ? null : reader.GetString(12)));
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
        MandiriSnapService mandiriSnap,
        CancellationToken cancellationToken)
    {
        var method = "MANDIRI";
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        // Check order exists and get total before starting transaction
        await using var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = "SELECT TotalAmount FROM dbo.Orders WHERE PoNumber = @PoNumber AND Status = 'pending_payment';";
        checkCmd.Parameters.AddWithValue("@PoNumber", poNumber);
        var totalObj = await checkCmd.ExecuteScalarAsync(cancellationToken);
        if (totalObj is null) return null;
        var total = (decimal)totalObj;

        // Create Mandiri VA (outside transaction – external API call)
        var (vaNumber, vaExpiredAt) = await mandiriSnap.CreateVirtualAccountAsync(poNumber, total, cancellationToken);

        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.Transaction = (SqlTransaction)transaction;
        command.CommandText = """
            UPDATE dbo.Orders
            SET Status = 'paid',
                PaymentMethod = @PaymentMethod,
                VirtualAccount = @VirtualAccount,
                VaExpiredAt = @VaExpiredAt,
                PaidAt = COALESCE(PaidAt, SYSUTCDATETIME()),
                UpdatedAt = SYSUTCDATETIME()
            OUTPUT INSERTED.Id, INSERTED.UserEmail
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);
        command.Parameters.AddWithValue("@PaymentMethod", method);
        command.Parameters.AddWithValue("@VirtualAccount", vaNumber);
        command.Parameters.AddWithValue("@VaExpiredAt", vaExpiredAt);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            await transaction.RollbackAsync(cancellationToken);
            return null;
        }

        var orderId = reader.GetInt32(0);
        var userEmail = reader.IsDBNull(1) ? null : reader.GetString(1);
        await reader.CloseAsync();

        await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId,
            "Pembayaran Berhasil", $"Mandiri Virtual Account {vaNumber}", "paid", true, 20, cancellationToken);
        await AddNotificationAsync(connection, (SqlTransaction)transaction,
            "Pembayaran berhasil", $"Pembayaran {poNumber} melalui Mandiri Virtual Account telah diterima.", userEmail, cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new PaymentResponse(
            poNumber, method, vaNumber, total, "paid",
            vaExpiredAt, MandiriSnapService.HowToPayInstructions(vaNumber));
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
            OUTPUT INSERTED.Id, INSERTED.UserEmail
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);
        command.Parameters.AddWithValue("@Accepted", request.Accepted);
        command.Parameters.AddWithValue("@Status", request.Accepted ? "received" : "delivery_issue");

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }

        var orderId = reader.GetInt32(0);
        var userEmail = reader.IsDBNull(1) ? null : reader.GetString(1);
        await reader.CloseAsync();

        var title = request.Accepted ? "Barang Diterima" : "Barang Bermasalah";
        var subtitle = string.IsNullOrWhiteSpace(request.Notes) ? "Konfirmasi dari kios" : request.Notes!;
        await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId, title, subtitle, "received", true, 40, cancellationToken);
        await AddNotificationAsync(connection, (SqlTransaction)transaction, title, $"{poNumber}: {subtitle}", userEmail, cancellationToken);
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
        string? userEmail,
        CancellationToken cancellationToken)
    {
        var items = new List<NotificationDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT TOP 50 Id, Title, Description, CreatedAt, IsRead
            FROM dbo.Notifications
            WHERE UserEmail IS NULL OR UserEmail = @UserEmail
            ORDER BY CreatedAt DESC;
            """;
        command.Parameters.AddWithValue("@UserEmail", string.IsNullOrWhiteSpace(userEmail) ? DBNull.Value : userEmail);

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

    public static async Task MarkNotificationReadAsync(IConfiguration configuration, int id, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = "UPDATE dbo.Notifications SET IsRead = 1 WHERE Id = @Id;";
        command.Parameters.AddWithValue("@Id", id);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public static async Task MarkAllNotificationsReadAsync(IConfiguration configuration, string? userEmail, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE dbo.Notifications SET IsRead = 1 
            WHERE UserEmail IS NULL OR UserEmail = @UserEmail;
            """;
        command.Parameters.AddWithValue("@UserEmail", string.IsNullOrWhiteSpace(userEmail) ? DBNull.Value : userEmail);
        await command.ExecuteNonQueryAsync(cancellationToken);
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
        await ImportProductsFromCsvAsync(connection);

        await ExecuteAsync(connection, """
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

    private static async Task ImportProductsFromCsvAsync(SqlConnection connection)
    {
        var csvPath = Path.Combine(AppContext.BaseDirectory, "Data", "produk_202605291005.csv");
        if (!File.Exists(csvPath))
        {
            return;
        }

        using var parser = new TextFieldParser(csvPath)
        {
            TextFieldType = FieldType.Delimited,
            HasFieldsEnclosedInQuotes = true,
            TrimWhiteSpace = false
        };
        parser.SetDelimiters(",");
        _ = parser.ReadFields();

        while (!parser.EndOfData)
        {
            var fields = parser.ReadFields();
            if (fields is null || fields.Length < 12)
            {
                continue;
            }

            var product = ProductSeed.FromCsv(fields);
            if (product is null)
            {
                continue;
            }

            await UpsertProductAsync(connection, product);
        }
    }

    private static async Task UpsertProductAsync(SqlConnection connection, ProductSeed product)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            MERGE dbo.Products AS target
            USING (
                SELECT
                    @SourceProductId AS SourceProductId,
                    @ProductCode AS ProductCode,
                    @Name AS Name,
                    @Description AS Description,
                    @Category AS Category,
                    @Price AS Price,
                    @Unit AS Unit,
                    @IconName AS IconName,
                    @Status AS Status,
                    @Rating AS Rating,
                    @Specification AS Specification
            ) AS source
            ON target.ProductCode = source.ProductCode
               OR (target.ProductCode IS NULL AND target.Id = source.SourceProductId)
            WHEN MATCHED THEN
                UPDATE SET
                    ProductCode = source.ProductCode,
                    SourceProductId = source.SourceProductId,
                    Name = source.Name,
                    Description = source.Description,
                    Category = source.Category,
                    Price = source.Price,
                    Unit = source.Unit,
                    IconName = source.IconName,
                    Status = source.Status,
                    Rating = source.Rating,
                    Specification = source.Specification,
                    UpdatedAt = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN
                INSERT
                    (ProductCode, SourceProductId, Name, Description, Category, Price, Stock,
                     MinimumOrder, Unit, IconName, Status, Rating, Specification, CreatedAt, UpdatedAt)
                VALUES
                    (source.ProductCode, source.SourceProductId, source.Name, source.Description,
                     source.Category, source.Price, 1000, 1, source.Unit, source.IconName,
                     source.Status, source.Rating, source.Specification, SYSUTCDATETIME(), SYSUTCDATETIME());
            """;
        command.Parameters.AddWithValue("@SourceProductId", product.SourceProductId);
        command.Parameters.AddWithValue("@ProductCode", product.Code);
        command.Parameters.AddWithValue("@Name", product.Name);
        command.Parameters.AddWithValue("@Description", product.Description);
        command.Parameters.AddWithValue("@Category", product.Category);
        command.Parameters.AddWithValue("@Price", product.Price);
        command.Parameters.AddWithValue("@Unit", product.Unit);
        command.Parameters.AddWithValue("@IconName", product.IconName);
        command.Parameters.AddWithValue("@Status", product.Status);
        command.Parameters.AddWithValue("@Rating", product.Rating);
        command.Parameters.AddWithValue("@Specification", (object?)product.Specification ?? DBNull.Value);
        await command.ExecuteNonQueryAsync();
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
        string? userEmail,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """
            INSERT INTO dbo.Notifications (Title, Description, UserEmail)
            VALUES (@Title, @Description, @UserEmail);
            """;
        command.Parameters.AddWithValue("@Title", title);
        command.Parameters.AddWithValue("@Description", description);
        command.Parameters.AddWithValue("@UserEmail", (object?)userEmail ?? DBNull.Value);
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

}

sealed record ProductSeed(
    int SourceProductId,
    string Code,
    string Name,
    string Description,
    string Category,
    decimal Price,
    string Unit,
    string IconName,
    string Status,
    decimal Rating,
    string? Specification)
{
    public static ProductSeed? FromCsv(string[] fields)
    {
        if (!int.TryParse(fields[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var sourceId))
        {
            return null;
        }

        var code = Clean(fields[1]);
        var name = Clean(fields[2]);
        if (string.IsNullOrWhiteSpace(code) || string.IsNullOrWhiteSpace(name))
        {
            return null;
        }

        var description = Clean(fields[3]);
        var category = Clean(fields[4]) == "1" ? "Subsidi" : "Retail";
        var price = decimal.TryParse(Clean(fields[5]), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsedPrice)
            ? parsedPrice
            : 0m;
        var status = string.IsNullOrWhiteSpace(Clean(fields[6])) ? "Aktif" : Clean(fields[6]);
        var unit = string.IsNullOrWhiteSpace(Clean(fields[9])) ? "TON" : Clean(fields[9]);
        var rating = decimal.TryParse(Clean(fields[10]), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsedRating)
            ? parsedRating
            : 0m;
        var specification = string.IsNullOrWhiteSpace(Clean(fields[11])) ? null : Clean(fields[11]);

        return new ProductSeed(
            sourceId,
            code,
            name,
            string.IsNullOrWhiteSpace(description) ? "-" : description,
            category,
            price,
            unit,
            IconFor(name),
            status,
            rating,
            specification);
    }

    private static string Clean(string? value) => (value ?? string.Empty).Trim();

    private static string IconFor(string name)
    {
        var normalized = name.ToLowerInvariant();
        if (normalized.Contains("urea")) return "water_drop";
        if (normalized.Contains("petro") || normalized.Contains("dolomit")) return "spa";
        return "eco";
    }
}
