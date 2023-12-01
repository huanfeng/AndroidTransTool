import 'dart:developer';

import 'package:flutter/material.dart';

import '../data/language.dart';
import '../data/project.dart';
import '../trans/openai.dart';
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

  final _openAI = OpenAiTrans();

  @override
  void initState() {
    super.initState();
    _openAI.init();
  }

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
      const DataColumn(label: Text(''), numeric: true),
      const DataColumn(label: Text('ID')),
      const DataColumn(label: Text('可翻译')),
    ];

    for (var lang in Language.values) {
      list.add(DataColumn(
          label: Text(lang.code.isEmpty
              ? lang.cnName
              : "${lang.cnName}(${lang.code})")));
    }

    return list;
  }

  List<DataRow> dataRows() {
    final list = <DataRow>[];
    for (final (idx, it) in _xmlData.items.indexed) {
      final cells = <DataCell>[];
      cells.add(DataCell(Container(
          constraints: const BoxConstraints(maxWidth: 50),
          child: Text(idx.toString()))));
      cells.add(DataCell(Container(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(it.name))));
      cells.add(DataCell(Container(
          constraints: const BoxConstraints(maxWidth: 30),
          child: Text(it.translatable ? "yes" : "no"))));
      final transIt = _xmlData.getTranslatedItem(it.name);
      for (var lang in Language.values) {
        final v = it.valueMap[lang] ?? "";
        final transV = transIt != null ? transIt.valueMap[lang] : null;
        final hasTrans = transV != null && transV.isNotEmpty;
        cells.add(DataCell(DecoratedBox(
          decoration: BoxDecoration(
              border: v.isNotEmpty || !it.translatable
                  ? null
                  : Border.all(color: hasTrans ? Colors.blue : Colors.red)),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: SizedBox.expand(child: Text(hasTrans ? transV : v))),
        )));
      }
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
    final ScrollController tableVController = ScrollController();
    final ScrollController tableHController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(children: [
          Text(widget.title),
          const SizedBox(width: 60),
          const Text(
            "项目路径: ",
            style: TextStyle(fontSize: 16),
          ),
          SelectableText(
            _project.projectDir,
            style: const TextStyle(fontSize: 16),
          ),
        ]),
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
        // top: Container(
        //     height: 30,
        //     padding: const EdgeInsets.only(left: 10, right: 10),
        //     decoration: BoxDecoration(color: Colors.blue.withAlpha(50)),
        //     alignment: Alignment.centerLeft,
        //     child: Row(children: [Text("项目路径: ${_project.projectDir}")])),
        left: Container(
            width: 450,
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(80)),
            child: Column(children: [
              Container(
                  alignment: Alignment.center,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer),
                  child: Text("资源目录: ${_project.resDirs.length}")),
              Expanded(
                  child: ListView.builder(
                      itemCount: _project.resDirs.length,
                      itemBuilder: (context, index) {
                        if (index < _project.resDirs.length) {
                          final children = <Widget>[];
                          children.add(ListTile(
                              title: Text(_project.resDirs[index]),
                              selected: index == selectedResDirIndex,
                              onTap: () {
                                if (selectedResDirIndex != index) {
                                  setState(() {
                                    _currentResInfo
                                        .load(_project.getResDirPath(index));
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
              Container(
                  alignment: Alignment.center,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer),
                  child: Text(
                      "资源文件: ${selectedResDirIndex >= 0 ? _project.resDirs.elementAtOrNull(selectedResDirIndex) ?? "" : ""}")),
              Expanded(
                  child: ListView.builder(
                      itemCount: _currentResInfo.xmlFileNames.length,
                      itemBuilder: (context, index) {
                        if (index < _currentResInfo.xmlFileNames.length) {
                          final children = <Widget>[];
                          children.add(ListTile(
                              title: Text(_currentResInfo.xmlFileNames
                                  .elementAt(index)),
                              selected: index == selectedXmlFileIndex,
                              onTap: () {
                                selectedXmlFileIndex = index;
                                final xmlFileName = _currentResInfo.xmlFileNames
                                    .elementAt(index);
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
        right: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  height: 40,
                  child: Row(children: [
                    TextButton.icon(
                        icon: const Icon(Icons.language),
                        label: const Text("一键翻译"),
                        onPressed: () {}),
                    TextButton.icon(
                        icon: const Icon(Icons.language),
                        label: const Text("翻译阿拉伯语"),
                        onPressed: () {
                          transOneLanguage(Language.ar);
                        }),
                    TextButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("保存结果(不可恢复,请提前备份)"),
                        onPressed: () {
                          saveResult();
                        }),
                  ])),
              Expanded(
                  child: Scrollbar(
                      controller: tableVController,
                      child: Scrollbar(
                          controller: tableHController,
                          notificationPredicate: (notify) => notify.depth == 1,
                          child: SingleChildScrollView(
                              controller: tableVController,
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                  controller: tableHController,
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    columnSpacing: 20,
                                    headingRowColor:
                                        MaterialStateColor.resolveWith(
                                            (states) => Theme.of(context)
                                                .colorScheme
                                                .primaryContainer),
                                    headingTextStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                    showBottomBorder: true,
                                    columns: dataColumns(),
                                    rows: dataRows(),
                                  ))))))
            ],
          ),
        ),
        bottom: Container(
            height: 30,
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Text(
                  "状态栏: resDir=$selectedResDirIndex, xmlFile=$selectedXmlFileIndex, xmlName=${_xmlData.fileName}"),
            ])),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          testTrans();
        },
        tooltip: 'Test',
        child: const Icon(Icons.add),
      ),
    );
  }

  void testTrans() {
    final request = TransRequest(Language.cnHk, [
      "Car Language",
      "Auto Start-Stop",
      "Calibration",
      "TPMS Calibration State",
      "TPMS Detection State",
      "Cleaning fluid"
    ], [
      "Car Language",
      "Auto Start-Stop",
      "Calibration",
      "TPMS Calibration State",
      "TPMS Detection State",
      "Cleaning fluid"
    ]);
    _openAI.transTexts(request).listen((event) {
      log("${event ?? "null"}");
    });
  }

  List<(String, String)> collectNeedTransStringsForLang(Language lang) {
    final needList = <(String, String)>[];
    for (var it in _xmlData.items) {
      if (it.translatable) {
        final v = it.valueMap[lang];
        if (v == null || v.isEmpty) {
          final defVal = it.valueMap[Language.def];
          if (defVal != null) {
            needList.add((it.name, defVal));
          }
        }
      }
    }
    return needList;
  }

  void transOneLanguage(Language lang) async {
    final needList = collectNeedTransStringsForLang(lang);
    log("needList=$needList");
    if (needList.isEmpty) {
      log("needList is empty");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("没有需要翻译的内容!")));
      return;
    }
    final req = TransRequest(lang, needList.map((e) => e.$1).toList(),
        needList.map((e) => e.$2).toList());
    _openAI.transTexts(req).listen((event) {
      log("onResponse: $event");
      if (event != null && event.strings.isNotEmpty) {
        for (var (idx, it) in event.strings.indexed) {
          final key = event.keys[idx];
          final transItem = _xmlData.getOrCreateTranslatedItem(key);
          transItem.valueMap[lang] = it;
        }
        setState(() {});
      }
    });
  }

  void saveResult() {
    if (!_xmlData.hasTranslatedData()) {
      log("saveResult is empty");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("无已翻译的内容, 无需保存!")));
      return;
    }

    _xmlData.saveToDir(_currentResInfo.dir);
  }
}
