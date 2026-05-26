class AuthSession {
  const AuthSession({
    required this.email,
    required this.role,
    required this.displayName,
    this.phone,
    this.address,
    this.picName,
    this.region,
    this.token,
  });

  final String email;
  final String role;
  final String displayName;
  final String? phone;
  final String? address;
  final String? picName;
  final String? region;
  final String? token;
}

class KioskRegistrationDraft {
  const KioskRegistrationDraft({
    required this.kioskName,
    required this.picName,
    required this.phone,
    required this.email,
    required this.password,
    required this.address,
    required this.region,
    required this.termsAccepted,
    required this.licenseImageName,
  });

  final String kioskName;
  final String picName;
  final String phone;
  final String email;
  final String password;
  final String address;
  final String region;
  final bool termsAccepted;
  final String? licenseImageName;
}

class TransportirRegistrationDraft {
  const TransportirRegistrationDraft({
    required this.transportirName,
    required this.phone,
    required this.email,
    required this.password,
    required this.termsAccepted,
  });

  final String transportirName;
  final String phone;
  final String email;
  final String password;
  final bool termsAccepted;
}

class PasswordResetChallenge {
  const PasswordResetChallenge({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;
}
