import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../utils/string_utils.dart';

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
          log("scanResDirs: add res dir=${item.path}");
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
      log("scanResult: resDirs=$resDirs");
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
          log("scanStringsXmlFiles: add xml file=${item.path}");
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

  bool translatable = true;

  // 语言对应的值
  Map<String, String> valueMap = {};

  StringItem(this.name, {this.translatable = true});
}

class XmlStringData {
  // 文件名称
  String fileName = "";

  // name -> Item
  Map<String, StringItem> items = {};

  XmlStringData setFileName(String name) {
    fileName = name;
    return this;
  }

  void load(ResDirInfo res) {
    items.clear();
    log("load: res=$res, fileName=$fileName");

    for (final subDir in res.valuesDirs) {
      final file = File(path.join(res.dir, subDir, fileName));
      if (file.existsSync()) {
        final xmlText = file.readAsStringSync();
        final doc = XmlDocument.parse(xmlText);
        final lang = subDir.startsWith(valuesDirPrefix)
            ? subDir.substring(valuesDirPrefix.length)
            : subDir.substring(valuesDirName.length);
        log("lang:[$lang]");
        final strings = doc.findAllElements("string");
        for (final it in strings) {
          final name = it.getAttribute("name") ?? "";
          final translatable = !(it.getAttribute("translatable") == "false");
          final value = it.firstChild?.value ?? "";
          log("  name:$name, translatable=$translatable, value=$value");
          if (items.containsKey(name)) {
            final si = items[name]!;
            si.valueMap[lang] = value.trimDQ();
          } else {
            final si = StringItem(name, translatable: translatable);
            si.valueMap[lang] = value.trimDQ();
            items[name] = si;
          }
        }
        log("lang:[$lang] rootElement: ${doc.rootElement.name}");
      }
    }
  }
}
