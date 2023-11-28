import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static late SharedPreferences gPrefs;

  static Future<void> init() async {
    gPrefs = await SharedPreferences.getInstance();
  }

  static void loadConfig() {
    final prefs = gPrefs;
  }
}
