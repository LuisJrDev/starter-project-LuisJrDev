import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _key = 'device_id';
  final SharedPreferences _prefs;
  final Uuid _uuid;

  DeviceIdService(this._prefs, this._uuid);

  String getOrCreate() {
    final existing = _prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _uuid.v4();
    _prefs.setString(_key, id);
    return id;
  }
}
