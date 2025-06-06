import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../config.dart';
import '../global.dart';

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
      if (Config.debugv.value) {
        log.d("scanResult: resDirs=$resDirs");
      }
    }
  }

  String getResDirPath(int index) {
    if (index < 0 || index >= resDirs.length) {
      return "";
    }
    return path.join(projectDir, resDirs[index]);
  }

  String getResDir(int index) {
    if (index < 0 || index >= resDirs.length) {
      return "";
    }
    return resDirs[index];
  }
}

class ResDirInfo {
  String parent = "";
  String dir = "";
  String dirPath = "";
  Set<String> xmlFileNames = {};

  @override
  String toString() {
    return 'ResDirInfo{parent: $parent, dir: $dir}';
  }

  void load(String parent, String dir) {
    this.parent = parent;
    this.dir = dir;
    dirPath = path.join(parent, dir);
    xmlFileNames.clear();

    scanResValuesDir(dirPath);
  }

  void scanResValuesDir(String dir) {
    final list = Directory(dir).listSync();
    for (final item in list) {
      if (item is Directory) {
        final dirname = path.basename(item.path);
        if (dirname == valuesDirName) {
          _scanStringsXmlFiles(item.path);
        } else if (dirname.startsWith(valuesDirPrefix)) {}
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
    xmlFileNames.clear();
  }
}
