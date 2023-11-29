import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as path;

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
        log("scanResDirs: dir=${item.path}");
        if (name == 'res') {
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
      result.forEach((element) {
        resDirs.add(path.relative(element, from: dir));
      });
      log("scanResult: resDirs=$resDirs");
    }
  }
}
