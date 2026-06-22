using Microsoft.Data.SqlClient;

static class WilayahDatabase
{
    public static async Task<List<ProvinsiDto>> GetProvinsiListAsync(IConfiguration configuration, string? region, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        // Filter provinces to the selected commercial region. Jawa Tengah has no propinsi-level
        // id_reg (its kabupaten are split between Utara/Selatan via kabupaten.id_reg instead), so
        // a province also matches when any of its kabupaten carry that region override.
        command.CommandText = """
            DECLARE @RegionId INT = (SELECT id FROM dbo.region WHERE nama_reg = @Region);
            SELECT p.id, p.kode_pro, p.nama_pro
            FROM dbo.propinsi p
            WHERE p.status = N'Aktif'
              AND (
                @RegionId IS NULL
                OR p.id_reg = @RegionId
                OR EXISTS (SELECT 1 FROM dbo.kabupaten k WHERE k.id_pro = p.id AND k.id_reg = @RegionId)
              )
            ORDER BY p.nama_pro;
            """;
        command.Parameters.AddWithValue("@Region", string.IsNullOrWhiteSpace(region) ? DBNull.Value : region);

        var result = new List<ProvinsiDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new ProvinsiDto(
                reader.GetInt64(0),
                reader.IsDBNull(1) ? string.Empty : reader.GetString(1),
                reader.IsDBNull(2) ? string.Empty : reader.GetString(2)));
        }

        return result;
    }

    public static async Task<List<KabupatenDto>> GetKabupatenListAsync(IConfiguration configuration, long provinsiId, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT id, id_pro, kode_kab, nama_kab
            FROM dbo.kabupaten
            WHERE id_pro = @ProvinsiId AND status = N'Aktif'
            ORDER BY nama_kab;
            """;
        command.Parameters.AddWithValue("@ProvinsiId", provinsiId);

        var result = new List<KabupatenDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new KabupatenDto(
                reader.GetInt64(0),
                reader.GetInt64(1),
                reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                reader.IsDBNull(3) ? string.Empty : reader.GetString(3)));
        }

        return result;
    }

    public static async Task<List<KecamatanDto>> GetKecamatanListAsync(IConfiguration configuration, long kabupatenId, CancellationToken cancellationToken)
    {
        var connectionString = ConnectionStringFactory.Build(configuration);
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT id, id_kab, kode_kec, nama_kec
            FROM dbo.kecamatan
            WHERE id_kab = @KabupatenId AND status = N'Aktif'
            ORDER BY nama_kec;
            """;
        command.Parameters.AddWithValue("@KabupatenId", kabupatenId);

        var result = new List<KecamatanDto>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new KecamatanDto(
                reader.GetInt64(0),
                reader.GetInt64(1),
                reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                reader.IsDBNull(3) ? string.Empty : reader.GetString(3)));
        }

        return result;
    }
}
