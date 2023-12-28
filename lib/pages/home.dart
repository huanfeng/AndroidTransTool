import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/language.dart';
import '../data/project.dart';
import '../data/xml_data.dart';
import '../global.dart';
import '../trans/openai.dart';
import '../trans/trans_data.dart';
import '../utils/picker_utils.dart';
import '../widgets/logview.dart';
import '../widgets/panel_layout.dart';
import 'auto_trans_dialog.dart';
import 'menu.dart';
import 'project_setting.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TranslateProgress {
  var working = false;
  Language currentLang = Language.def;
  var langIndex = 0;
  var langCount = 0;
  var textTotalCount = 0;
  var textTranslatedCount = 0;

  void reset() {
    working = false;
    langCount = 0;
    langIndex = 0;
    textTotalCount = 0;
    textTranslatedCount = 0;
  }

  void setLangProgress(Language lang, int index, int count) {
    currentLang = lang;
    langIndex = index;
    langCount = count;
    textTotalCount = 0;
    textTranslatedCount = 0;
  }

  void setTextProgress(int translated, int total) {
    textTranslatedCount = translated;
    textTotalCount = total;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedResDirIndex = -1;
  int selectedXmlFileIndex = -1;
  int selectedXmlLine = -1;
  bool _showLogView = Config.showLogView.value;

  set showLogView(bool value) {
    _showLogView = value;
    Config.showLogView.value = value;
  } // _showLogView 的 setting

  final Project _project = Project("New Project");
  final ResDirInfo _currentResInfo = ResDirInfo();
  final XmlData _xmlData = XmlData();
  final Set<Language> _selectedLangs = {};

  final _openAI = OpenAiTrans();

  final TranslateProgress _progress = TranslateProgress();
  final ScrollController tableVController = ScrollController();
  final ScrollController tableHController = ScrollController();

  final MenuEnabledController _menuEnabledController = MenuEnabledController();

  final LogController _logController = LogController();

  @override
  void initState() {
    super.initState();
    Logger.addOutputListener(onLog);
  }

  @override
  void dispose() {
    super.dispose();
    Logger.removeOutputListener(onLog);
  }

  void onMenuPressed(MenuEntry entry) {
    switch (entry) {
      case MenuEntry.openFolder:
        onOpenProject();
        break;
      case MenuEntry.settings:
        Navigator.pushNamed(context, 'setting');
        break;
      case MenuEntry.autoProject:
        _menuEnabledController.toggle(MenuEntry.autoRes);
        break;
      case MenuEntry.autoRes:
        _menuEnabledController.toggle(MenuEntry.autoProject);
        break;
      case MenuEntry.debugTran:
        chatCompleteTest(Config.apiUrl.value, Config.apiToken.value);
        break;
      default:
        break;
    }
  }

  void onLog(OutputEvent event) {
    if (event.level.value >= Level.info.value) {
      _logController.addLogs(event.lines);
    }
  }

  List<DataColumn> dataColumns() {
    final list = <DataColumn>[
      const DataColumn(label: Text('序号'), numeric: true),
      const DataColumn(label: Text('ID')),
      const DataColumn(label: Text('可翻译')),
    ];

    for (var lang in Language.supportedLanguages) {
      list.add(DataColumn(
          label: Row(children: [
        Text(lang.cnTitle),
        lang == Language.def
            ? const SizedBox()
            : Checkbox(
                value: _selectedLangs.contains(lang),
                onChanged: (check) {
                  if (check == true) {
                    _selectedLangs.add(lang);
                  } else {
                    _selectedLangs.remove(lang);
                  }
                  setState(() {});
                },
              )
      ])));
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
      for (var lang in Language.supportedLanguages) {
        final v = it.valueMap[lang]?.toString() ?? "";
        final transV =
            transIt != null ? transIt.valueMap[lang]?.toString() : null;
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
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(fit: StackFit.expand, children: [
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MainMenu(
                          onMenuPressed: onMenuPressed,
                          enabledController: _menuEnabledController)
                    ],
                  ))
            ]);
          })),
      body: mainLayout(),
    );
  }

  Widget mainLayout() {
    final projectDirEmpty = _project.projectDir.isEmpty;
    return SimplePanelLayout(
        left: Container(
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(80)),
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "项目路径: ",
                          style: TextStyle(fontSize: 16),
                        ),
                        Tooltip(
                            waitDuration: const Duration(milliseconds: 500),
                            message: "左键打开, 右键复制",
                            child: InkWell(
                              onTap: projectDirEmpty
                                  ? null
                                  : () {
                                      if (Platform.isWindows) {
                                        final url = Uri.parse(
                                            'file:///${_project.projectDir}');
                                        launchUrl(url);
                                      }
                                    },
                              onSecondaryTap: projectDirEmpty
                                  ? null
                                  : () {
                                      // 创建一个包含要复制的数据的 ClipboardData 对象
                                      ClipboardData data = ClipboardData(
                                          text: _project.projectDir);
                                      // 将数据复制到剪切板
                                      Clipboard.setData(data);
                                      showMessage(
                                          "已复制 ${_project.projectDir} 到剪切板!");
                                    },
                              child: Text(_project.projectDir,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromRGBO(0, 0, 255, 1),
                                  )),
                            )),
                      ],
                    )),
                // const Divider(),
                Container(
                    alignment: Alignment.center,
                    height: 30,
                    decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.secondaryContainer),
                    child: Text(
                        "资源目录: ${_project.resDirs.length}  当前选择: ${selectedResDirIndex < 0 ? "-" : selectedResDirIndex + 1}")),
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
                                  onTapResDir(index);
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
                        color:
                            Theme.of(context).colorScheme.secondaryContainer),
                    child: Text(
                        "资源文件: ${_currentResInfo.xmlFileNames.length} 当前选择: ${selectedXmlFileIndex < 0 ? "-" : selectedXmlFileIndex + 1}")),
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
                                  onTapXmlFile(index);
                                }));
                            if (index <
                                _currentResInfo.xmlFileNames.length - 1) {
                              children.add(const Divider());
                            }
                            return Column(
                              children: children,
                            );
                          }
                          return null;
                        })),
              ],
            )),
        right: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Wrap(children: [
                  // MenuAnchor(
                  //     menuChildren: <Widget>[
                  //       MenuItemButton(
                  //         child: const Text("自动翻译当前资源"),
                  //         onPressed: () => {},
                  //       ),
                  //       MenuItemButton(
                  //         onPressed: () => {},
                  //         child: const Text("自动翻译当前资源并保存"),
                  //       ),
                  //     ],
                  //     builder: (BuildContext context, MenuController controller,
                  //         Widget? child) {
                  //       return TextButton.icon(
                  //         onPressed: () {
                  //           if (controller.isOpen) {
                  //             controller.close();
                  //           } else {
                  //             controller.open();
                  //           }
                  //         },
                  //         label: const Text("一键翻译"),
                  //         icon: const Icon(Icons.language),
                  //       );
                  //     }),
                  TextButton.icon(
                      icon: const Icon(Icons.language),
                      label: const Text("一键翻译"),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black26,
                          builder: (BuildContext context) {
                            return AutoTransDialog(doAutoTransXml);
                          },
                        );
                      }),
                  TextButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: const Text("选中"),
                      onPressed: () {
                        onSelectCanTranslateLanguage();
                      }),
                  TextButton.icon(
                      icon: const Icon(Icons.language),
                      label: const Text("翻译选中语言"),
                      onPressed: () {
                        onTransSelectLanguage();
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
                                      MaterialStateColor.resolveWith((states) =>
                                          Theme.of(context)
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
        bottom: _showLogView ? LogView(logController: _logController) : null,
        statusBar: Container(
            height: 30,
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              const Expanded(child: Text("状态栏")),
              const VerticalDivider(),
              const Expanded(child: Text("状态栏")),
              const Spacer(),
              const VerticalDivider(),
              Expanded(
                  child: Row(children: [
                const Text("日志窗口"),
                Checkbox(
                    value: _showLogView,
                    semanticLabel: "显示日志窗口",
                    onChanged: (v) {
                      setState(() {
                        if (v != null) {
                          showLogView = v;
                        }
                      });
                    })
              ])),
            ])));
  }

  void onOpenProject() {
    openDirectoryPacker(
        title: "请选择安卓工程目录",
        cb: (dir) {
          _project.loadFrom(dir);
          _currentResInfo.reset();
          _xmlData.clear();
          log.i(
              "打开项目 [${_project.projectDir}] 找到 [${_project.resDirs.length}] 个资源目录");
          selectedResDirIndex = -1;
          selectedXmlFileIndex = -1;
          setState(() {});
        });
  }

  void onTapResDir(int index) {
    if (selectedResDirIndex != index) {
      setState(() {
        _currentResInfo.load(_project.projectDir, _project.getResDir(index));
        log.i(
            "打开目录 [${_currentResInfo.dir}] 找到 [${_currentResInfo.xmlFileNames.length}] 个资源文件");
        selectedResDirIndex = index;
        selectedXmlFileIndex = -1;
      });
    }
  }

  void onTapXmlFile(int index) {
    setState(() {
      selectedXmlFileIndex = index;
      _selectedLangs.clear();
      final xmlFileName = _currentResInfo.xmlFileNames.elementAt(index);
      log.d("onTapXmlFile: index=$index, name=$xmlFileName");
      _xmlData.setFileName(xmlFileName);
      _xmlData.load(_currentResInfo.dirPath);
      log.i("打开文件 [$xmlFileName] 共 [${_xmlData.items.length}] 个条目");
    });
  }

  List<TransItem> collectNeedTransItemForLang(Language lang) {
    final needList = <TransItem>[];
    for (var it in _xmlData.items) {
      if (it.translatable) {
        final v = it.getLangItem(lang);
        if (v == null || v.isEmpty) {
          final defVal = it.getLangItem(Language.def);
          if (defVal != null) {
            needList.add(TransItem(it.name, defVal));
          }
        }
      }
    }
    return needList;
  }

  bool isLanguageNeedTrans(Language lang) {
    for (var it in _xmlData.items) {
      if (it.translatable) {
        final v = it.valueMap[lang];
        if (v == null || v.isEmpty) {
          final defVal = it.valueMap[Language.def];
          if (defVal != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> transOneLanguage(Language lang, {bool byUi = false}) async {
    final needList = collectNeedTransItemForLang(lang);
    // log.d("needList=$needList");
    logProgress((progress) => progress.setTextProgress(0, needList.length));
    if (needList.isEmpty) {
      log.d("[${lang.cnName}] needList is empty");
      if (byUi) {
        showMessage("[${lang.cnName}] 没有需要翻译的内容!");
      }
      return;
    }
    final req = TransRequest(lang, needList);
    _openAI.setConfig(Config.apiUrl.value, Config.apiToken.value,
        httpProxy: Config.httpProxy.value);

    var translateCount = 0;
    await _openAI.startTransRequest(req, (event) {
      log.d("onResponse: $event");
      if (event != null) {
        for (var it in event.items) {
          final transItem = _xmlData.getOrCreateTranslatedItem(it);
          if (it.dstValue != null) {
            transItem.valueMap[lang] = it.dstValue;
          }
        }
        translateCount += event.items.length;
        logProgress((progress) =>
            progress.setTextProgress(translateCount, needList.length));
        setState(() {});
      }
    });
  }

  void saveResult() {
    if (!_xmlData.hasTranslatedData()) {
      log.d("saveResult is empty");
      showMessage("无已翻译的内容, 无需保存!");
      return;
    }

    final langList = _xmlData.getTranslatedLanguages();
    for (final i in langList) {
      _xmlData.saveToDir(_currentResInfo.dirPath, i);
    }
    log.i("已保存 ${langList.length} 种语言的翻译结果!");
    _xmlData.load(_currentResInfo.dirPath);
    setState(() {});
  }

  void onTransSelectLanguage() async {
    if (Config.apiToken.value.isEmpty) {
      showMessage("请先配置API Token!");
      return;
    }
    if (_selectedLangs.isEmpty) {
      showMessage("无选中的语言!");
      return;
    }

    final list = _selectedLangs.toList();
    doTranslate(list);
  }

  Future<void> doTranslate(List<Language> langList) async {
    langList.sort((a, b) => a.index.compareTo(b.index));
    for (final lang in langList) {
      logProgress((progress) => progress.setLangProgress(
          lang, langList.indexOf(lang), langList.length));
      await transOneLanguage(lang, byUi: true);
    }
    log.i("翻译结束!");
  }

  void showMessage(String msg) {
    log.i(msg);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Language> getCanTranslateLanguages() {
    final list = <Language>[];
    for (final i in Language.supportedLanguages) {
      if (isLanguageNeedTrans(i)) {
        list.add(i);
      }
    }
    return list;
  }

  // 选择可翻译的语言
  void onSelectCanTranslateLanguage() async {
    final canTransList = getCanTranslateLanguages();
    _selectedLangs.clear();
    _selectedLangs.addAll(canTransList);
    showMessage("已选中${canTransList.length}种可翻译的语言!");
    setState(() {});
  }

  void logProgress(Function(TranslateProgress) update) {
    update(_progress);
    if (_progress.textTotalCount == 0) {
      log.i(
          "语言进度: ${_progress.langIndex + 1}/${_progress.langCount}, 当前语言: ${_progress.currentLang.cnName}");
    } else {
      log.i(
          "语言进度: ${_progress.langIndex + 1}/${_progress.langCount}, 当前语言: ${_progress.currentLang.cnName}, 文本进度: ${_progress.textTranslatedCount}/${_progress.textTotalCount}");
    }
  }

  void doAutoTransXml(AutoTransConfig config) async {
    final autoSelect = config.autoSelect;
    final autoSave = config.autoSave;
    final langList =
        autoSelect ? getCanTranslateLanguages() : _selectedLangs.toList();
    if (langList.isEmpty) {
      showMessage("没有可翻译的语言!");
      return;
    }
    await doTranslate(langList);
    if (autoSave) {
      saveResult();
    }
  }
}
