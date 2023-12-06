import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../config.dart';
import '../global.dart';
import '../utils/string_utils.dart';
import 'language.dart';

const valuesDirName = "values";
const valuesDirPrefix = "values-";
const stringsFilePrefix = "strings";
const arraysFilePrefix = "arrays";

class Project {
  String name = "";
  String projectDir = "";

  List<String> resDirs = [];

  Project(this.name);

  static const kConfigFileName = "android_trans.json";

  static bool hasConfigFile(String dir) {
    final configFile = File(path.join(dir, kConfigFileName));
    return configFile.existsSync();
  }

  static final ignoreDirs = {'build', 'gradle'};

  static void scanResDirs(List<String> result, String dir) {
    final dirList = Directory(dir).listSync();
    for (final item in dirList) {
      if (item is Directory) {
        final name = path.basename(item.path);
        if (name == 'res') {
          log.d("scanResDirs: add res dir=${item.path}");
          result.add(item.path);
        } else if (!ignoreDirs.contains(name)) {
          scanResDirs(result, item.path);
        }
      }
    }
  }

  void loadFrom(String dir) {
    projectDir = dir;
    resDirs.clear();

    final configFile = File(path.join(dir, kConfigFileName));

    if (configFile.existsSync()) {
      final config = jsonDecode(configFile.readAsStringSync());
      name = config["name"];
      resDirs = List<String>.from(config["resDirs"]);
    } else {
      final result = <String>[];
      scanResDirs(result, dir);
      for (var element in result) {
        final relPath = path.relative(element, from: dir);
        resDirs.add(relPath);
      }
      log.d("scanResult: resDirs=$resDirs");
    }
  }

  String getResDirPath(int index) {
    if (index < 0 || index >= resDirs.length) {
      return "";
    }
    return path.join(projectDir, resDirs[index]);
  }
}

class ResDirInfo {
  String dir = "";
  List<String> valuesDirs = [];
  Set<String> xmlFileNames = {};

  @override
  String toString() {
    return 'ResDirInfo{dir: $dir}';
  }

  void load(String resDir) {
    dir = resDir;
    valuesDirs.clear();
    xmlFileNames.clear();

    scanResValuesDir(resDir);
    valuesDirs.sort();
  }

  void scanResValuesDir(String dir) {
    final list = Directory(dir).listSync();
    for (final item in list) {
      if (item is Directory) {
        final dirname = path.basename(item.path);
        if (dirname == valuesDirName) {
          valuesDirs.insert(0, dirname);
          _scanStringsXmlFiles(item.path);
        } else if (dirname.startsWith(valuesDirPrefix)) {
          valuesDirs.insert(0, dirname);
        }
      }
    }
  }

  void _scanStringsXmlFiles(String dir) {
    final fileList = Directory(dir).listSync();
    for (final item in fileList) {
      if (item is File) {
        final name = path.basename(item.path);
        if (name.startsWith(stringsFilePrefix) ||
            name.startsWith(arraysFilePrefix)) {
          log.d("scanStringsXmlFiles: add xml file=${item.path}");
          xmlFileNames.add(name);
        }
      }
    }
  }

  void reset() {
    dir = "";
    valuesDirs.clear();
    xmlFileNames.clear();
  }
}

class StringItem {
  // Key
  String name = "";

  // 是否可翻译, 如果标记了不可翻译, 则不进行翻译
  bool translatable = true;

  // 语言对应的值
  Map<Language, String> valueMap = {};

  StringItem(this.name, {this.translatable = true});
}

class XmlStringData {
  // 文件名称
  String fileName = "";

  // 原始文本: name -> Item
  final List<StringItem> items = [];

// Map用于快速查找
  final Map<String, StringItem> _itemsMap = {};

  // 翻译后的文本
  final Map<String, StringItem> translatedItems = {};

  XmlStringData setFileName(String name) {
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
      log.d("lang:[$langCode]");
      final lang = Language.fromCode(langCode);
      if (lang == null) {
        log.w("WARNING: lang:[$langCode] not found");
        return;
      }
      final strings = doc.findAllElements("string");
      for (final it in strings) {
        final name = it.getAttribute("name") ?? "";
        final translatable = !(it.getAttribute("translatable") == "false");
        final value = it.firstChild?.value ?? "";
        if (Config.debugv.value) {
          log.d("  name:$name, translatable=$translatable, value=$value");
        }
        if (_itemsMap.containsKey(name)) {
          final si = _itemsMap[name]!;
          si.valueMap[lang] = value.trimDQ();
        } else {
          final si = StringItem(name, translatable: translatable);
          si.valueMap[lang] = value.trimDQ();
          items.add(si);
          _itemsMap[name] = si;
        }
      }
    }
  }

  void clear() {
    items.clear();
    _itemsMap.clear();
    translatedItems.clear();
  }

  void load(ResDirInfo res) {
    clear();
    log.d("load: res=$res, fileName=$fileName");

    // 需要保证 valuesDirs 的顺序, 默认的需要在最前, 不然会影响生成后的顺序
    for (final subDir in res.valuesDirs) {
      _loadOneDir(res.dir, subDir);
    }
  }

  StringItem? getTranslatedItem(String key) {
    return translatedItems[key];
  }

  StringItem getOrCreateTranslatedItem(String key) {
    if (translatedItems.containsKey(key)) {
      return translatedItems[key]!;
    } else {
      final item = StringItem(key);
      translatedItems[key] = item;
      return item;
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

  XmlDocument buildStringXml(Language lang) {
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
        b.element('string', nest: () {
          b.attribute('name', it.name);
          b.text(targetText);
        });
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
    final doc = buildStringXml(lang);
    file.writeAsStringSync(doc.toXmlString(pretty: true, indent: "    "));
  }
}
