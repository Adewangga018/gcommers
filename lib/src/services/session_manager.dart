import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class SessionManager {
  static const _keyEmail = 'session_email';
  static const _keyRole = 'session_role';
  static const _keyDisplayName = 'session_display_name';
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
    await Future.wait([
      _prefs.setString(_keyEmail, session.email),
      _prefs.setString(_keyRole, session.role),
      _prefs.setString(_keyDisplayName, session.displayName),
      _prefs.setString(_keyToken, session.token ?? ''),
      _prefs.setString(_keyPhone, session.phone ?? ''),
      _prefs.setString(_keyAddress, session.address ?? ''),
      _prefs.setString(_keyPicName, session.picName ?? ''),
      _prefs.setString(_keyRegion, session.region ?? ''),
    ]);
  }

  Future<AuthSession?> getSession() async {
    await _ensureInit();
    final email = _prefs.getString(_keyEmail);
    final role = _prefs.getString(_keyRole);
    final displayName = _prefs.getString(_keyDisplayName);
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
      token: token,
      phone: phone?.isEmpty == true ? null : phone,
      address: address?.isEmpty == true ? null : address,
      picName: picName?.isEmpty == true ? null : picName,
      region: region?.isEmpty == true ? null : region,
    );
  }

  Future<void> saveAvatarBytes(Uint8List bytes) async {
    await _ensureInit();
    await _prefs.setString(_keyAvatarB64, base64Encode(bytes));
  }

  Future<Uint8List?> loadAvatarBytes() async {
    await _ensureInit();
    final str = _prefs.getString(_keyAvatarB64);
    if (str == null || str.isEmpty) return null;
    return base64Decode(str);
  }

  Future<void> clearSession() async {
    await _ensureInit();
    await Future.wait([
      _prefs.remove(_keyEmail),
      _prefs.remove(_keyRole),
      _prefs.remove(_keyDisplayName),
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
}

final sessionManager = SessionManager();
