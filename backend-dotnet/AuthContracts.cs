public sealed record LoginRequest(string Email, string Password);

public sealed record RegisterKioskRequest(
    string KioskName,
    string PicName,
    string Phone,
    string Email,
    string Password,
    string Address,
    string Region,
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
    string Phone,
    string Email,
    string Password,
    bool TermsAccepted)
{
    public string? Validate()
    {
        if (string.IsNullOrWhiteSpace(TransportirName) ||
            string.IsNullOrWhiteSpace(Phone) ||
            string.IsNullOrWhiteSpace(Email) ||
            string.IsNullOrWhiteSpace(Password))
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

public sealed record ForgotPasswordRequest(string Email);
public sealed record ForgotPasswordResponse(string Email, string Otp, int ExpiresInSeconds);
public sealed record VerifyOtpRequest(string Email, string Otp);
public sealed record ResetPasswordRequest(string Email, string Password, string ConfirmPassword);

public sealed record AuthSession(
    string Email,
    string Role,
    string DisplayName,
    string Token)
{
    public static AuthSession FromUser(AuthUserRecord user)
        => new(user.Email, user.Role, user.DisplayName, Guid.NewGuid().ToString("N"));
}

public sealed record AuthUserRecord(
    int Id,
    string Email,
    byte[] PasswordHash,
    byte[] PasswordSalt,
    string Role,
    string DisplayName,
    byte[]? ResetOtpHash,
    byte[]? ResetOtpSalt,
    DateTimeOffset? ResetOtpExpiresAt,
    DateTimeOffset? ResetOtpVerifiedAt);
