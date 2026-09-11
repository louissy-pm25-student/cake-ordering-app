import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cake_repository.dart';

class LocalCakeRepository implements CakeRepository {
  static const _key = 'sweet_studio_flutter_v1';
  final SharedPreferences preferences;
  LocalCakeRepository(this.preferences);
  @override
  Future<Map<String, dynamic>> load() async {
    final raw = preferences.getString(_key);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    if (!await preferences.setString(_key, jsonEncode(snapshot))) {
      throw StateError('Unable to save your cake order.');
    }
  }
}
