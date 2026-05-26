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
      _prefs.setString(_keyTransportirName, session.transportirName ?? ''),
      _prefs.setString(_keyCompanyName, session.companyName ?? ''),
      _prefs.setString(_keyPoliceNumber, session.policeNumber ?? ''),
      _prefs.setString(_keyVehicleType, session.vehicleType ?? ''),
      _prefs.setString(_keyToken, session.token ?? ''),
    ]);
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
    );
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
    ]);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }
}

final sessionManager = SessionManager();
