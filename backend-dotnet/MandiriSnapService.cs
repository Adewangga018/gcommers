using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

public sealed class MandiriSnapConfig
{
    public bool Enabled { get; init; }
    public string BaseUrl { get; init; } = "https://apidev.bankmandiri.co.id";
    public string ClientId { get; init; } = "";
    public string ClientSecret { get; init; } = "";
    public string PrivateKeyPem { get; init; } = "";
    public string PartnerServiceId { get; init; } = "  088908";
    public string ChannelId { get; init; } = "95231";
    public string VirtualAccountName { get; init; } = "PT GCommers Indonesia";
}

public sealed class MandiriSnapService
{
    private readonly MandiriSnapConfig _config;
    private readonly HttpClient _httpClient;
    private readonly ILogger<MandiriSnapService> _logger;

    private string? _cachedToken;
    private DateTimeOffset _tokenExpiry;
    private readonly SemaphoreSlim _tokenLock = new(1, 1);

    public MandiriSnapService(MandiriSnapConfig config, IHttpClientFactory factory, ILogger<MandiriSnapService> logger)
    {
        _config = config;
        _httpClient = factory.CreateClient("mandiri");
        _logger = logger;
    }

    public async Task<(string VirtualAccountNo, DateTimeOffset ExpiredAt)> CreateVirtualAccountAsync(
        string poNumber, decimal amount, CancellationToken cancellationToken)
    {
        if (!_config.Enabled)
        {
            return CreateMockVa(poNumber);
        }

        try
        {
            var token = await GetAccessTokenAsync(cancellationToken);
            return await CallCreateVaAsync(token, poNumber, amount, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Mandiri Snap API unavailable – using mock VA for {PoNumber}", poNumber);
            return CreateMockVa(poNumber);
        }
    }

    private (string VirtualAccountNo, DateTimeOffset ExpiredAt) CreateMockVa(string poNumber)
    {
        var digits = new string(poNumber.Where(char.IsDigit).ToArray());
        var customerNo = digits.Length >= 12 ? digits[^12..] : digits.PadLeft(12, '0');
        var vaNo = $"{_config.PartnerServiceId.PadLeft(8)}{customerNo}";
        return (vaNo, DateTimeOffset.UtcNow.AddHours(24));
    }

    private async Task<string> GetAccessTokenAsync(CancellationToken cancellationToken)
    {
        await _tokenLock.WaitAsync(cancellationToken);
        try
        {
            if (_cachedToken is not null && _tokenExpiry > DateTimeOffset.UtcNow.AddMinutes(1))
                return _cachedToken;

            var timestamp = WibTimestamp();
            var signature = SignRsa($"{_config.ClientId}|{timestamp}");

            var req = new HttpRequestMessage(HttpMethod.Post, $"{_config.BaseUrl}/openapi/v1.0/access-token/b2b");
            req.Headers.Add("X-TIMESTAMP", timestamp);
            req.Headers.Add("X-CLIENT-KEY", _config.ClientId);
            req.Headers.Add("X-SIGNATURE", signature);
            req.Content = new StringContent("""{"grantType":"client_credentials"}""", Encoding.UTF8, "application/json");

            var res = await _httpClient.SendAsync(req, cancellationToken);
            var body = await res.Content.ReadAsStringAsync(cancellationToken);
            var doc = JsonDocument.Parse(body);

            _cachedToken = doc.RootElement.GetProperty("accessToken").GetString()
                ?? throw new InvalidOperationException("Mandiri: missing accessToken");
            var expiresIn = doc.RootElement.GetProperty("expiresIn").GetInt32();
            _tokenExpiry = DateTimeOffset.UtcNow.AddSeconds(expiresIn);

            return _cachedToken;
        }
        finally
        {
            _tokenLock.Release();
        }
    }

    private async Task<(string VirtualAccountNo, DateTimeOffset ExpiredAt)> CallCreateVaAsync(
        string accessToken, string poNumber, decimal amount, CancellationToken cancellationToken)
    {
        var timestamp = WibTimestamp();
        var partnerServiceId = _config.PartnerServiceId.PadLeft(8);
        var digits = new string(poNumber.Where(char.IsDigit).ToArray());
        var customerNo = digits.Length >= 12 ? digits[^12..] : digits.PadLeft(12, '0');
        var vaNo = $"{partnerServiceId}{customerNo}";
        var expiredAt = DateTimeOffset.UtcNow.AddHours(24).ToOffset(TimeSpan.FromHours(7));

        var bodyObj = new
        {
            partnerServiceId,
            customerNo,
            virtualAccountNo = vaNo,
            virtualAccountName = _config.VirtualAccountName,
            virtualAccountEmail = "",
            virtualAccountPhone = "",
            trxId = poNumber,
            totalAmount = new { value = $"{amount:F2}", currency = "IDR" },
            virtualAccountTrxType = "C",
            expiredDate = expiredAt.ToString("yyyy-MM-ddTHH:mm:sszzz"),
            additionalInfo = new { }
        };

        var bodyJson = JsonSerializer.Serialize(bodyObj);
        var signature = SignHmac("POST", "/openapi/v1.0/transfer-va/create-va", accessToken, timestamp, bodyJson);

        var req = new HttpRequestMessage(HttpMethod.Post, $"{_config.BaseUrl}/openapi/v1.0/transfer-va/create-va");
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        req.Headers.Add("X-TIMESTAMP", timestamp);
        req.Headers.Add("X-SIGNATURE", signature);
        req.Headers.Add("X-PARTNER-ID", _config.ClientId);
        req.Headers.Add("X-REQUEST-ID", Guid.NewGuid().ToString());
        req.Headers.Add("X-EXTERNAL-ID", poNumber);
        req.Headers.Add("CHANNEL-ID", _config.ChannelId);
        req.Content = new StringContent(bodyJson, Encoding.UTF8, "application/json");

        var res = await _httpClient.SendAsync(req, cancellationToken);
        res.EnsureSuccessStatusCode();

        return (vaNo, expiredAt);
    }

    private string SignRsa(string data)
    {
        var pem = _config.PrivateKeyPem
            .Replace("-----BEGIN PRIVATE KEY-----", "")
            .Replace("-----END PRIVATE KEY-----", "")
            .Replace("\n", "").Replace("\r", "").Trim();

        using var rsa = RSA.Create();
        rsa.ImportPkcs8PrivateKey(Convert.FromBase64String(pem), out _);
        var sig = rsa.SignData(Encoding.UTF8.GetBytes(data), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        return Convert.ToBase64String(sig);
    }

    private string SignHmac(string method, string path, string accessToken, string timestamp, string body)
    {
        var tokenHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(accessToken))).ToLowerInvariant();
        var bodyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(body))).ToLowerInvariant();
        var str = $"{method}:{path}:{tokenHash}:{timestamp}:{bodyHash}";
        var sig = HMACSHA512.HashData(Encoding.UTF8.GetBytes(_config.ClientSecret), Encoding.UTF8.GetBytes(str));
        return Convert.ToBase64String(sig);
    }

    private static string WibTimestamp()
        => DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7)).ToString("yyyy-MM-ddTHH:mm:sszzz");

    public static IReadOnlyList<string> HowToPayInstructions(string vaNumber) =>
    [
        "Buka aplikasi Livin' by Mandiri atau ATM Mandiri.",
        "Pilih menu Pembayaran → Multi Payment.",
        $"Masukkan kode perusahaan 088908 dan No. VA: {vaNumber}.",
        "Periksa detail tagihan lalu konfirmasi pembayaran.",
        "Simpan bukti pembayaran sebagai referensi."
    ];
}
