import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../global.dart';

void openOneFilePicker(
    {String? title,
    List<String>? allowedExtensions,
    required ValueChanged<String> cb}) async {
  var result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    dialogTitle: title,
    allowedExtensions: allowedExtensions,
    lockParentWindow: true,
  );
  log.d('result=$result');
  var file = result?.files.single;
  // 打开文件选择
  if (file != null) {
    log.d('filePaths=$file');
    if (file.path != null) {
      cb(file.path!);
    }
  }
}

void openDirectoryPacker(
    {String? title, required ValueChanged<String> cb}) async {
  final result = await FilePicker.platform.getDirectoryPath(
    dialogTitle: title,
    lockParentWindow: true,
  );
  if (result != null) {
    cb(result);
  }
}
