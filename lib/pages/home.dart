import 'dart:developer';

import 'package:flutter/material.dart';

import '../data/language.dart';
import '../data/project.dart';
import '../utils/picker_utils.dart';
import '../widgets/panel_layout.dart';
import 'project_setting.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedResDirIndex = -1;
  int selectedXmlFileIndex = -1;
  int selectedXmlLine = -1;

  final Project _project = Project("New Project");
  final ResDirInfo _currentResInfo = ResDirInfo();
  final XmlStringData _xmlData = XmlStringData();

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

  List<DataColumn> dataColumns() {
    final list = <DataColumn>[
      const DataColumn(label: Text('ID')),
      const DataColumn(label: Text('可翻译')),
    ];

    Languages.values.forEach((key, value) => list
        .add(DataColumn(label: Text(key.isEmpty ? value : "$value($key)"))));

    return list;
  }

  List<DataRow> dataRows() {
    final list = <DataRow>[];
    for (final (idx, it) in _xmlData.items.values.indexed) {
      final cells = <DataCell>[];
      cells.add(DataCell(Container(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(it.name))));
      cells.add(DataCell(Container(
          constraints: const BoxConstraints(maxWidth: 30),
          child: Text(it.translatable ? "yes" : "no"))));
      Languages.values.forEach((key, value) {
        final v = it.valueMap[key] ?? "";
        cells.add(DataCell(DecoratedBox(
          decoration: BoxDecoration(
              border: v.isNotEmpty || !it.translatable
                  ? null
                  : Border.all(color: Colors.red)),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: SizedBox.expand(child: Text(v))),
        )));
      });
      list.add(DataRow(
        cells: cells,
        selected: idx == selectedXmlLine,
        onSelectChanged: (value) {
          if (value == true) {
            selectedXmlLine = idx;
            setState(() {});
          }
        },
      ));
    }
    return list;
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
                      _currentResInfo.reset();
                      selectedResDirIndex = -1;
                      selectedXmlFileIndex = -1;
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
            child: Column(children: [
              DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.greenAccent),
                  child: Text("共找到${_project.resDirs.length}个res目录")),
              Expanded(child: ListView.builder(itemBuilder: (context, index) {
                if (index < _project.resDirs.length) {
                  final children = <Widget>[];
                  children.add(ListTile(
                      title: Text(_project.resDirs[index]),
                      selected: index == selectedResDirIndex,
                      onTap: () {
                        if (selectedResDirIndex != index) {
                          setState(() {
                            _currentResInfo.load(_project.getResDirPath(index));
                            selectedResDirIndex = index;
                            selectedXmlFileIndex = -1;
                          });
                        }
                      }));
                  if (index < _project.resDirs.length - 1) {
                    children.add(const Divider());
                  }
                  return Column(
                    children: children,
                  );
                }
                return null;
              })),
              DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.greenAccent),
                  child: Text(
                      "已选择: ${selectedResDirIndex >= 0 ? _project.resDirs.elementAtOrNull(selectedResDirIndex) ?? "" : ""}")),
              Expanded(child: ListView.builder(itemBuilder: (context, index) {
                if (index < _currentResInfo.xmlFileNames.length) {
                  final children = <Widget>[];
                  children.add(ListTile(
                      title:
                          Text(_currentResInfo.xmlFileNames.elementAt(index)),
                      selected: index == selectedXmlFileIndex,
                      onTap: () {
                        selectedXmlFileIndex = index;
                        final xmlFileName =
                            _currentResInfo.xmlFileNames.elementAt(index);
                        log("onTap: index=$index, name=$xmlFileName");
                        _xmlData.setFileName(xmlFileName);
                        _xmlData.load(_currentResInfo);
                        setState(() {});
                      }));
                  if (index < _currentResInfo.xmlFileNames.length - 1) {
                    children.add(const Divider());
                  }
                  return Column(
                    children: children,
                  );
                }
                return null;
              })),
            ])),
        right: DecoratedBox(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            showCheckboxColumn: false,
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.greenAccent),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            showBottomBorder: true,
                            columns: dataColumns(),
                            rows: dataRows(),
                          ))))
            ],
          ),
        ),
        top: Align(
            alignment: Alignment.topLeft,
            child: Row(children: [Text("项目路径: ${_project.projectDir}")])),
        bottom: Align(
            alignment: Alignment.topLeft,
            child: Row(children: [
              Text(
                  "状态栏: resDir=$selectedResDirIndex, xmlFile=$selectedXmlFileIndex, xmlName=${_xmlData.fileName}"),
            ])),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
