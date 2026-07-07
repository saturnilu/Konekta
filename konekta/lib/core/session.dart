import 'package:shared_preferences/shared_preferences.dart';

class Session {
  final SharedPreferences _prefs;
  Session(this._prefs);

  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kUserId = 'auth_user_id';
  static const _kName = 'auth_name';

  String? get token => _prefs.getString(_kToken);
  String? get role => _prefs.getString(_kRole);
  int? get userId => _prefs.getInt(_kUserId);
  String? get name => _prefs.getString(_kName);
  bool get isLoggedIn => token != null;

  Future<void> save({required String token, required String role, required int userId, required String name}) async {
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kRole, role);
    await _prefs.setInt(_kUserId, userId);
    await _prefs.setString(_kName, name);
  }

  Future<void> clear() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kRole);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kName);
  }
}
