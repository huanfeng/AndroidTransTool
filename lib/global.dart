import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

String get logPath {
  if (kIsWeb) return '';
  return path.join(path.dirname(Platform.resolvedExecutable), 'log.txt');
}

var log = Logger(
  printer: SimplePrinter(printTime: true, colors: false),
  output: MultiOutput(
      [ConsoleOutput(), kIsWeb ? null : FileOutput(file: File(logPath))]),
);
