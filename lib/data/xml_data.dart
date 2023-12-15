import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../config.dart';
import '../global.dart';
import '../trans/trans_data.dart';
import '../utils/string_utils.dart';
import 'language.dart';
import 'project.dart';

const typeString = "string";
const typeStringArray = "string-array";

abstract class ResItem<T> {
  String type;

  // Key
  String name = "";

  // 是否可翻译, 如果标记了不可翻译, 则不进行翻译
  bool translatable = true;

  // 语言对应的值
  Map<Language, T> valueMap = {};

  ResItem(this.type, this.name, {this.translatable = true});

  T? getLangItem(Language lang) {
    return valueMap[lang];
  }

  // 生成xml
  void buildXml(XmlBuilder builder, T targetValue);
}

class StringItem extends ResItem<String> {
  StringItem(name, {translatable = true})
      : super(typeString, name, translatable: translatable);

  @override
  void buildXml(XmlBuilder builder, String targetValue) {
    builder.element(type, nest: () {
      builder.attribute('name', name);
      builder.text(targetValue);
    });
  }
}

class ArrayItem extends ResItem<List<String>> {
  ArrayItem(name, {translatable = true})
      : super(typeStringArray, name, translatable: translatable);

  @override
  void buildXml(XmlBuilder builder, List<String> targetValue) {
    builder.element(type, nest: () {
      builder.attribute('name', name);
      for (final item in targetValue) {
        builder.element('item', nest: () {
          builder.text(item);
        });
      }
    });
  }
}

class XmlData {
  // 文件名称
  String fileName = "";

  // 原始文本: name -> Item
  final List<ResItem> items = [];

// Map用于快速查找
  final Map<String, ResItem> _itemsMap = {};

  // 翻译后的文本
  final Map<String, ResItem> translatedItems = {};

  XmlData setFileName(String name) {
    fileName = name;
    return this;
  }

  void _loadOneDir(String rootDir, String subDir) {
    final file = File(path.join(rootDir, subDir, fileName));
    if (file.existsSync()) {
      final xmlText = file.readAsStringSync();
      final doc = XmlDocument.parse(xmlText);
      final langCode = subDir.startsWith(valuesDirPrefix)
          ? subDir.substring(valuesDirPrefix.length)
          : subDir.substring(valuesDirName.length);
      log.d("_loadOneDir lang:[$langCode]");
      final lang = Language.fromCode(langCode);
      if (lang == null) {
        log.w("_loadOneDir WARNING: lang:[$langCode] not found");
        return;
      }
      final root = doc.getElement("resources");
      if (root == null) {
        log.w("_loadOneDir WARNING: not resources");
        return;
      }
      final elements = root.findElements("*");
      for (final it in elements) {
        final type = it.name.local;
        final name = it.getAttribute("name") ?? "";
        final translatable = !(it.getAttribute("translatable") == "false");
        if (type == typeString) {
          final value = it.firstChild?.value?.trimDQ() ?? "";
          if (_itemsMap.containsKey(name)) {
            final si = _itemsMap[name]!;
            si.valueMap[lang] = value.trimDQ();
          } else {
            final si = StringItem(name, translatable: translatable);
            si.valueMap[lang] = value.trimDQ();
            items.add(si);
            _itemsMap[name] = si;
          }
        } else if (type == typeStringArray) {
          final elements = it.findElements("item");
          final stringList = <String>[];
          for (final i in elements) {
            stringList.add(i.firstChild?.value?.trimDQ() ?? "");
          }
          if (_itemsMap.containsKey(name)) {
            final si = _itemsMap[name]!;
            si.valueMap[lang] = stringList;
          } else {
            final si = ArrayItem(name, translatable: translatable);
            si.valueMap[lang] = stringList;
            items.add(si);
            _itemsMap[name] = si;
          }
        }
        final value = it.firstChild?.value ?? "";
        if (Config.debugv.value) {
          log.d("  name:$name, translatable=$translatable, value=$value");
        }
      }
    }
  }

  void clear() {
    items.clear();
    _itemsMap.clear();
    translatedItems.clear();
  }

  void load(String resDir) {
    clear();
    log.d("load: resDir=$resDir, fileName=$fileName");

    // 需要保证 valuesDirs 的顺序, 默认的需要在最前, 不然会影响生成后的顺序
    for (final lang in Language.supportedLanguages) {
      _loadOneDir(resDir, lang.valuesDirName);
    }
  }

  ResItem? getTranslatedItem(String key) {
    return translatedItems[key];
  }

  ResItem getOrCreateTranslatedItem(TransItem item) {
    if (translatedItems.containsKey(item.key)) {
      return translatedItems[item.key]!;
    } else {
      final newItem = item.toResItem();
      translatedItems[item.key] = newItem;
      return newItem;
    }
  }

  bool hasTranslatedData() {
    var count = 0;
    for (final item in translatedItems.values) {
      count += item.valueMap.length;
    }
    return count > 0;
  }

  List<Language> getTranslatedLanguages() {
    final result = <Language>[];
    for (final item in translatedItems.values) {
      for (final it in item.valueMap.entries) {
        if (!result.contains(it.key)) {
          result.add(it.key);
        }
      }
    }
    return result;
  }

  XmlDocument buildXml(Language lang) {
    final b = XmlBuilder();
    b.declaration(encoding: 'utf-8');
    b.element('resources', nest: () {
      // 使用这个是为了保证顺序
      for (var it in items) {
        final key = it.name;
        if (!it.translatable) {
          log.d("buildStringXml: ignore none translatable [$key]");
          continue;
        }
        final transIt = translatedItems[key];
        final targetText = transIt?.valueMap[lang] ?? it.valueMap[lang];
        if (targetText == null) {
          log.i("buildStringXml: ignore null text [$key]");
          continue;
        }
        it.buildXml(b, targetText);
      }
    });
    final document = b.buildDocument();
    return document;
  }

  void saveToDir(String resDir, Language lang) {
    log.d(
        "saveToDir: resDir=$resDir, lang=$lang, valueDirName=${lang.valuesDirName}");
    final file = File(path.join(resDir, lang.valuesDirName, fileName));
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    final doc = buildXml(lang);
    file.writeAsStringSync(doc.toXmlString(pretty: true, indent: "    "));
  }
}
