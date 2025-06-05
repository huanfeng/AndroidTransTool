import '../config.dart';

enum Language {
  def("", "默认(英文)", "Default(English)"),
  cn("zh-rCN", "简体中文", "Simplified Chinese"),
  cnHk("zh-rHK", "繁體中文", "Traditional Chinese"),
  cnTw("zh-rTW", "繁體中文", "Traditional Chinese"),
  ar("ar", "阿拉伯语", "Arabic"),
  de("de", "德语", "German"),
  fr("fr", "法语", "French"),
  hi("hi", "印地语", "Hindi"),
  it("it", "意大利语", "Italian"),
  iw("iw", "希伯来语", "Hebrew"),
  ja("ja", "日语", "Japanese"),
  ko("ko", "韩语", "Korean"),
  ru("ru", "俄语", "Russian"),
  uk("uk", "乌克兰语", "Ukrainian"),
  ;

  final String code;
  final String cnName;
  final String enName;

  const Language(this.code, this.cnName, this.enName);

  @override
  String toString() {
    return 'Language{code: $code, cnName: $cnName}';
  }

  String get valuesDirName {
    if (code.isEmpty) {
      return "values";
    }
    return "values-$code";
  }

  String get cnTitle {
    return code.isEmpty ? cnName : "$cnName($code)";
  }

  static final _map = <String, Language>{};

  static void _genMap() {
    for (final value in Language.values) {
      _map[value.code] = value;
    }
  }

  static Language? fromCode(String code) {
    if (_map.isEmpty) {
      _genMap();
    }
    return _map[code];
  }

  static List<Language> supportedLanguages = [
    Language.def,
    Language.cn,
    Language.cnHk,
    Language.ar,
    Language.de,
    Language.fr,
    Language.hi,
    Language.it,
    Language.iw,
    Language.ja,
    Language.ko,
    Language.ru,
    Language.uk,
  ];

  // 获取用户启用的语言列表
  static List<Language> getEnabledLanguages() {
    // 始终包含默认语言
    final result = <Language>[Language.def];

    // 从配置文件读取启用的语言代码列表
    try {
      final enabledCodes = Config.enabledLanguages.value;
      // 将语言代码转换为 Language 对象
      for (final code in enabledCodes) {
        if (code.isEmpty) continue; // 跳过默认语言，因为前面已经添加
        final language = Language.fromCode(code);
        if (language != null) {
          result.add(language);
        }
      }
    } catch (e) {
      // 错误情况下返回默认的支持语言列表
      return supportedLanguages;
    }

    // 如果没有启用任何语言，返回默认的支持语言列表
    if (result.length <= 1) {
      return supportedLanguages;
    }

    return result;
  }
}
