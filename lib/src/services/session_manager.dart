import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class SessionManager {
  static const _keyEmail = 'session_email';
  static const _keyRole = 'session_role';
  static const _keyDisplayName = 'session_display_name';
  static const _keyToken = 'session_token';

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
    ]);
  }

  Future<AuthSession?> getSession() async {
    await _ensureInit();
    final email = _prefs.getString(_keyEmail);
    final role = _prefs.getString(_keyRole);
    final displayName = _prefs.getString(_keyDisplayName);
    final token = _prefs.getString(_keyToken);

    if (email == null || role == null || displayName == null) {
      return null;
    }

    return AuthSession(
      email: email,
      role: role,
      displayName: displayName,
      token: token,
    );
  }

  Future<void> clearSession() async {
    await _ensureInit();
    await Future.wait([
      _prefs.remove(_keyEmail),
      _prefs.remove(_keyRole),
      _prefs.remove(_keyDisplayName),
      _prefs.remove(_keyToken),
    ]);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }
}

final sessionManager = SessionManager();
