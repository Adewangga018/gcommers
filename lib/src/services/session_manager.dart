import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class SessionManager {
  static const _keyEmail = 'session_email';
  static const _keyRole = 'session_role';
  static const _keyDisplayName = 'session_display_name';
  static const _keyTransportirName = 'session_transportir_name';
  static const _keyCompanyName = 'session_company_name';
  static const _keyPoliceNumber = 'session_police_number';
  static const _keyVehicleType = 'session_vehicle_type';
  static const _keyToken = 'session_token';
  static const _keyPhone = 'session_phone';
  static const _keyAddress = 'session_address';
  static const _keyPicName = 'session_pic_name';
  static const _keyRegion = 'session_region';
  static const _keyAvatarB64 = 'session_avatar_b64';

  late final SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<void> saveSession(AuthSession session) async {
    await _ensureInit();
    final avatarKey = _avatarKeyForEmail(session.email);
    final futures = <Future>[
      _prefs.setString(_keyEmail, session.email),
      _prefs.setString(_keyRole, session.role),
      _prefs.setString(_keyDisplayName, session.displayName),
      _prefs.setString(_keyTransportirName, session.transportirName ?? ''),
      _prefs.setString(_keyCompanyName, session.companyName ?? ''),
      _prefs.setString(_keyPoliceNumber, session.policeNumber ?? ''),
      _prefs.setString(_keyVehicleType, session.vehicleType ?? ''),
      _prefs.setString(_keyToken, session.token ?? ''),
      _prefs.setString(_keyPhone, session.phone ?? ''),
      _prefs.setString(_keyAddress, session.address ?? ''),
      _prefs.setString(_keyPicName, session.picName ?? ''),
      _prefs.setString(_keyRegion, session.region ?? ''),
    ];
    if (session.avatarImageBase64 != null && session.avatarImageBase64!.isNotEmpty) {
      try {
        base64Decode(session.avatarImageBase64!);
        futures.add(_prefs.setString(avatarKey, session.avatarImageBase64!));
        futures.add(_prefs.setString(_keyAvatarB64, session.avatarImageBase64!));
      } catch (e) {
        debugPrint('SessionManager: invalid avatar base64 from server: $e');
      }
    } else {
      futures.add(_prefs.remove(avatarKey));
      futures.add(_prefs.remove(_keyAvatarB64));
    }
    await Future.wait(futures);
  }

  Future<AuthSession?> getSession() async {
    await _ensureInit();
    final email = _prefs.getString(_keyEmail);
    final role = _prefs.getString(_keyRole);
    final displayName = _prefs.getString(_keyDisplayName);
    final transportirName = _prefs.getString(_keyTransportirName);
    final companyName = _prefs.getString(_keyCompanyName);
    final policeNumber = _prefs.getString(_keyPoliceNumber);
    final vehicleType = _prefs.getString(_keyVehicleType);
    final token = _prefs.getString(_keyToken);
    final phone = _prefs.getString(_keyPhone);
    final address = _prefs.getString(_keyAddress);
    final picName = _prefs.getString(_keyPicName);
    final region = _prefs.getString(_keyRegion);

    if (email == null || role == null || displayName == null) {
      return null;
    }

    return AuthSession(
      email: email,
      role: role,
      displayName: displayName,
      transportirName: transportirName?.isNotEmpty == true ? transportirName : null,
      companyName: companyName?.isNotEmpty == true ? companyName : null,
      policeNumber: policeNumber?.isNotEmpty == true ? policeNumber : null,
      vehicleType: vehicleType?.isNotEmpty == true ? vehicleType : null,
      token: token,
      phone: phone?.isEmpty == true ? null : phone,
      address: address?.isEmpty == true ? null : address,
      picName: picName?.isEmpty == true ? null : picName,
      region: region?.isEmpty == true ? null : region,
      avatarImageBase64: _loadAvatarBase64ForEmail(email),
    );
  }

  Future<void> saveAvatarBytes(Uint8List bytes, {String? email}) async {
    await _ensureInit();
    final encoded = base64Encode(bytes);
    final futures = <Future>[_prefs.setString(_keyAvatarB64, encoded)];
    if (email != null && email.trim().isNotEmpty) {
      futures.add(_prefs.setString(_avatarKeyForEmail(email), encoded));
    }
    await Future.wait(futures);
  }

  Future<Uint8List?> loadAvatarBytes({String? email}) async {
    await _ensureInit();
    final str = email == null
        ? _prefs.getString(_keyAvatarB64)
        : _loadAvatarBase64ForEmail(email);
    if (str == null || str.isEmpty) return null;
    return base64Decode(str);
  }

  Future<void> clearSession() async {
    await _ensureInit();
    await Future.wait([
      _prefs.remove(_keyEmail),
      _prefs.remove(_keyRole),
      _prefs.remove(_keyDisplayName),
      _prefs.remove(_keyTransportirName),
      _prefs.remove(_keyCompanyName),
      _prefs.remove(_keyPoliceNumber),
      _prefs.remove(_keyVehicleType),
      _prefs.remove(_keyToken),
      _prefs.remove(_keyPhone),
      _prefs.remove(_keyAddress),
      _prefs.remove(_keyPicName),
      _prefs.remove(_keyRegion),
      _prefs.remove(_keyAvatarB64),
    ]);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }

  String _avatarKeyForEmail(String email) =>
      '${_keyAvatarB64}_${email.trim().toLowerCase()}';

  String? _loadAvatarBase64ForEmail(String email) {
    return _prefs.getString(_avatarKeyForEmail(email)) ??
        _prefs.getString(_keyAvatarB64);
  }
}

final sessionManager = SessionManager();
