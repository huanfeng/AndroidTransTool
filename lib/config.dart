import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class ConfigItem<T> {
  ConfigItem(this.key, this.defaultValue) : _value = defaultValue {
    Config.configs.add(this);
  }

  final String key;
  final T defaultValue;
  T _value;

  T get value => _value;

  set value(T value) {
    log("ConfigItem: set $key=$value");
    _value = value;
    if (value is String) {
      Config.gPrefs.setString(key, value);
    } else if (value is bool) {
      Config.gPrefs.setBool(key, value);
    } else if (value is int) {
      Config.gPrefs.setInt(key, value);
    } else if (value is double) {
      Config.gPrefs.setDouble(key, value);
    } else {
      throw Exception("ConfigItem: not support type: ${value.runtimeType}");
    }
  }

  void load() {
    if (_value is String) {
      final v = Config.gPrefs.getString(key)?.trim() ?? "";
      _value = v as T;
    } else if (_value is bool) {
      final v = Config.gPrefs.getBool(key) ?? false;
      _value = v as T;
    } else if (_value is int) {
      final v = Config.gPrefs.getInt(key) ?? 0;
      _value = v as T;
    } else if (_value is double) {
      final v = Config.gPrefs.getDouble(key) ?? 0;
      _value = v as T;
    } else {
      throw Exception("ConfigItem: not support type: ${_value.runtimeType}");
    }
  }
}

class Config {
  static late SharedPreferences gPrefs;
  static List<ConfigItem> configs = [];

  static Future<void> init() async {
    gPrefs = await SharedPreferences.getInstance();
  }

  static void loadConfig() {
    for (final item in configs) {
      item.load();
    }
  }

  static final apiToken = ConfigItem("api_token", "");
  static final apiUrl = ConfigItem("apiUrl", "");
  static final debugv = ConfigItem("debugv", false);
}
