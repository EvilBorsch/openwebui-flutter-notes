import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyBaseUrl = 'base_url';
  static const _keyToken = 'token';
  static const _keyModel = 'model';
  static const _keyCollectionId = 'collection_id';
  static const _keyDark = 'dark_mode';

  String baseUrl = 'http://localhost:3000';
  String token = '';
  String model = '';
  String collectionId = '';
  bool isDark = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_keyBaseUrl) ?? baseUrl;
    token = prefs.getString(_keyToken) ?? token;
    model = prefs.getString(_keyModel) ?? model;
    collectionId = prefs.getString(_keyCollectionId) ?? collectionId;
    isDark = prefs.getBool(_keyDark) ?? isDark;
    notifyListeners();
  }

  Future<void> update({
    String? baseUrl,
    String? token,
    String? model,
    String? collectionId,
    bool? isDark,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (baseUrl != null) {
      var cleaned = baseUrl.trim();
      // Collapse repeated slashes in the end
      while (cleaned.endsWith('/')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      this.baseUrl = cleaned;
      await prefs.setString(_keyBaseUrl, this.baseUrl);
    }
    if (token != null) {
      this.token = token;
      await prefs.setString(_keyToken, this.token);
    }
    if (model != null) {
      this.model = model;
      await prefs.setString(_keyModel, this.model);
    }
    if (collectionId != null) {
      this.collectionId = collectionId;
      await prefs.setString(_keyCollectionId, this.collectionId);
    }
    if (isDark != null) {
      this.isDark = isDark;
      await prefs.setBool(_keyDark, this.isDark);
    }
    notifyListeners();
  }
}
