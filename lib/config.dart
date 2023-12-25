import 'package:shared_preferences/shared_preferences.dart';

import 'data/language.dart';
import 'global.dart';

class ConfigItem<T> {
  ConfigItem(this.key, this.defaultValue) : _value = defaultValue;

  final String key;
  final T defaultValue;
  T _value;

  T get value => _value;

  set value(T value) {
    log.d("ConfigItem: set $key=$value");
    _value = value;
    if (value is String) {
      Config.gPrefs.setString(key, value);
    } else if (value is bool) {
      Config.gPrefs.setBool(key, value);
    } else if (value is int) {
      Config.gPrefs.setInt(key, value);
    } else if (value is double) {
      Config.gPrefs.setDouble(key, value);
    } else if (value is List<String>) {
      Config.gPrefs.setStringList(key, value);
    } else {
      throw Exception("ConfigItem: not support type: ${value.runtimeType}");
    }
  }

  void load() {
    if (_value is String) {
      final v = Config.gPrefs.getString(key)?.trim() ?? defaultValue;
      _value = v as T;
    } else if (_value is bool) {
      final v = Config.gPrefs.getBool(key) ?? defaultValue;
      _value = v as T;
    } else if (_value is int) {
      final v = Config.gPrefs.getInt(key) ?? defaultValue;
      _value = v as T;
    } else if (_value is double) {
      final v = Config.gPrefs.getDouble(key) ?? defaultValue;
      _value = v as T;
    } else if (_value is List<String>) {
      final v = Config.gPrefs.getStringList(key) ?? defaultValue;
      _value = v as T;
    } else {
      throw Exception("ConfigItem: not support type: ${_value.runtimeType}");
    }
  }
}

class Config {
  static late SharedPreferences gPrefs;

  static final apiToken = ConfigItem("api_token", "");
  static final apiUrl = ConfigItem("apiUrl", "");
  static final debugv = ConfigItem("debugv", false);
  static final enabledLanguages = ConfigItem("enable_language",
      Language.supportedLanguages.map((e) => e.code).toList());

  static final httpProxy = ConfigItem("http_proxy", "");

  static final leftPanelFlex = ConfigItem("left_panel_flex", 0.3);
  static final bottomPanelFlex = ConfigItem("bottom_panel_flex", 0.2);

  static final List<ConfigItem> configs = [
    apiToken,
    apiUrl,
    debugv,
    enabledLanguages,
    httpProxy,
    leftPanelFlex,
  ];

  static Future<void> init() async {
    gPrefs = await SharedPreferences.getInstance();
  }

  static void loadConfig() {
    log.i("loadConfig start: item.size=${configs.length}");

    for (final item in configs) {
      item.load();
      log.i("loadConfig: ${item.key}=${item.value}");
    }
  }
}
