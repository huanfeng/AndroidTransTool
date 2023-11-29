import 'package:android_trans_tool/data/project.dart';
import 'package:android_trans_tool/utils/picker_utils.dart';
import 'package:flutter/material.dart';

import '../widgets/panel_layout.dart';
import 'project_setting.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  final Project _project = Project("New Project");

  Future<void> _showProjectSettingDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('项目设置'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ProjectSetting(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
              icon: const Icon(Icons.file_open),
              label: const Text("打开项目"),
              onPressed: () {
                openDirectoryPacker(
                    title: "请选择安卓工程目录",
                    cb: (dir) {
                      _project.loadFrom(dir);
                      setState(() {});
                    });
              }),
          TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text("项目设置"),
              onPressed: () {
                Navigator.pushNamed(context, 'project_setting');
              }),
          TextButton.icon(
              icon: const Icon(Icons.settings_applications),
              label: const Text("系统设置"),
              onPressed: () {
                Navigator.pushNamed(context, 'setting');
              }),
          const SizedBox(width: 30),
        ],
      ),
      body: SimplePanelLayout(
        left: DecoratedBox(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 1)),
            child: Center(
              child: ListView.builder(itemBuilder: (context, index) {
                if (index < _project.resDirs.length) {
                  return ListTile(title: Text(_project.resDirs[index]));
                }
                return null;
              }),
            )),
        right: DecoratedBox(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 1)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            )),
        top: Align(
            alignment: Alignment.topLeft,
            child: Row(children: [Text("项目路径: ${_project.projectDir}")])),
        bottom: Align(
            alignment: Alignment.topLeft,
            child: Row(children: [Text("状态栏: ${_project.projectDir}")])),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
