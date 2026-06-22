class AuthSession {
  const AuthSession({
    required this.email,
    required this.role,
    required this.displayName,
    this.transportirName,
    this.companyName,
    this.policeNumber,
    this.vehicleType,
    this.phone,
    this.address,
    this.picName,
    this.region,
    this.token,
    this.avatarImageBase64,
    this.provinsiNama,
    this.kabupatenNama,
    this.kecamatanNama,
  });

  final String email;
  final String role;
  final String displayName;
  final String? transportirName;
  final String? companyName;
  final String? policeNumber;
  final String? vehicleType;
  final String? phone;
  final String? address;
  final String? picName;
  final String? region;
  final String? token;
  final String? avatarImageBase64;
  final String? provinsiNama;
  final String? kabupatenNama;
  final String? kecamatanNama;
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
    required this.provinsiId,
    required this.kabupatenId,
    required this.kecamatanId,
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
  final int provinsiId;
  final int kabupatenId;
  final int kecamatanId;
  final bool termsAccepted;
  final String? licenseImageName;
}

class TransportirRegistrationDraft {
  const TransportirRegistrationDraft({
    required this.transportirName,
    required this.companyName,
    required this.phone,
    required this.policeNumber,
    required this.type,
    required this.email,
    required this.password,
    required this.region,
    required this.termsAccepted,
  });

  final String transportirName;
  final String companyName;
  final String phone;
  final String policeNumber;
  final String type;
  final String email;
  final String password;
  final String region;
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
