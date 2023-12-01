import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static late SharedPreferences gPrefs;

  static Future<void> init() async {
    gPrefs = await SharedPreferences.getInstance();
  }

  static void loadConfig() {
    final prefs = gPrefs;
    _apiToken = prefs.getString(_keyApiToken) ?? _apiToken;
  }

  static const _keyApiToken = "api_token";

  static String _apiToken = "";

  static String get apiToken => _apiToken;

  static set apiToken(String value) {
    _apiToken = value.trim();
    gPrefs.setString(_keyApiToken, _apiToken);
  }
}
