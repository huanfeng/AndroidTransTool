import 'dart:convert';
import 'dart:math' as math;

import 'package:android_trans_tool/data/xml_data.dart';

import '../data/language.dart';

sealed class TransData {
  final bool isRequest;
  final Language targetLang;
  final List<TransItem> items;
  int start = 0;
  int count = 0;

  TransData(this.targetLang, this.items,
      {this.start = 0, int? count, this.isRequest = true}) {
    this.count = count ?? items.length;
  }

  TransItem? getItem(String key) {
    return items.firstWhere((element) => element.key == key);
  }

  @override
  String toString() {
    return 'TransData{targetLang: $targetLang, start: $start, count: $count}';
  }

  String toJson() {
    return jsonEncode(
        items.asMap().map((key, value) => MapEntry(value.key, value.srcValue)));
  }
}

class TransRequest extends TransData {
  TransRequest(super.targetLang, super.items,
      {super.start, super.count, super.isRequest = true});

  List<TransRequest> split(int size) {
    final result = <TransRequest>[];
    var start = 0;
    while (start < items.length) {
      final end = math.min(start + size, items.length);
      final subs = items.sublist(start, end);
      result.add(TransRequest(
        targetLang,
        subs,
      ));
      start = end;
    }
    return result;
  }
}

class TransResponse extends TransData {
  TransResponse(super.targetLang, super.items,
      {super.start, super.count, super.isRequest = false});
}

// 可翻译的条目, 可能是一个字符串, 也可以一个字符数组
class TransItem {
  final String key;
  final dynamic srcValue;
  dynamic dstValue;

  TransItem(this.key, this.srcValue) {
    if (key.isEmpty) {
      throw ArgumentError("TransItem key must not be empty");
    }
    if (!(srcValue is String || srcValue is List<String>)) {
      throw ArgumentError("TransItem srcValue must be String or List<String>");
    }
  }

  String valueToJson() {
    if (srcValue is String) {
      return srcValue as String;
    } else if (srcValue is List<String>) {
      return jsonEncode(srcValue);
    }
    throw ArgumentError("TransItem srcValue must be String or List<String>");
  }

  bool isList() {
    return srcValue is List<String>;
  }

  ResItem toResItem() {
    if (isList()) {
      return ArrayItem(key);
    } else {
      return StringItem(key);
    }
  }
}
