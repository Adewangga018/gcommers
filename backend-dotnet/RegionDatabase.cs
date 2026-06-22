using Microsoft.Data.SqlClient;

static class RegionDatabase
{
    public static async Task<List<RegionDto>> GetRegionListAsync(IConfiguration configuration, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, nama_reg FROM dbo.region ORDER BY nama_reg;";

        var result = new List<RegionDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new RegionDto(reader.GetInt32(0), reader.GetString(1)));
        }

        return result;
    }

    private static readonly string[] SeedRegions =
    {
        "Jawa Tengah Selatan",
        "Medan",
        "Lampung",
        "Jawa Tengah Utara",
        "Jawa Timur",
        "Makassar",
    };

    public static async Task EnsureSchemaAsync(IConfiguration configuration)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await ExecuteAsync(connection, """
        IF OBJECT_ID(N'dbo.region', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.region
            (
                id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_region PRIMARY KEY,
                nama_reg NVARCHAR(100) NOT NULL,
                CONSTRAINT UX_region_nama_reg UNIQUE (nama_reg)
            );
        END

        IF OBJECT_ID(N'dbo.propinsi', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.propinsi
            (
                id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_propinsi PRIMARY KEY,
                nama_pro NVARCHAR(150) NOT NULL,
                CONSTRAINT UX_propinsi_nama_pro UNIQUE (nama_pro)
            );
        END

        IF OBJECT_ID(N'dbo.propinsi', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.propinsi') AND name = N'id_reg'
        )
        BEGIN
            ALTER TABLE dbo.propinsi ADD id_reg INT NULL;
        END

        IF OBJECT_ID(N'dbo.kabupaten', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.kabupaten
            (
                id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_kabupaten PRIMARY KEY,
                nama_kab NVARCHAR(150) NOT NULL,
                CONSTRAINT UX_kabupaten_nama_kab UNIQUE (nama_kab)
            );
        END

        IF OBJECT_ID(N'dbo.kecamatan', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.kecamatan
            (
                id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_kecamatan PRIMARY KEY,
                nama_kec NVARCHAR(150) NOT NULL,
                CONSTRAINT UX_kecamatan_nama_kec UNIQUE (nama_kec)
            );
        END

        -- Users needs a nama_pro column (plain display text, not a FK target --
        -- kabupaten/kecamatan names are not unique nationally, see id-based FKs below)
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'nama_pro'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD nama_pro NVARCHAR(150) NULL;
        END

        -- kabupaten/kecamatan/propinsi (existing Laravel-managed tables) have no PK/index at all
        -- on id, even though values are already unique -- add one so it can be an FK target
        IF OBJECT_ID(N'dbo.kabupaten', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.kabupaten') AND type = 'PK'
        )
        BEGIN
            ALTER TABLE dbo.kabupaten ADD CONSTRAINT PK_kabupaten PRIMARY KEY (id);
        END

        IF OBJECT_ID(N'dbo.kecamatan', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.kecamatan') AND type = 'PK'
        )
        BEGIN
            ALTER TABLE dbo.kecamatan ADD CONSTRAINT PK_kecamatan PRIMARY KEY (id);
        END

        IF OBJECT_ID(N'dbo.propinsi', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.propinsi') AND type = 'PK'
        )
        BEGIN
            ALTER TABLE dbo.propinsi ADD CONSTRAINT PK_propinsi PRIMARY KEY (id);
        END

        -- kabupaten.id / kecamatan.id / propinsi.id are BIGINT (existing Laravel-managed tables);
        -- widen Users.id_kab from INT to match so the FK below can be created
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND EXISTS (
            SELECT 1 FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'dbo.Users') AND c.name = N'id_kab' AND ty.name = N'int'
        )
        BEGIN
            ALTER TABLE dbo.Users ALTER COLUMN id_kab BIGINT NULL;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'id_kec'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD id_kec BIGINT NULL;
        END

        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'id_pro'
        )
        BEGIN
            ALTER TABLE dbo.Users ADD id_pro BIGINT NULL;
        END

        -- Jawa Tengah's kabupaten split across two regions (Utara/Selatan), which a single
        -- propinsi.id_reg value can't represent -- kabupaten.id_reg overrides it per-row.
        IF OBJECT_ID(N'dbo.kabupaten', N'U') IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.kabupaten') AND name = N'id_reg'
        )
        BEGIN
            ALTER TABLE dbo.kabupaten ADD id_reg INT NULL;
        END
        """);

        // Rename Gresik -> Jawa Tengah Utara before seeding, so the seed list (which now
        // lists "Jawa Tengah Utara") doesn't insert a second row ahead of the rename.
        // Region is FK'd from Users, so relax the constraint for the rename, then re-validate.
        await ExecuteAsync(connection, """
        IF EXISTS (SELECT 1 FROM dbo.region WHERE nama_reg = N'Gresik')
        BEGIN
            IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_region')
                ALTER TABLE dbo.Users NOCHECK CONSTRAINT FK_Users_region;

            UPDATE dbo.region SET nama_reg = N'Jawa Tengah Utara' WHERE nama_reg = N'Gresik';
            UPDATE dbo.Users SET Region = N'Jawa Tengah Utara' WHERE Region = N'Gresik';

            IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_region')
                ALTER TABLE dbo.Users WITH CHECK CHECK CONSTRAINT FK_Users_region;
        END
        """);

        // Seed dbo.region before adding any FK that references it --
        // Users.Region already holds values like 'Makassar'/'Medan' that must exist there first.
        await SeedRegionsAsync(connection);

        await ExecuteAsync(connection, """
        -- propinsi.id_reg -> region.id
        IF OBJECT_ID(N'dbo.propinsi', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.region', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_propinsi_region')
        BEGIN
            ALTER TABLE dbo.propinsi
            ADD CONSTRAINT FK_propinsi_region FOREIGN KEY (id_reg) REFERENCES dbo.region(id);
        END

        -- Users.id_kab -> kabupaten.id
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.kabupaten', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_kabupaten')
        BEGIN
            ALTER TABLE dbo.Users
            ADD CONSTRAINT FK_Users_kabupaten FOREIGN KEY (id_kab) REFERENCES dbo.kabupaten(id);
        END

        -- Users.id_kec -> kecamatan.id
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.kecamatan', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_kecamatan')
        BEGIN
            ALTER TABLE dbo.Users
            ADD CONSTRAINT FK_Users_kecamatan FOREIGN KEY (id_kec) REFERENCES dbo.kecamatan(id);
        END

        -- Users.id_pro -> propinsi.id
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.propinsi', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_propinsi')
        BEGIN
            ALTER TABLE dbo.Users
            ADD CONSTRAINT FK_Users_propinsi FOREIGN KEY (id_pro) REFERENCES dbo.propinsi(id);
        END

        -- Users.Region -> region.nama_reg
        IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.region', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_region')
        BEGIN
            ALTER TABLE dbo.Users
            ADD CONSTRAINT FK_Users_region FOREIGN KEY (Region) REFERENCES dbo.region(nama_reg);
        END

        -- kabupaten.id_reg -> region.id (Jawa Tengah Utara/Selatan override)
        IF OBJECT_ID(N'dbo.kabupaten', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.region', N'U') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_kabupaten_region')
        BEGIN
            ALTER TABLE dbo.kabupaten
            ADD CONSTRAINT FK_kabupaten_region FOREIGN KEY (id_reg) REFERENCES dbo.region(id);
        END
        """);

        await AssignPropinsiRegionsAsync(connection);
        await AssignKabupatenRegionOverridesAsync(connection);
        await GenerateDummyUserAddressDataAsync(connection);
    }

    // Provinces that map cleanly to one region. Jawa Tengah is deliberately excluded -- it
    // spans both Jawa Tengah Utara and Selatan, handled per-kabupaten below. DKI Jakarta and
    // Jawa Barat aren't covered by any region rule, so they're left unassigned (id_reg NULL).
    private static readonly (string NamaPro, string NamaReg)[] PropinsiRegionMap =
    {
        ("Aceh", "Medan"),
        ("Sumatera Utara", "Medan"),
        ("Sumatera Barat", "Medan"),
        ("Riau", "Medan"),
        ("Lampung", "Lampung"),
        ("Sumatera Selatan", "Lampung"),
        ("Kep. Bangka Belitung", "Lampung"),
        ("DI Yogyakarta", "Jawa Tengah Selatan"),
        ("Jawa Timur", "Jawa Timur"),
        ("Bali", "Jawa Timur"),
        ("Kalimantan Tengah", "Jawa Timur"),
        ("Kalimantan Selatan", "Jawa Timur"),
        ("Sulawesi Selatan", "Makassar"),
        ("Sulawesi Tengah", "Makassar"),
        ("Sulawesi Tenggara", "Makassar"),
        ("Maluku", "Makassar"),
    };

    // Jawa Tengah's own kabupaten, classified by coast: Pantura (north coast) vs the
    // south/central ones (including those bordering DI Yogyakarta, which has no kabupaten
    // rows in this DB to draw from).
    private static readonly string[] JawaTengahUtaraKabupaten =
    {
        "Batang", "Brebes", "Kota Pekalongan", "Kota Tegal", "Pekalongan", "Pemalang", "Tegal",
    };

    private static readonly string[] JawaTengahSelatanKabupaten =
    {
        "Banjarnegara", "Boyolali", "Kab. Banyumas", "Kab. Cilacap", "Kebumen", "Klaten",
        "Kota Magelang", "Magelang", "Purbalingga", "Purworejo", "Temanggung", "Wonosobo",
    };

    private static async Task AssignPropinsiRegionsAsync(SqlConnection connection)
    {
        foreach (var (namaPro, namaReg) in PropinsiRegionMap)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = """
                UPDATE dbo.propinsi
                SET id_reg = (SELECT id FROM dbo.region WHERE nama_reg = @NamaReg)
                WHERE nama_pro = @NamaPro;
                """;
            command.Parameters.AddWithValue("@NamaReg", namaReg);
            command.Parameters.AddWithValue("@NamaPro", namaPro);
            await command.ExecuteNonQueryAsync();
        }
    }

    private static async Task AssignKabupatenRegionOverridesAsync(SqlConnection connection)
    {
        await AssignKabupatenRegionAsync(connection, JawaTengahUtaraKabupaten, "Jawa Tengah Utara");
        await AssignKabupatenRegionAsync(connection, JawaTengahSelatanKabupaten, "Jawa Tengah Selatan");
    }

    private static async Task AssignKabupatenRegionAsync(SqlConnection connection, string[] namaKabList, string namaReg)
    {
        foreach (var namaKab in namaKabList)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = """
                UPDATE dbo.kabupaten
                SET id_reg = (SELECT id FROM dbo.region WHERE nama_reg = @NamaReg)
                WHERE nama_kab = @NamaKab;
                """;
            command.Parameters.AddWithValue("@NamaReg", namaReg);
            command.Parameters.AddWithValue("@NamaKab", namaKab);
            await command.ExecuteNonQueryAsync();
        }
    }

    // Fills nama_kab/nama_kec/nama_pro/id_kab/id_kec/id_pro/kode_kec for existing Users rows
    // whose Region is set but address detail is still missing, picking a kabupaten+kecamatan
    // that actually belongs to that region (via kabupaten.id_reg, falling back to propinsi.id_reg).
    private static async Task GenerateDummyUserAddressDataAsync(SqlConnection connection)
    {
        var kabupatenByRegion = new Dictionary<string, List<(long KabId, string NamaKab, long ProId, string NamaPro)>>();

        await using (var command = connection.CreateCommand())
        {
            command.CommandText = """
                SELECT r.nama_reg, k.id, k.nama_kab, p.id, p.nama_pro
                FROM dbo.kabupaten k
                JOIN dbo.propinsi p ON p.id = k.id_pro
                JOIN dbo.region r ON r.id = COALESCE(k.id_reg, p.id_reg)
                WHERE EXISTS (SELECT 1 FROM dbo.kecamatan kc WHERE kc.id_kab = k.id)
                ORDER BY r.nama_reg, k.id;
                """;
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var namaReg = reader.GetString(0);
                if (!kabupatenByRegion.TryGetValue(namaReg, out var list))
                {
                    list = new List<(long, string, long, string)>();
                    kabupatenByRegion[namaReg] = list;
                }
                list.Add((reader.GetInt64(1), reader.GetString(2), reader.GetInt64(3), reader.GetString(4)));
            }
        }

        var pendingUsers = new List<(int Id, string Region)>();
        await using (var command = connection.CreateCommand())
        {
            command.CommandText = "SELECT Id, Region FROM dbo.Users WHERE Region IS NOT NULL AND nama_kab IS NULL;";
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                pendingUsers.Add((reader.GetInt32(0), reader.GetString(1)));
            }
        }

        var regionCounters = new Dictionary<string, int>();

        foreach (var (userId, region) in pendingUsers)
        {
            if (!kabupatenByRegion.TryGetValue(region, out var candidates) || candidates.Count == 0)
            {
                continue;
            }

            var index = regionCounters.TryGetValue(region, out var count) ? count : 0;
            regionCounters[region] = index + 1;
            var (kabId, namaKab, proId, namaPro) = candidates[index % candidates.Count];

            long kecId;
            string namaKec;
            string? kodeKec;
            await using (var kecCommand = connection.CreateCommand())
            {
                kecCommand.CommandText = "SELECT id, nama_kec, kode_kec FROM dbo.kecamatan WHERE id_kab = @KabId ORDER BY id;";
                kecCommand.Parameters.AddWithValue("@KabId", kabId);
                var kecList = new List<(long Id, string NamaKec, string? KodeKec)>();
                await using var kecReader = await kecCommand.ExecuteReaderAsync();
                while (await kecReader.ReadAsync())
                {
                    kecList.Add((kecReader.GetInt64(0), kecReader.GetString(1), kecReader.IsDBNull(2) ? null : kecReader.GetString(2)));
                }

                var kecIndex = userId % kecList.Count;
                (kecId, namaKec, kodeKec) = kecList[kecIndex];
            }

            await using var updateCommand = connection.CreateCommand();
            updateCommand.CommandText = """
                UPDATE dbo.Users
                SET nama_kab = @NamaKab, id_kab = @IdKab,
                    nama_kec = @NamaKec, id_kec = @IdKec, kode_kec = @KodeKec,
                    nama_pro = @NamaPro, id_pro = @IdPro
                WHERE Id = @Id;
                """;
            updateCommand.Parameters.AddWithValue("@NamaKab", namaKab);
            updateCommand.Parameters.AddWithValue("@IdKab", kabId);
            updateCommand.Parameters.AddWithValue("@NamaKec", namaKec);
            updateCommand.Parameters.AddWithValue("@IdKec", kecId);
            updateCommand.Parameters.AddWithValue("@KodeKec", (object?)kodeKec ?? DBNull.Value);
            updateCommand.Parameters.AddWithValue("@NamaPro", namaPro);
            updateCommand.Parameters.AddWithValue("@IdPro", proId);
            updateCommand.Parameters.AddWithValue("@Id", userId);
            await updateCommand.ExecuteNonQueryAsync();
        }
    }

    private static async Task SeedRegionsAsync(SqlConnection connection)
    {
        foreach (var namaReg in SeedRegions)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = """
                IF NOT EXISTS (SELECT 1 FROM dbo.region WHERE nama_reg = @NamaReg)
                INSERT INTO dbo.region (nama_reg) VALUES (@NamaReg);
                """;
            command.Parameters.AddWithValue("@NamaReg", namaReg);
            await command.ExecuteNonQueryAsync();
        }
    }

    private static async Task ExecuteAsync(SqlConnection connection, string sql)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();
    }
}
