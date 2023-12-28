import 'package:flutter/material.dart';

typedef OnAutoTransCallback = void Function(AutoTransConfig config);

class AutoTransConfig {
  var autoSelect = true;
  var autoSave = true;
}

class AutoTransDialog extends StatefulWidget {
  final OnAutoTransCallback callback;

  const AutoTransDialog(this.callback, {super.key});

  @override
  State<AutoTransDialog> createState() => _AutoTransDialogState();
}

class _AutoTransDialogState extends State<AutoTransDialog> {
  final _config = AutoTransConfig();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('一键翻译'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            CheckboxListTile(
                value: _config.autoSelect,
                title: const Text('自动选中语言'),
                onChanged: (value) {
                  setState(() {
                    _config.autoSelect = value!;
                  });
                }),
            CheckboxListTile(
                value: _config.autoSave,
                title: const Text('自动保存'),
                onChanged: (value) {
                  setState(() {
                    _config.autoSave = value!;
                  });
                }),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('开始'),
          onPressed: () {
            widget.callback(_config);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
