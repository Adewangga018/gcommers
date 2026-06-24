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

        IF OBJECT_ID(N'dbo.ProductRegionPrices', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.ProductRegionPrices') AND name = 'QtyAvailable')
        BEGIN
            -- Old schema (flat BiayaPengiriman + PajakPpnPersen, keyed by ProductId) predates the
            -- product_master/qty_available redesign on the Laravel side; safe to rebuild since this
            -- table is just a mirror of product_region_prices, repopulated on each stock approval.
            DROP TABLE dbo.ProductRegionPrices;
        END

        IF OBJECT_ID(N'dbo.ProductRegionPrices', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.ProductRegionPrices
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProductRegionPrices PRIMARY KEY,
                ProductCode NVARCHAR(50) NOT NULL,
                ProductName NVARCHAR(200) NOT NULL,
                SourceProductId INT NULL,
                Region NVARCHAR(100) NOT NULL,
                QtyAvailable DECIMAL(12,2) NOT NULL CONSTRAINT DF_PRP_QtyAvailable DEFAULT 0,
                HargaSatuan DECIMAL(15,2) NOT NULL CONSTRAINT DF_PRP_HargaSatuan DEFAULT 0,
                BiayaPengirimanPerKg DECIMAL(10,2) NOT NULL CONSTRAINT DF_PRP_BiayaPengirimanPerKg DEFAULT 0,
                PajakPphPersen DECIMAL(5,2) NOT NULL CONSTRAINT DF_PRP_PajakPph DEFAULT 0.25,
                EffectiveFrom DATETIMEOFFSET NULL,
                SetBy NVARCHAR(256) NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_PRP_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_PRP_UpdatedAt DEFAULT SYSUTCDATETIME(),
                CONSTRAINT UX_ProductRegionPrices UNIQUE (ProductCode, Region)
            );
        END

        -- ───────────────────────────────────────────────────────────────
        -- Transport / Shipments / Route checks (for tracking & dummy data)
        -- ───────────────────────────────────────────────────────────────
        IF OBJECT_ID(N'dbo.Shipments', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Shipments
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Shipments PRIMARY KEY,
                ShipmentNumber NVARCHAR(50) NOT NULL,
                OrderId INT NULL,
                DriverName NVARCHAR(200) NULL,
                Status NVARCHAR(50) NOT NULL CONSTRAINT DF_Shipments_Status DEFAULT N'siap_muat',
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Shipments_CreatedAt DEFAULT SYSUTCDATETIME(),
                MuatInCompletedAt DATETIMEOFFSET NULL,
                MuatOutCompletedAt DATETIMEOFFSET NULL,
                CompletedAt DATETIMEOFFSET NULL,
                TotalDistanceMeters DECIMAL(18,2) NOT NULL CONSTRAINT DF_Shipments_TotalDistance DEFAULT 0,
                UpdatedAt DATETIMEOFFSET NULL,
                TransportirEmail NVARCHAR(256) NULL,
                TruckLabel NVARCHAR(200) NULL,
                PoliceNumber NVARCHAR(50) NULL,
                DestinationLabel NVARCHAR(200) NULL,
                DestinationAddress NVARCHAR(500) NULL,
                OriginLat DECIMAL(9,6) NULL,
                OriginLng DECIMAL(9,6) NULL,
                DestinationLat DECIMAL(9,6) NULL,
                DestinationLng DECIMAL(9,6) NULL,

                CONSTRAINT UX_Shipments_ShipmentNumber UNIQUE (ShipmentNumber),
                CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id)
            );
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'TransportirEmail')
                ALTER TABLE dbo.Shipments ADD TransportirEmail NVARCHAR(256) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'TruckLabel')
                ALTER TABLE dbo.Shipments ADD TruckLabel NVARCHAR(200) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'PoliceNumber')
                ALTER TABLE dbo.Shipments ADD PoliceNumber NVARCHAR(50) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'DestinationLabel')
                ALTER TABLE dbo.Shipments ADD DestinationLabel NVARCHAR(200) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'DestinationAddress')
                ALTER TABLE dbo.Shipments ADD DestinationAddress NVARCHAR(500) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'OriginLat')
                ALTER TABLE dbo.Shipments ADD OriginLat DECIMAL(9,6) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'OriginLng')
                ALTER TABLE dbo.Shipments ADD OriginLng DECIMAL(9,6) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'DestinationLat')
                ALTER TABLE dbo.Shipments ADD DestinationLat DECIMAL(9,6) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Shipments') AND name = 'DestinationLng')
                ALTER TABLE dbo.Shipments ADD DestinationLng DECIMAL(9,6) NULL;
        END

        IF OBJECT_ID(N'dbo.ShipmentRouteChecks', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.ShipmentRouteChecks
            (
                Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ShipmentRouteChecks PRIMARY KEY,
                ShipmentId INT NOT NULL,
                CheckType NVARCHAR(20) NOT NULL CONSTRAINT DF_ShipmentRouteChecks_CheckType DEFAULT N'load_out',
                ExpectedDistanceMeters DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShipmentRouteChecks_ExpectedDistance DEFAULT 0,
                ActualDistanceMeters DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShipmentRouteChecks_ActualDistance DEFAULT 0,
                DistanceDiffMeters DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShipmentRouteChecks_Diff DEFAULT 0,
                Notes NVARCHAR(500) NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_ShipmentRouteChecks_CreatedAt DEFAULT SYSUTCDATETIME(),

                CONSTRAINT FK_ShipmentRouteChecks_Shipments FOREIGN KEY (ShipmentId) REFERENCES dbo.Shipments(Id)
            );

            CREATE INDEX IX_ShipmentRouteChecks_ShipmentId_CreatedAt
                ON dbo.ShipmentRouteChecks(ShipmentId, CreatedAt DESC);
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
                VirtualAccount NVARCHAR(30) NULL,
                VaExpiredAt DATETIMEOFFSET NULL,
                Subtotal DECIMAL(18,2) NOT NULL,
                ShippingAmount DECIMAL(18,2) NOT NULL,
                TotalAmount DECIMAL(18,2) NOT NULL,
                CreatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT SYSUTCDATETIME(),
                UpdatedAt DATETIMEOFFSET NOT NULL CONSTRAINT DF_Orders_UpdatedAt DEFAULT SYSUTCDATETIME(),
                PaidAt DATETIMEOFFSET NULL,
                DeliveredAt DATETIMEOFFSET NULL,
                OrderStatus NVARCHAR(50) NULL,
                OrderStatusNote NVARCHAR(500) NULL,
                DeliveryAddress NVARCHAR(500) NULL,
                DeliveryKelurahan NVARCHAR(150) NULL,
                DeliveryKodePos NVARCHAR(10) NULL,
                DeliveryLatitude DECIMAL(10,6) NULL,
                DeliveryLongitude DECIMAL(10,6) NULL,
                KioskRegion NVARCHAR(100) NULL,
                KioskKabupaten NVARCHAR(150) NULL,
                KioskKecamatan NVARCHAR(150) NULL,
                GudangSubmissionId BIGINT NULL,
                GudangNama NVARCHAR(200) NULL
            );

            CREATE UNIQUE INDEX UX_Orders_PoNumber ON dbo.Orders(PoNumber);
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'VirtualAccount')
                ALTER TABLE dbo.Orders ADD VirtualAccount NVARCHAR(30) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'VaExpiredAt')
                ALTER TABLE dbo.Orders ADD VaExpiredAt DATETIMEOFFSET NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'OrderStatus')
                ALTER TABLE dbo.Orders ADD OrderStatus NVARCHAR(50) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'OrderStatusNote')
                ALTER TABLE dbo.Orders ADD OrderStatusNote NVARCHAR(500) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'DeliveryAddress')
                ALTER TABLE dbo.Orders ADD DeliveryAddress NVARCHAR(500) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'DeliveryKelurahan')
                ALTER TABLE dbo.Orders ADD DeliveryKelurahan NVARCHAR(150) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'DeliveryKodePos')
                ALTER TABLE dbo.Orders ADD DeliveryKodePos NVARCHAR(10) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'DeliveryLatitude')
                ALTER TABLE dbo.Orders ADD DeliveryLatitude DECIMAL(10,6) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'DeliveryLongitude')
                ALTER TABLE dbo.Orders ADD DeliveryLongitude DECIMAL(10,6) NULL;
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'TaxAmount')
                ALTER TABLE dbo.Orders DROP COLUMN TaxAmount;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'KioskRegion')
                ALTER TABLE dbo.Orders ADD KioskRegion NVARCHAR(100) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'KioskKabupaten')
                ALTER TABLE dbo.Orders ADD KioskKabupaten NVARCHAR(150) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'KioskKecamatan')
                ALTER TABLE dbo.Orders ADD KioskKecamatan NVARCHAR(150) NULL;
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'GudangNama')
                ALTER TABLE dbo.Orders ADD GudangNama NVARCHAR(200) NULL;
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Orders') AND name = 'GudangId')
                ALTER TABLE dbo.Orders DROP COLUMN GudangId;
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
        string? region,
        string? kecamatan,
        CancellationToken cancellationToken)
    {
        var products = new List<ProductDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        // kecamatan names aren't unique nationally (e.g. several "Genteng" kecamatan exist in
        // different provinces), so kecamatan alone is not a safe lookup key -- region must be
        // matched too, same as the compound key used in kecamatan_product_prices/_stocks.
        var hasKecamatan = !string.IsNullOrWhiteSpace(kecamatan) && !string.IsNullOrWhiteSpace(region);
        var hasRegion = !hasKecamatan && !string.IsNullOrWhiteSpace(region);

        if (hasKecamatan)
        {
            // dbo.kecamatan_product_prices / dbo.kecamatan_product_stocks are managed by the admin
            // console (subsidy quota per kecamatan) and are the source of truth for kiosk pricing now
            // that kiosks are registered against a specific kecamatan. Stock is allocated monthly.
            // kecamatan_product_prices has no pph_persen column, so PPh falls back to the standard 0.25.
            command.CommandText = """
                SELECT p.Id, COALESCE(p.ProductCode, ''), p.Name, p.Description, p.Category,
                       kpp.harga_satuan, CAST(kps.quota_ton AS INT), p.MinimumOrder, p.Unit, p.IconName,
                       p.Status, p.Rating, p.Specification,
                       kpp.biaya_pengiriman, 0.25
                FROM dbo.Products p
                INNER JOIN dbo.kecamatan_product_prices kpp
                    ON kpp.product_code = p.ProductCode AND kpp.kecamatan = @Kecamatan AND kpp.region = @Region
                INNER JOIN dbo.kecamatan_product_stocks kps
                    ON kps.product_code = p.ProductCode AND kps.kecamatan = @Kecamatan AND kps.region = @Region AND kps.period = @Period
                WHERE (@Category IS NULL OR p.Category = @Category)
                  AND p.Status = N'Aktif'
                  AND kps.quota_ton > 0
                ORDER BY p.Id;
                """;
            command.Parameters.AddWithValue("@Kecamatan", kecamatan);
            command.Parameters.AddWithValue("@Region", region);
            command.Parameters.AddWithValue("@Period", CurrentPeriod());
        }
        else if (hasRegion)
        {
            // Only return products that have an approved regional price + stock for this region.
            // dbo.product_region_prices is the externally-managed source of truth for region
            // pricing/stock (separate from dbo.Products' own auto-increment ids), so ProductCode
            // is the join key both sides agree on.
            command.CommandText = """
                SELECT p.Id, COALESCE(p.ProductCode, ''), p.Name, p.Description, p.Category,
                       rp.harga_satuan, CAST(rp.qty_available AS INT), p.MinimumOrder, p.Unit, p.IconName,
                       p.Status, p.Rating, p.Specification,
                       rp.biaya_pengiriman_per_kg, rp.pajak_pph_persen
                FROM dbo.Products p
                INNER JOIN dbo.product_region_prices rp
                    ON rp.product_code = p.ProductCode AND rp.region = @Region
                WHERE (@Category IS NULL OR p.Category = @Category)
                  AND p.Status = N'Aktif'
                  AND rp.qty_available > 0
                ORDER BY p.Id;
                """;
            command.Parameters.AddWithValue("@Region", region);
        }
        else
        {
            command.CommandText = """
                SELECT Id, COALESCE(ProductCode, ''), Name, Description, Category, Price, Stock,
                       MinimumOrder, Unit, IconName, Status, Rating, Specification,
                       50.0, 0.25
                FROM dbo.Products
                WHERE (@Category IS NULL OR Category = @Category)
                  AND Status = N'Aktif'
                ORDER BY Id;
                """;
        }

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
                reader.IsDBNull(12) ? null : reader.GetString(12),
                reader.GetDecimal(13),
                reader.GetDecimal(14)));
        }

        return products;
    }

    public static async Task UpsertProductRegionPriceAsync(
        IConfiguration configuration,
        UpsertProductRegionPriceRequest req,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            MERGE dbo.ProductRegionPrices AS target
            USING (SELECT @ProductCode AS ProductCode, @Region AS Region) AS source
            ON target.ProductCode = source.ProductCode AND target.Region = source.Region
            WHEN MATCHED THEN
                UPDATE SET
                    ProductName          = @ProductName,
                    SourceProductId      = @SourceProductId,
                    HargaSatuan          = @HargaSatuan,
                    BiayaPengirimanPerKg = @BiayaPengirimanPerKg,
                    PajakPphPersen       = @PajakPphPersen,
                    QtyAvailable         = @QtyAvailable,
                    EffectiveFrom        = SYSUTCDATETIME(),
                    SetBy                = @SetBy,
                    UpdatedAt            = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN
                INSERT (ProductCode, ProductName, SourceProductId, Region, QtyAvailable, HargaSatuan,
                        BiayaPengirimanPerKg, PajakPphPersen, EffectiveFrom, SetBy)
                VALUES (@ProductCode, @ProductName, @SourceProductId, @Region, @QtyAvailable, @HargaSatuan,
                        @BiayaPengirimanPerKg, @PajakPphPersen, SYSUTCDATETIME(), @SetBy);
            """;
        command.Parameters.AddWithValue("@ProductCode", req.ProductCode);
        command.Parameters.AddWithValue("@ProductName", req.ProductName);
        command.Parameters.AddWithValue("@SourceProductId", req.ProductId);
        command.Parameters.AddWithValue("@Region", req.Region);
        command.Parameters.AddWithValue("@QtyAvailable", req.QtyAvailable);
        command.Parameters.AddWithValue("@HargaSatuan", req.HargaSatuan);
        command.Parameters.AddWithValue("@BiayaPengirimanPerKg", req.BiayaPengirimanPerKg);
        command.Parameters.AddWithValue("@PajakPphPersen", req.PajakPphPersen);
        command.Parameters.AddWithValue("@SetBy", (object?)req.SetBy ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
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
            var hasKecamatan = !string.IsNullOrWhiteSpace(request.Kecamatan) && !string.IsNullOrWhiteSpace(request.Region);
            var hasRegion = !hasKecamatan && !string.IsNullOrWhiteSpace(request.Region);
            var period = CurrentPeriod();
            var orderItems = new List<(int ProductId, string ProductCode, string Name, string Unit, int Quantity, decimal UnitPrice, decimal TotalPrice)>();
            var totalShipping = 0m;

            foreach (var item in request.Items)
            {
                await using var productCommand = connection.CreateCommand();
                productCommand.Transaction = (SqlTransaction)transaction;

                if (hasKecamatan)
                {
                    // dbo.kecamatan_product_prices / dbo.kecamatan_product_stocks are managed by the
                    // admin console (subsidy quota per kecamatan); ProductCode is the join key, scoped
                    // by region+kecamatan since kecamatan names aren't unique nationally. That table has
                    // no pph_persen column, so PPh falls back to the standard 0.25.
                    productCommand.CommandText = """
                        SELECT p.Name, p.Unit, COALESCE(p.ProductCode, ''), kpp.harga_satuan,
                               kps.quota_ton, kpp.biaya_pengiriman, 0.25
                        FROM dbo.Products p
                        INNER JOIN dbo.kecamatan_product_prices kpp
                            ON kpp.product_code = p.ProductCode AND kpp.kecamatan = @Kecamatan AND kpp.region = @Region
                        INNER JOIN dbo.kecamatan_product_stocks kps
                            ON kps.product_code = p.ProductCode AND kps.kecamatan = @Kecamatan AND kps.region = @Region AND kps.period = @Period
                        WHERE p.Id = @Id;
                        """;
                    productCommand.Parameters.AddWithValue("@Kecamatan", request.Kecamatan!);
                    productCommand.Parameters.AddWithValue("@Region", request.Region!);
                    productCommand.Parameters.AddWithValue("@Period", period);
                }
                else if (hasRegion)
                {
                    // ProductCode is the join key: dbo.product_region_prices and dbo.Products
                    // have independent id sequences.
                    productCommand.CommandText = """
                        SELECT p.Name, p.Unit, COALESCE(p.ProductCode, ''), rp.harga_satuan,
                               rp.qty_available, rp.biaya_pengiriman_per_kg, rp.pajak_pph_persen
                        FROM dbo.Products p
                        INNER JOIN dbo.product_region_prices rp
                            ON rp.product_code = p.ProductCode AND rp.region = @Region
                        WHERE p.Id = @Id;
                        """;
                    productCommand.Parameters.AddWithValue("@Region", request.Region!);
                }
                else
                {
                    productCommand.CommandText = "SELECT Name, Unit, COALESCE(ProductCode, ''), Price, Stock, 50.0, 0.25 FROM dbo.Products WHERE Id = @Id;";
                }
                productCommand.Parameters.AddWithValue("@Id", item.ProductId);

                string name, unit, productCode;
                decimal price, qtyAvailable, biayaPengirimanPerKg;

                await using (var reader = await productCommand.ExecuteReaderAsync(cancellationToken))
                {
                    if (!await reader.ReadAsync(cancellationToken))
                    {
                        throw new InvalidOperationException(hasKecamatan
                            ? $"Produk {item.ProductId} tidak tersedia di kecamatan {request.Kecamatan}."
                            : hasRegion
                                ? $"Produk {item.ProductId} tidak tersedia di region {request.Region}."
                                : $"Produk {item.ProductId} tidak ditemukan.");
                    }

                    name = reader.GetString(0);
                    unit = reader.GetString(1);
                    productCode = reader.GetString(2);
                    price = reader.GetDecimal(3);
                    qtyAvailable = reader.GetDecimal(4);
                    biayaPengirimanPerKg = reader.GetDecimal(5);
                }

                if (qtyAvailable < item.Quantity)
                {
                    throw new InvalidOperationException($"Stok {name} tidak cukup.");
                }

                // qty dipesan dalam satuan TON; tarif ongkir region dalam Rp/kg.
                var beratKg = item.Quantity * 1000m;
                totalShipping += biayaPengirimanPerKg * beratKg;
                // harga_satuan dalam Rp/kg; untuk produk satuan TON, qty dipesan dalam TON jadi
                // harus dikonversi ke kg dulu sebelum dikalikan harga.
                var isTonUnit = string.Equals(unit, "TON", StringComparison.OrdinalIgnoreCase);
                var totalPrice = isTonUnit ? price * item.Quantity * 1000m : price * item.Quantity;
                orderItems.Add((item.ProductId, productCode, name, unit, item.Quantity, price, totalPrice));
            }

            var subtotal = orderItems.Sum(item => item.TotalPrice);
            var shipping = Math.Round(totalShipping, 2);
            var total = subtotal + shipping;
            // Kode pemesanan sementara - diganti kode pembayaran resmi (GCS-{tahun}-{urutan}) oleh PayOrderAsync saat bayar sukses.
            var orderCode = $"ORD-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString("N")[..8]}";
            var vendor = await GetVendorForUserAsync(connection, (SqlTransaction)transaction, request.UserEmail, cancellationToken);

            string? deliveryAddress = null, deliveryKelurahan = null, deliveryKodePos = null;
            decimal? deliveryLatitude = null, deliveryLongitude = null;
            string? kioskRegion = null, kioskKabupaten = null, kioskKecamatan = null, gudangNama = null;
            long? gudangSubmissionId = null;
            if (!string.IsNullOrWhiteSpace(request.UserEmail))
            {
                await using var addressCommand = connection.CreateCommand();
                addressCommand.Transaction = (SqlTransaction)transaction;
                // kab/kec diambil live dari dbo.kabupaten/dbo.kecamatan (bukan kolom cache di Users)
                // supaya tidak terikut data stale; gudang aktif = status 'approved' di gudang_submissions
                // (dikelola admin console) untuk kecamatan kios tersebut, ambil yang terbaru jika lebih dari satu.
                addressCommand.CommandText = """
                    SELECT u.Address, u.Kelurahan, u.KodePos, u.Latitude, u.Longitude,
                           u.Region, kab.nama_kab, kec.nama_kec, g.Id, g.nama_gudang
                    FROM dbo.Users u
                    LEFT JOIN dbo.kabupaten kab ON kab.id = u.KabupatenId
                    LEFT JOIN dbo.kecamatan kec ON kec.id = u.KecamatanId
                    OUTER APPLY (
                        SELECT TOP 1 gs.id AS Id, gs.nama_gudang
                        FROM dbo.gudang_submissions gs
                        WHERE gs.kecamatan_id = u.KecamatanId AND gs.status = 'approved'
                        ORDER BY gs.id DESC
                    ) g
                    WHERE u.Email = @Email;
                    """;
                addressCommand.Parameters.AddWithValue("@Email", request.UserEmail!);
                await using var addressReader = await addressCommand.ExecuteReaderAsync(cancellationToken);
                if (await addressReader.ReadAsync(cancellationToken))
                {
                    deliveryAddress = addressReader.IsDBNull(0) ? null : addressReader.GetString(0);
                    deliveryKelurahan = addressReader.IsDBNull(1) ? null : addressReader.GetString(1);
                    deliveryKodePos = addressReader.IsDBNull(2) ? null : addressReader.GetString(2);
                    deliveryLatitude = addressReader.IsDBNull(3) ? null : addressReader.GetDecimal(3);
                    deliveryLongitude = addressReader.IsDBNull(4) ? null : addressReader.GetDecimal(4);
                    kioskRegion = addressReader.IsDBNull(5) ? null : addressReader.GetString(5);
                    kioskKabupaten = addressReader.IsDBNull(6) ? null : addressReader.GetString(6);
                    kioskKecamatan = addressReader.IsDBNull(7) ? null : addressReader.GetString(7);
                    gudangSubmissionId = addressReader.IsDBNull(8) ? null : addressReader.GetInt64(8);
                    gudangNama = addressReader.IsDBNull(9) ? null : addressReader.GetString(9);
                }
            }

            await using var orderCommand = connection.CreateCommand();
            orderCommand.Transaction = (SqlTransaction)transaction;
            orderCommand.CommandText = """
                INSERT INTO dbo.Orders
                (PoNumber, UserEmail, Status, Vendor, PaymentMethod, Subtotal, ShippingAmount, TotalAmount,
                 DeliveryAddress, DeliveryKelurahan, DeliveryKodePos, DeliveryLatitude, DeliveryLongitude,
                 KioskRegion, KioskKabupaten, KioskKecamatan, GudangSubmissionId, GudangNama)
                OUTPUT INSERTED.Id
                VALUES
                (@PoNumber, @UserEmail, 'pending_payment', @Vendor, '-', @Subtotal, @ShippingAmount, @TotalAmount,
                 @DeliveryAddress, @DeliveryKelurahan, @DeliveryKodePos, @DeliveryLatitude, @DeliveryLongitude,
                 @KioskRegion, @KioskKabupaten, @KioskKecamatan, @GudangSubmissionId, @GudangNama);
                """;
            orderCommand.Parameters.AddWithValue("@PoNumber", orderCode);
            orderCommand.Parameters.AddWithValue("@UserEmail", (object?)request.UserEmail ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@Vendor", vendor);
            orderCommand.Parameters.AddWithValue("@Subtotal", subtotal);
            orderCommand.Parameters.AddWithValue("@ShippingAmount", shipping);
            orderCommand.Parameters.AddWithValue("@DeliveryAddress", (object?)deliveryAddress ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@DeliveryKelurahan", (object?)deliveryKelurahan ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@DeliveryKodePos", (object?)deliveryKodePos ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@DeliveryLatitude", (object?)deliveryLatitude ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@DeliveryLongitude", (object?)deliveryLongitude ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@KioskRegion", (object?)kioskRegion ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@KioskKabupaten", (object?)kioskKabupaten ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@KioskKecamatan", (object?)kioskKecamatan ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@GudangSubmissionId", (object?)gudangSubmissionId ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@GudangNama", (object?)gudangNama ?? DBNull.Value);
            orderCommand.Parameters.AddWithValue("@TotalAmount", total);
            var orderId = Convert.ToInt32(await orderCommand.ExecuteScalarAsync(cancellationToken));

            foreach (var item in orderItems)
            {
                await using var itemCommand = connection.CreateCommand();
                itemCommand.Transaction = (SqlTransaction)transaction;
                itemCommand.CommandText = hasKecamatan
                    ? """
                        INSERT INTO dbo.OrderItems
                        (OrderId, ProductId, ProductName, Unit, Quantity, UnitPrice, TotalPrice)
                        VALUES
                        (@OrderId, @ProductId, @ProductName, @Unit, @Quantity, @UnitPrice, @TotalPrice);

                        UPDATE dbo.kecamatan_product_stocks
                        SET quota_ton = quota_ton - @Quantity
                        WHERE product_code = @ProductCode AND kecamatan = @Kecamatan AND region = @Region AND period = @Period;
                        """
                    : hasRegion
                        ? """
                            INSERT INTO dbo.OrderItems
                            (OrderId, ProductId, ProductName, Unit, Quantity, UnitPrice, TotalPrice)
                            VALUES
                            (@OrderId, @ProductId, @ProductName, @Unit, @Quantity, @UnitPrice, @TotalPrice);

                            UPDATE dbo.product_region_prices
                            SET qty_available = qty_available - @Quantity
                            WHERE product_code = @ProductCode AND region = @Region;
                            """
                        : """
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
                if (hasKecamatan)
                {
                    itemCommand.Parameters.AddWithValue("@ProductCode", item.ProductCode);
                    itemCommand.Parameters.AddWithValue("@Kecamatan", request.Kecamatan!);
                    itemCommand.Parameters.AddWithValue("@Region", request.Region!);
                    itemCommand.Parameters.AddWithValue("@Period", period);
                }
                else if (hasRegion)
                {
                    itemCommand.Parameters.AddWithValue("@ProductCode", item.ProductCode);
                    itemCommand.Parameters.AddWithValue("@Region", request.Region!);
                }
                await itemCommand.ExecuteNonQueryAsync(cancellationToken);
            }

            await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId, "Pesanan Dibuat", "Menunggu pembayaran", "created", true, 10, cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return await GetOrderDetailAsync(configuration, orderCode, cancellationToken)
                ?? throw new InvalidOperationException("Pesanan gagal dibuat.");
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static async Task<string> GetVendorForUserAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        string? userEmail,
        CancellationToken cancellationToken)
    {
        const string fallbackVendor = "PT Global Logistik Nusantara";
        if (string.IsNullOrWhiteSpace(userEmail))
        {
            return fallbackVendor;
        }

        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = "SELECT Region FROM dbo.Users WHERE Email = @Email;";
        command.Parameters.AddWithValue("@Email", userEmail);
        var regionObj = await command.ExecuteScalarAsync(cancellationToken);
        return regionObj is string region && !string.IsNullOrWhiteSpace(region) ? region : fallbackVendor;
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
                COUNT(oi.Id) AS ItemCount,
                o.OrderStatus,
                o.PaidAt
            FROM dbo.Orders o
            LEFT JOIN dbo.OrderItems oi ON oi.OrderId = o.Id
            WHERE @UserEmail IS NULL OR o.UserEmail = @UserEmail
            GROUP BY o.PoNumber, o.Status, o.TotalAmount, o.CreatedAt, o.PaymentMethod, o.OrderStatus, o.PaidAt
            ORDER BY o.CreatedAt DESC;
            """;
        command.Parameters.AddWithValue("@UserEmail", string.IsNullOrWhiteSpace(userEmail) ? DBNull.Value : userEmail);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var status = reader.GetString(1);
            var orderStatus = reader.IsDBNull(6) ? null : reader.GetString(6);
            var paidAt = reader.IsDBNull(7) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(7);
            var (paymentStatus, paymentStatusLabel) = DerivePaymentStatus(paidAt);
            orders.Add(new OrderSummaryDto(
                reader.GetString(0),
                status,
                ToStatusLabel(status),
                reader.GetDecimal(2),
                reader.GetFieldValue<DateTimeOffset>(3),
                reader.GetString(4),
                reader.GetInt32(5),
                orderStatus,
                ToOrderStatusLabel(orderStatus),
                paymentStatus,
                paymentStatusLabel));
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
            SELECT Id, PoNumber, Status, Vendor, PaymentMethod, Subtotal, ShippingAmount,
                   TotalAmount, CreatedAt, PaidAt, DeliveredAt, OrderStatus, OrderStatusNote,
                   DeliveryAddress, DeliveryKelurahan, DeliveryKodePos, DeliveryLatitude, DeliveryLongitude
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
            ShippingAmount = reader.GetDecimal(6),
            TotalAmount = reader.GetDecimal(7),
            CreatedAt = reader.GetFieldValue<DateTimeOffset>(8),
            PaidAt = reader.IsDBNull(9) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(9),
            DeliveredAt = reader.IsDBNull(10) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(10),
            OrderStatus = reader.IsDBNull(11) ? null : reader.GetString(11),
            OrderStatusNote = reader.IsDBNull(12) ? null : reader.GetString(12),
            DeliveryAddress = reader.IsDBNull(13) ? null : reader.GetString(13),
            DeliveryKelurahan = reader.IsDBNull(14) ? null : reader.GetString(14),
            DeliveryKodePos = reader.IsDBNull(15) ? null : reader.GetString(15),
            DeliveryLatitude = reader.IsDBNull(16) ? (double?)null : (double)reader.GetDecimal(16),
            DeliveryLongitude = reader.IsDBNull(17) ? (double?)null : (double)reader.GetDecimal(17)
        };
        await reader.CloseAsync();

        var items = await GetOrderItemsAsync(connection, orderId, cancellationToken);
        var timeline = await GetOrderTimelineAsync(connection, orderId, cancellationToken);
        var (paymentStatus, paymentStatusLabel) = DerivePaymentStatus(detail.PaidAt);

        return new OrderDetailDto(
            detail.PoNumber,
            detail.Status,
            ToStatusLabel(detail.Status),
            detail.Vendor,
            detail.PaymentMethod,
            detail.Subtotal,
            detail.ShippingAmount,
            detail.TotalAmount,
            detail.CreatedAt,
            detail.PaidAt,
            detail.DeliveredAt,
            items,
            timeline,
            detail.OrderStatus,
            ToOrderStatusLabel(detail.OrderStatus),
            detail.OrderStatusNote,
            paymentStatus,
            paymentStatusLabel,
            detail.DeliveryAddress,
            detail.DeliveryKelurahan,
            detail.DeliveryKodePos,
            detail.DeliveryLatitude,
            detail.DeliveryLongitude);
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

        // Kode pembayaran resmi (PoNumber final) - kontrak §4: GCS-{tahun}-{urutan}, atomic increment per tahun.
        var finalPoNumber = await GenerateFinalPoNumberAsync(connection, (SqlTransaction)transaction, cancellationToken);

        await using var command = connection.CreateCommand();
        command.Transaction = (SqlTransaction)transaction;
        command.CommandText = """
            UPDATE dbo.Orders
            SET PoNumber = @FinalPoNumber,
                Status = 'paid',
                OrderStatus = 'processing',
                PaymentMethod = @PaymentMethod,
                VirtualAccount = @VirtualAccount,
                VaExpiredAt = @VaExpiredAt,
                PaidAt = COALESCE(PaidAt, SYSUTCDATETIME()),
                UpdatedAt = SYSUTCDATETIME()
            OUTPUT INSERTED.Id, INSERTED.UserEmail
            WHERE PoNumber = @PoNumber;
            """;
        command.Parameters.AddWithValue("@PoNumber", poNumber);
        command.Parameters.AddWithValue("@FinalPoNumber", finalPoNumber);
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
            "Pembayaran berhasil", $"Pembayaran {finalPoNumber} melalui Mandiri Virtual Account telah diterima.", userEmail, cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new PaymentResponse(
            finalPoNumber, method, vaNumber, total, "paid",
            vaExpiredAt, MandiriSnapService.HowToPayInstructions(vaNumber));
    }

    private static async Task<string> GenerateFinalPoNumberAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """
            DECLARE @year INT = YEAR(GETDATE());
            DECLARE @seq INT;

            UPDATE dbo.order_code_counters
            SET last_seq = last_seq + 1, @seq = last_seq + 1, updated_at = SYSDATETIME()
            WHERE year = @year;

            IF @@ROWCOUNT = 0
            BEGIN
                SET @seq = 1;
                INSERT INTO dbo.order_code_counters (year, last_seq, updated_at) VALUES (@year, 1, SYSDATETIME());
            END

            SELECT 'GCS-' + CAST(@year AS NVARCHAR(4)) + '-' + CAST(@seq AS NVARCHAR(10));
            """;
        var result = await command.ExecuteScalarAsync(cancellationToken);
        return (string)result!;
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
        var now = DateTimeOffset.UtcNow;
        var monthlySales = orders
            .Where(order => order.CreatedAt.Year == now.Year && order.CreatedAt.Month == now.Month)
            .Sum(order => order.TotalAmount);
        return new DashboardSummaryDto(active, completed, monthlySales, orders.Take(5).ToList());
    }

    public static async Task<IReadOnlyList<ShipmentSummaryDto>> GetShipmentsAsync(
        IConfiguration configuration,
        string? transportirEmail,
        CancellationToken cancellationToken)
    {
        var shipments = new List<ShipmentSummaryDto>();
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = ShipmentSelectSql + """
            WHERE @TransportirEmail IS NULL OR s.TransportirEmail IS NULL OR s.TransportirEmail = @TransportirEmail
            ORDER BY s.CreatedAt DESC;
            """;
        command.Parameters.AddWithValue("@TransportirEmail", string.IsNullOrWhiteSpace(transportirEmail) ? DBNull.Value : transportirEmail);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            shipments.Add(MapShipmentRow(reader));
        }

        return shipments;
    }

    public static async Task<ShipmentSummaryDto?> GetShipmentByNumberAsync(
        IConfiguration configuration,
        string shipmentNumber,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = ShipmentSelectSql + "WHERE s.ShipmentNumber = @ShipmentNumber;";
        command.Parameters.AddWithValue("@ShipmentNumber", shipmentNumber);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? MapShipmentRow(reader) : null;
    }

    private const string ShipmentSelectSql = """
        SELECT s.ShipmentNumber, s.Status, COALESCE(s.DriverName, ''), s.TruckLabel, s.PoliceNumber,
               s.DestinationLabel, s.DestinationAddress, s.OriginLat, s.OriginLng, s.DestinationLat, s.DestinationLng,
               s.CreatedAt, s.CompletedAt, s.OrderId, o.PoNumber, w.name, w.address,
               s.MuatInPhotoUrl, s.MuatOutPhotoUrl, s.Note, s.AssignedBy, s.MuatInCompletedAt, s.MuatOutCompletedAt
        FROM dbo.Shipments s
        LEFT JOIN dbo.Orders o ON o.Id = s.OrderId
        LEFT JOIN dbo.warehouses w ON w.id = s.WarehouseId

        """;

    private static ShipmentSummaryDto MapShipmentRow(SqlDataReader reader)
    {
        var status = reader.GetString(1);
        return new ShipmentSummaryDto(
            reader.GetString(0),
            status,
            ToShipmentStatusLabel(status),
            reader.GetString(2),
            reader.IsDBNull(3) ? null : reader.GetString(3),
            reader.IsDBNull(4) ? null : reader.GetString(4),
            reader.IsDBNull(5) ? null : reader.GetString(5),
            reader.IsDBNull(6) ? null : reader.GetString(6),
            reader.IsDBNull(7) ? null : (double)reader.GetDecimal(7),
            reader.IsDBNull(8) ? null : (double)reader.GetDecimal(8),
            reader.IsDBNull(9) ? null : (double)reader.GetDecimal(9),
            reader.IsDBNull(10) ? null : (double)reader.GetDecimal(10),
            reader.GetFieldValue<DateTimeOffset>(11),
            reader.IsDBNull(12) ? null : reader.GetFieldValue<DateTimeOffset>(12),
            reader.IsDBNull(13) ? null : reader.GetInt32(13),
            reader.IsDBNull(14) ? null : reader.GetString(14),
            reader.IsDBNull(15) ? null : reader.GetString(15),
            reader.IsDBNull(16) ? null : reader.GetString(16),
            reader.IsDBNull(17) ? null : reader.GetString(17),
            reader.IsDBNull(18) ? null : reader.GetString(18),
            reader.IsDBNull(19) ? null : reader.GetString(19),
            reader.IsDBNull(20) ? null : reader.GetString(20),
            reader.IsDBNull(21) ? null : reader.GetFieldValue<DateTimeOffset>(21),
            reader.IsDBNull(22) ? null : reader.GetFieldValue<DateTimeOffset>(22));
    }

    public static async Task<TransportirDashboardSummaryDto> GetTransportirDashboardSummaryAsync(
        IConfiguration configuration,
        string? transportirEmail,
        CancellationToken cancellationToken)
    {
        var shipments = await GetShipmentsAsync(configuration, transportirEmail, cancellationToken);
        var active = shipments.Where(s => s.Status != "selesai").ToList();
        var activeShipment = active.FirstOrDefault(s => s.Status == "dalam_perjalanan") ?? active.FirstOrDefault();
        return new TransportirDashboardSummaryDto(shipments.Count, active.Count, activeShipment);
    }

    private static string ToShipmentStatusLabel(string status) => status switch
    {
        "siap_muat" => "Siap Muat",
        "dalam_perjalanan" => "Dalam Perjalanan",
        "selesai" => "Selesai",
        _ => status,
    };

    public static async Task<ShipmentSummaryDto> UploadShipmentPhotoAsync(
        IConfiguration configuration,
        string shipmentNumber,
        string muatType,
        string transportirEmail,
        string photoUrl,
        CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        try
        {
            await using var lookupCommand = connection.CreateCommand();
            lookupCommand.Transaction = (SqlTransaction)transaction;
            lookupCommand.CommandText = """
                SELECT Id, OrderId, TransportirEmail, MuatInCompletedAt, MuatOutCompletedAt
                FROM dbo.Shipments
                WHERE ShipmentNumber = @ShipmentNumber;
                """;
            lookupCommand.Parameters.AddWithValue("@ShipmentNumber", shipmentNumber);

            int shipmentId;
            int? orderId;
            bool muatInDone;
            bool muatOutDone;
            await using (var reader = await lookupCommand.ExecuteReaderAsync(cancellationToken))
            {
                if (!await reader.ReadAsync(cancellationToken))
                {
                    throw new InvalidOperationException($"Shipment {shipmentNumber} tidak ditemukan.");
                }

                shipmentId = reader.GetInt32(0);
                orderId = reader.IsDBNull(1) ? null : reader.GetInt32(1);
                var ownerEmail = reader.IsDBNull(2) ? null : reader.GetString(2);
                muatInDone = !reader.IsDBNull(3);
                muatOutDone = !reader.IsDBNull(4);

                if (!string.Equals(ownerEmail, transportirEmail, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Shipment ini tidak dialokasikan untuk akun Transportir Anda.");
                }
            }

            if (orderId is null)
            {
                throw new InvalidOperationException($"Shipment {shipmentNumber} belum terhubung ke order manapun.");
            }

            if (muatType == "load-in")
            {
                if (muatInDone)
                {
                    throw new InvalidOperationException("Foto load-in sudah diunggah sebelumnya.");
                }

                await using var updateShipment = connection.CreateCommand();
                updateShipment.Transaction = (SqlTransaction)transaction;
                updateShipment.CommandText = """
                    UPDATE dbo.Shipments
                    SET MuatInPhotoUrl = @PhotoUrl, MuatInCompletedAt = SYSUTCDATETIME(),
                        Status = 'dalam_perjalanan', UpdatedAt = SYSUTCDATETIME()
                    WHERE Id = @Id;
                    """;
                updateShipment.Parameters.AddWithValue("@PhotoUrl", photoUrl);
                updateShipment.Parameters.AddWithValue("@Id", shipmentId);
                await updateShipment.ExecuteNonQueryAsync(cancellationToken);

                var userEmail = await UpdateOrderForShipmentEventAsync(
                    connection, (SqlTransaction)transaction, orderId.Value,
                    orderStatus: "shipping", legacyStatus: "shipping", setDeliveredAt: false, cancellationToken);

                await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId.Value,
                    "Dalam Perjalanan", "Kendaraan berangkat dari gudang.", "shipping", true, 30, cancellationToken);
                await AddNotificationAsync(connection, (SqlTransaction)transaction,
                    "Pesanan dalam perjalanan", $"Shipment {shipmentNumber} sudah berangkat dari gudang.", userEmail, cancellationToken);
            }
            else
            {
                if (!muatInDone)
                {
                    throw new InvalidOperationException("Foto load-in belum diunggah, tidak bisa unggah foto load-out.");
                }

                if (muatOutDone)
                {
                    throw new InvalidOperationException("Foto load-out sudah diunggah sebelumnya.");
                }

                await using var updateShipment = connection.CreateCommand();
                updateShipment.Transaction = (SqlTransaction)transaction;
                updateShipment.CommandText = """
                    UPDATE dbo.Shipments
                    SET MuatOutPhotoUrl = @PhotoUrl, MuatOutCompletedAt = SYSUTCDATETIME(),
                        CompletedAt = SYSUTCDATETIME(), Status = 'selesai', UpdatedAt = SYSUTCDATETIME()
                    WHERE Id = @Id;
                    """;
                updateShipment.Parameters.AddWithValue("@PhotoUrl", photoUrl);
                updateShipment.Parameters.AddWithValue("@Id", shipmentId);
                await updateShipment.ExecuteNonQueryAsync(cancellationToken);

                var userEmail = await UpdateOrderForShipmentEventAsync(
                    connection, (SqlTransaction)transaction, orderId.Value,
                    orderStatus: "delivered", legacyStatus: "delivered", setDeliveredAt: true, cancellationToken);

                await AddOrderEventAsync(connection, (SqlTransaction)transaction, orderId.Value,
                    "Pemesanan Selesai", "Barang telah diserahterimakan di kios tujuan.", "delivered", true, 40, cancellationToken);
                await AddNotificationAsync(connection, (SqlTransaction)transaction,
                    "Pesanan selesai", $"Shipment {shipmentNumber} telah sampai di tujuan.", userEmail, cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }

        return await GetShipmentByNumberAsync(configuration, shipmentNumber, cancellationToken)
            ?? throw new InvalidOperationException("Shipment tidak ditemukan setelah pembaruan status.");
    }

    private static async Task<string?> UpdateOrderForShipmentEventAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int orderId,
        string orderStatus,
        string legacyStatus,
        bool setDeliveredAt,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = $"""
            UPDATE dbo.Orders
            SET OrderStatus = @OrderStatus,
                Status = @LegacyStatus,
                DeliveredAt = {(setDeliveredAt ? "COALESCE(DeliveredAt, SYSUTCDATETIME())" : "DeliveredAt")},
                UpdatedAt = SYSUTCDATETIME()
            OUTPUT INSERTED.UserEmail
            WHERE Id = @OrderId;
            """;
        command.Parameters.AddWithValue("@OrderStatus", orderStatus);
        command.Parameters.AddWithValue("@LegacyStatus", legacyStatus);
        command.Parameters.AddWithValue("@OrderId", orderId);
        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result is string email ? email : null;
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
            (PoNumber, UserEmail, Status, Vendor, PaymentMethod, Subtotal, ShippingAmount, TotalAmount, PaidAt)
            VALUES
            ('PO-2026-10-9842', NULL, 'shipping', 'PT Global Logistik Nusantara', 'Bank Transfer (Mandiri)', 12150000, 250000, 12400000, SYSUTCDATETIME());

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

        IF NOT EXISTS (SELECT 1 FROM dbo.Shipments WHERE ShipmentNumber = N'SJ-2026-001')
        BEGIN
            DECLARE @MonthStart DATETIMEOFFSET = DATEFROMPARTS(YEAR(SYSUTCDATETIME()), MONTH(SYSUTCDATETIME()), 1);

            INSERT INTO dbo.Shipments
            (ShipmentNumber, DriverName, Status, CreatedAt, TruckLabel, PoliceNumber, DestinationLabel, DestinationAddress, OriginLat, OriginLng, DestinationLat, DestinationLng)
            VALUES
            (N'SJ-2026-001', N'Budi Santoso', N'siap_muat', DATEADD(DAY, 6, @MonthStart), N'Truk Engkel (Nopol: B 1234 YXZ)', N'B 1234 YXZ', N'Kios Tani Makmur', N'Driyorejo, Gresik', -7.257500, 112.752100, -7.385000, 112.592800),
            (N'SJ-2026-002', N'Hotma Simangunsong', N'dalam_perjalanan', DATEADD(DAY, 3, @MonthStart), N'Truk Fuso (Nopol: B 9021 XB)', N'B 9021 XB', N'Kios Makmur Jaya', N'Sukabumi, Bandar Lampung', -5.450000, 105.266700, -5.398000, 105.301000);

            UPDATE dbo.Shipments SET MuatInCompletedAt = DATEADD(HOUR, 4, CreatedAt) WHERE ShipmentNumber = N'SJ-2026-002';

            INSERT INTO dbo.Shipments
            (ShipmentNumber, DriverName, Status, CreatedAt, MuatInCompletedAt, MuatOutCompletedAt, CompletedAt, TotalDistanceMeters, TruckLabel, PoliceNumber, DestinationLabel, DestinationAddress, OriginLat, OriginLng, DestinationLat, DestinationLng)
            VALUES
            (N'SJ-2026-003', N'Agus Wibowo', N'selesai', DATEADD(DAY, 1, @MonthStart), DATEADD(DAY, 1, DATEADD(HOUR, 2, @MonthStart)), DATEADD(DAY, 1, DATEADD(HOUR, 6, @MonthStart)), DATEADD(DAY, 1, DATEADD(HOUR, 6, @MonthStart)), 21000, N'Truk Engkel (Nopol: BE 9911 AC)', N'BE 9911 AC', N'Gudang Tani Sejahtera', N'Metro Pusat, Lampung', -5.450000, 105.266700, -5.113500, 105.306100);
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

    // Admin console allocates kecamatan_product_stocks quota yearly (period = "yyyy"), not monthly.
    private static string CurrentPeriod() => DateTimeOffset.UtcNow.ToString("yyyy");

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

    private static string ToOrderStatusLabel(string? orderStatus) => orderStatus switch
    {
        "processing" => "Sedang Diproses",
        "shipping" => "Dalam Perjalanan",
        "delivered" => "Pemesanan Selesai",
        "cancelled" => "Dibatalkan",
        _ => "Menunggu Pembayaran"
    };

    private static (string Status, string Label) DerivePaymentStatus(DateTimeOffset? paidAt) =>
        paidAt is null ? ("pending", "Pending") : ("paid", "Sudah Dibayar");

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
