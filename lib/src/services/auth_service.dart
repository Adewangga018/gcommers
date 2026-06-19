import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_models.dart';

class AuthService {
  AuthService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:5000',
            );

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _decodeAuthSession(response);
  }

  Future<PasswordResetChallenge> requestPasswordReset({
    required String email,
  }) async {
    final response = await http.post(
      _uri('/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PasswordResetChallenge(
        email: data['email'] as String,
        otp: data['otp'] as String,
      );
    }

    throw _toException(response);
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      _uri('/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode != 200) {
      throw _toException(response);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      _uri('/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw _toException(response);
    }
  }

  Future<String> uploadKtp({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/auth/upload-ktp'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['fileName'] as String;
    }

    throw _toException(response);
  }

  Future<AuthSession> registerKiosk(KioskRegistrationDraft draft) async {
    final response = await http.post(
      _uri('/auth/register-kiosk'),
      headers: _headers,
      body: jsonEncode({
        'kioskName': draft.kioskName,
        'picName': draft.picName,
        'phone': draft.phone,
        'email': draft.email,
        'password': draft.password,
        'address': draft.address,
        'region': draft.region,
        'provinsiId': draft.provinsiId,
        'kabupatenId': draft.kabupatenId,
        'kecamatanId': draft.kecamatanId,
        'termsAccepted': draft.termsAccepted,
        'licenseImageName': draft.licenseImageName,
      }),
    );

    return _decodeAuthSession(response);
  }

  Future<AuthSession> updateProfile({
    required String email,
    required String displayName,
    String? picName,
    String? phone,
    String? address,
    String? avatarImageBase64,
  }) async {
    final response = await http.put(
      _uri('/auth/profile'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'displayName': displayName,
        'picName': picName,
        'phone': phone,
        'address': address,
        'avatarImageBase64': avatarImageBase64,
      }),
    );
    return _decodeAuthSession(response);
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await http.post(
      _uri('/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw _toException(response);
    }
  }

  Future<AuthSession> registerTransportir(TransportirRegistrationDraft draft) async {
    final response = await http.post(
      _uri('/auth/register-transportir'),
      headers: _headers,
      body: jsonEncode({
        'transportirName': draft.transportirName,
        'companyName': draft.companyName,
        'phone': draft.phone,
        'policeNumber': draft.policeNumber,
        'type': draft.type,
        'email': draft.email,
        'password': draft.password,
        'termsAccepted': draft.termsAccepted,
      }),
    );

    return _decodeAuthSession(response);
  }

  AuthSession _decodeAuthSession(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession(
        email: data['email'] as String,
        role: data['role'] as String,
        displayName: data['displayName'] as String,
        transportirName: data['transportirName'] as String?,
        companyName: data['companyName'] as String?,
        policeNumber: data['policeNumber'] as String?,
        vehicleType: data['vehicleType'] as String?,
        token: data['token'] as String?,
        phone: data['phone'] as String?,
        picName: data['picName'] as String?,
        address: data['address'] as String?,
        region: data['region'] as String?,
        avatarImageBase64: data['avatarImageBase64'] as String?,
        provinsiNama: data['provinsiNama'] as String?,
        kabupatenNama: data['kabupatenNama'] as String?,
        kecamatanNama: data['kecamatanNama'] as String?,
      );
    }

    throw _toException(response);
  }

  Exception _toException(http.Response response) {
    if (response.body.isEmpty) {
      return Exception('Request failed with status ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) {
          return Exception(message);
        }
      }
    } catch (_) {
      debugPrint('Failed to decode auth error body');
    }

    return Exception('Request failed with status ${response.statusCode}');
  }
}
