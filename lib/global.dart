import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

String get logPath {
  return path.join(path.dirname(Platform.resolvedExecutable), 'log.txt');
}

var log = Logger(
  printer: SimplePrinter(printTime: true, colors: false),
  output: MultiOutput([ConsoleOutput(), FileOutput(file: File(logPath))]),
);
