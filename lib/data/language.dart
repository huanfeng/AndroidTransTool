enum Language {
  def("", "默认(英文)", "Default(English)"),
  cn("zh-rCN", "简体中文", "Simplified Chinese"),
  cnHk("zh-rHK", "繁体中文", "Traditional Chinese"),
  // cnTw("zh-rTW", "繁体中文", "Traditional Chinese"),
  ar("ar", "阿拉伯语", "Arabic"),
  de("de", "德语", "German"),
  fr("fr", "法语", "French"),
  hi("hi", "印地语", "Hindi"),
  it("it", "意大利语", "Italian"),
  iw("iw", "希伯来语", "Hebrew"),
  ja("ja", "日语", "Japanese"),
  ko("ko", "韩语", "Korean"),
  ru("ru", "俄语", "Russian"),
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
}
