extension StringExt on String {
  static final _kNoneSingleQuotePattern = RegExp(r"[^']");

  // 去除前后的单引号
  String trimSQ() {
    final start = indexOf(_kNoneSingleQuotePattern);
    final end = lastIndexOf(_kNoneSingleQuotePattern);
    return substring(start < 0 ? 0 : start, end < 0 ? length : end + 1);
  }

  static final _kNoneDoubleQuotePattern = RegExp(r'[^"]');

  // 去除前后的双引号
  String trimDQ() {
    final start = indexOf(_kNoneDoubleQuotePattern);
    final end = lastIndexOf(_kNoneDoubleQuotePattern);
    return substring(start < 0 ? 0 : start, end < 0 ? length : end + 1);
  }
}
