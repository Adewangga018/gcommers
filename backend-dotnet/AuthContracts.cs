public sealed record LoginRequest(string Email, string Password);

public sealed record RegisterKioskRequest(
    string KioskName,
    string PicName,
    string Phone,
    string Email,
    string Password,
    string Address,
    string Region,
    long ProvinsiId,
    long KabupatenId,
    long KecamatanId,
    bool TermsAccepted,
    string? LicenseImageName)
{
    public string? Validate()
    {
        if (string.IsNullOrWhiteSpace(KioskName) ||
            string.IsNullOrWhiteSpace(PicName) ||
            string.IsNullOrWhiteSpace(Phone) ||
            string.IsNullOrWhiteSpace(Email) ||
            string.IsNullOrWhiteSpace(Password) ||
            string.IsNullOrWhiteSpace(Address) ||
            string.IsNullOrWhiteSpace(Region))
        {
            return "Semua field wajib diisi.";
        }

        if (ProvinsiId <= 0 || KabupatenId <= 0 || KecamatanId <= 0)
        {
            return "Provinsi, kabupaten, dan kecamatan wajib dipilih.";
        }

        if (Password.Length < 8)
        {
            return "Password minimal 8 karakter.";
        }

        if (!TermsAccepted)
        {
            return "Anda harus menyetujui syarat dan ketentuan.";
        }

        return null;
    }
}

public sealed record RegisterTransportirRequest(
    string TransportirName,
    string CompanyName,
    string Phone,
    string Email,
    string Password,
    string PoliceNumber,
    string Type,
    string Region,
    bool TermsAccepted)
{
    public string? Validate()
    {
        if (string.IsNullOrWhiteSpace(TransportirName) ||
            string.IsNullOrWhiteSpace(CompanyName) ||
            string.IsNullOrWhiteSpace(Phone) ||
            string.IsNullOrWhiteSpace(Email) ||
            string.IsNullOrWhiteSpace(Password) ||
            string.IsNullOrWhiteSpace(PoliceNumber) ||
            string.IsNullOrWhiteSpace(Type) ||
            string.IsNullOrWhiteSpace(Region))
        {
            return "Semua field wajib diisi.";
        }

        if (Password.Length < 8)
        {
            return "Password minimal 8 karakter.";
        }

        if (!TermsAccepted)
        {
            return "Anda harus menyetujui syarat dan ketentuan.";
        }

        return null;
    }
}

public sealed record UpdateProfileRequest(
    string Email,
    string DisplayName,
    string? PicName = null,
    string? Phone = null,
    string? Address = null,
    string? AvatarImageBase64 = null);

public sealed record UpdateAddressRequest(
    string Email,
    long? ProvinsiId,
    long? KabupatenId,
    long? KecamatanId,
    string? Kelurahan,
    string? KodePos,
    string? Address,
    double? Latitude,
    double? Longitude)
{
    public string? Validate()
    {
        if (string.IsNullOrWhiteSpace(Email))
        {
            return "Email wajib diisi.";
        }

        return null;
    }
}

public sealed record ChangePasswordRequest(
    string Email,
    string CurrentPassword,
    string NewPassword,
    string ConfirmNewPassword);

public sealed record ForgotPasswordRequest(string Email);
public sealed record ForgotPasswordResponse(string Email, string Otp, int ExpiresInSeconds);
public sealed record VerifyOtpRequest(string Email, string Otp);
public sealed record ResetPasswordRequest(string Email, string Password, string ConfirmPassword);

public sealed record AuthSession(
    string Email,
    string Role,
    string DisplayName,
    string Token,
    string? Phone = null,
    string? PicName = null,
    string? Address = null,
    string? Region = null,
    string? TransportirName = null,
    string? CompanyName = null,
    string? PoliceNumber = null,
    string? VehicleType = null,
    string? AvatarImageBase64 = null,
    long? ProvinsiId = null,
    long? KabupatenId = null,
    long? KecamatanId = null,
    string? ProvinsiNama = null,
    string? KabupatenNama = null,
    string? KecamatanNama = null,
    string? Kelurahan = null,
    string? KodePos = null,
    double? Latitude = null,
    double? Longitude = null)
{
    public static AuthSession FromUser(AuthUserRecord user)
        => new(
            Email: user.Email,
            Role: user.Role,
            DisplayName: user.DisplayName,
            Token: Guid.NewGuid().ToString("N"),
            Phone: user.Phone,
            PicName: user.PicName,
            Address: user.Address,
            Region: user.Region,
            TransportirName: user.TransportirName,
            CompanyName: user.CompanyName,
            PoliceNumber: user.PoliceNumber,
            VehicleType: user.VehicleType,
            AvatarImageBase64: user.AvatarImage is { Length: > 0 } bytes ? Convert.ToBase64String(bytes) : null,
            ProvinsiId: user.ProvinsiId,
            KabupatenId: user.KabupatenId,
            KecamatanId: user.KecamatanId,
            ProvinsiNama: user.ProvinsiNama,
            KabupatenNama: user.KabupatenNama,
            KecamatanNama: user.KecamatanNama,
            Kelurahan: user.Kelurahan,
            KodePos: user.KodePos,
            Latitude: user.Latitude,
            Longitude: user.Longitude);
}

public sealed record AuthUserRecord(
    int Id,
    string Email,
    byte[] PasswordHash,
    byte[] PasswordSalt,
    string Role,
    string DisplayName,
    string? Phone,
    string? PicName,
    string? Address,
    string? Region,
    string? TransportirName,
    string? CompanyName,
    string? PoliceNumber,
    string? VehicleType,
    byte[]? ResetOtpHash,
    byte[]? ResetOtpSalt,
    DateTimeOffset? ResetOtpExpiresAt,
    DateTimeOffset? ResetOtpVerifiedAt,
    int FailedLoginCount,
    DateTimeOffset? LastFailedLoginAt,
    DateTimeOffset? LockoutUntil,
    byte[]? AvatarImage = null,
    long? ProvinsiId = null,
    long? KabupatenId = null,
    long? KecamatanId = null,
    string? ProvinsiNama = null,
    string? KabupatenNama = null,
    string? KecamatanNama = null,
    string? Kelurahan = null,
    string? KodePos = null,
    double? Latitude = null,
    double? Longitude = null);
