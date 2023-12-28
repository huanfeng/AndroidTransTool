import 'dart:io';

import 'package:android_trans_tool/config.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

String get logPath {
  if (kIsWeb) return '';
  return path.join(path.dirname(Platform.resolvedExecutable), 'log.txt');
}

var log = Logger(
  filter: logFilter,
  printer: SimplePrinter(printTime: true, colors: false),
  output: MultiOutput([
    ConsoleOutput(),
    kIsWeb ? null : FileOutput(file: File(logPath)),
  ]),
);

final configLogLevel =
    ConfigItem("log_level", Level.trace.index, onChanged: (value) {
  logFilter.level = Level.values[value];
});

final logFilter = ProductionFilter();
