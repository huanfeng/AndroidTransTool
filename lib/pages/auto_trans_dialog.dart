import 'package:flutter/material.dart';

class AutoTranDialog extends StatefulWidget {
  const AutoTranDialog({super.key});

  @override
  State<AutoTranDialog> createState() => _AutoTranDialogState();
}

class _AutoTranDialogState extends State<AutoTranDialog> {
  var _autoSelect = true;
  var _autoSave = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('一键翻译'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            CheckboxListTile(
                value: _autoSelect,
                title: const Text('自动选中语言'),
                onChanged: (value) {
                  setState(() {
                    _autoSelect = value!;
                  });
                }),
            CheckboxListTile(
                value: _autoSave,
                title: const Text('自动保存'),
                onChanged: (value) {
                  setState(() {
                    _autoSave = value!;
                  });
                }),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('开始'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
