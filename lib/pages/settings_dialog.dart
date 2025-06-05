import 'package:flutter/material.dart';

import '../config.dart';
import '../data/language.dart';
import '../trans/openai.dart';

// 设置分类
enum SettingsCategory {
  api("API设置", Icons.api),
  languages("翻译语言", Icons.language);

  final String title;
  final IconData icon;
  
  const SettingsCategory(this.title, this.icon);
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  // 当前选中的设置分类
  SettingsCategory _selectedCategory = SettingsCategory.api;
  
  // API测试状态和结果
  bool _isTestingApi = false;
  TestResult? _apiTestResult;


  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("设置", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  // 左侧分类导航
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: ListView(
                      children: [
                        for (final category in SettingsCategory.values)
                          ListTile(
                            leading: Icon(category.icon),
                            title: Text(category.title),
                            selected: _selectedCategory == category,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  // 右侧设置内容
                  Expanded(
                    child: _buildSettingsContent(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("关闭"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 根据所选分类构建对应设置内容
  Widget _buildSettingsContent() {
    switch (_selectedCategory) {
      case SettingsCategory.api:
        return _buildApiSettings();
      case SettingsCategory.languages:
        return _buildLanguageSettings();
    }
  }

  // API设置内容
  Widget _buildApiSettings() {
    final apiUrl = TextEditingController(text: Config.apiUrl.value);
    final apiToken = TextEditingController(text: Config.apiToken.value);
    final httpProxy = TextEditingController(text: Config.httpProxy.value);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView(
        children: [
          const ListTile(
            title: Text("API设置", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("配置翻译API的相关参数"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                    flex: 1,
                    child: ListTile(title: Text("API URL:")),
                  ),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: apiUrl,
                      decoration: InputDecoration(
                          hintText: 'https://api.openai.com/v1/',
                          hintStyle:
                              TextStyle(color: Colors.grey.withAlpha(80))),
                      onChanged: (value) {
                        Config.apiUrl.value = value;
                      },
                    )
                  )
                ]),
              ]),
            )
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                    flex: 1,
                    child: ListTile(title: Text("API TOKEN:")),
                  ),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: apiToken,
                      onChanged: (value) {
                        Config.apiToken.value = value;
                      },
                    )
                  )
                ]),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                    flex: 1,
                    child: ListTile(title: Text("HTTP 代理:")),
                  ),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: httpProxy,
                      decoration: InputDecoration(
                          hintText: "localhost:7890",
                          hintStyle:
                              TextStyle(color: Colors.grey.withAlpha(80))),
                      onChanged: (value) {
                        Config.httpProxy.value = value;
                      },
                    )
                  )
                ]),
              ]),
            ),
          ),
          // 测试API按钮和结果显示区域
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 测试按钮
              ElevatedButton.icon(
                icon: _isTestingApi ? 
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)) : 
                  const Icon(Icons.translate),
                label: Text(_isTestingApi ? "测试中..." : "测试翻译接口"),
                onPressed: _isTestingApi ? null : () => _testTranslationApi(),
              ),
              
              // 测试结果区域
              if (_apiTestResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color: _apiTestResult!.success ? Colors.green.shade50 : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            Icon(
                              _apiTestResult!.success ? Icons.check_circle : Icons.error_outline,
                              color: _apiTestResult!.success ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _apiTestResult!.success ? "测试成功" : "测试失败",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _apiTestResult!.success ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            if (_apiTestResult!.elapsedMs != null) ...[  
                              const SizedBox(width: 8),
                              Text("(${_apiTestResult!.elapsedMs}ms)", style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Text(_apiTestResult!.message),
                        ),
                        // 如果有内容，显示测试结果
                        if (_apiTestResult!.content != null) ...[  
                          const Divider(),
                          const Text("翻译结果:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            margin: const EdgeInsets.only(top: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            width: double.infinity,
                            child: SelectableText(
                              _apiTestResult!.content!,
                              style: TextStyle(fontFamily: "monospace", fontSize: 14),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
  
  // 语言设置内容
  // 测试翻译API连接
  Future<void> _testTranslationApi() async {
    // 设置测试中状态
    setState(() {
      _isTestingApi = true;
      _apiTestResult = null; // 清空之前的测试结果
    });
    
    try {
      // 执行测试，使用当前设置的API参数
      final result = await chatCompleteTest(
        Config.apiUrl.value, 
        Config.apiToken.value, 
        httpProxy: Config.httpProxy.value
      );
      
      // 更新UI显示测试结果
      setState(() {
        _apiTestResult = result;
        _isTestingApi = false;
      });
    } catch (e) {
      // 处理异常情况
      setState(() {
        _apiTestResult = TestResult(
          success: false, 
          message: "测试过程发生异常: ${e.toString()}"
        );
        _isTestingApi = false;
      });
    }
  }

  Widget _buildLanguageSettings() {
    // 获取当前已启用的语言列表
    final enabledLanguages = Config.enabledLanguages.value;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView(
        children: [
          const ListTile(
            title: Text("翻译语言设置", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("选择需要支持的翻译语言"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("支持的语言", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  // 语言选择列表
                  for (final language in Language.values.where((l) => l != Language.def)) // 排除默认语言
                    CheckboxListTile(
                      title: Text(language.cnName),
                      subtitle: Text("${language.enName} (${language.code})"),
                      value: enabledLanguages.contains(language.code),
                      onChanged: (bool? value) {
                        setState(() {
                          final List<String> newEnabledLanguages = List.from(enabledLanguages);
                          if (value == true) {
                            if (!newEnabledLanguages.contains(language.code)) {
                              newEnabledLanguages.add(language.code);
                            }
                          } else {
                            newEnabledLanguages.remove(language.code);
                          }
                          Config.enabledLanguages.value = newEnabledLanguages;
                        });
                      },
                    ),
                  // 添加关于语言使用的提示信息
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "注意: 更改语言设置后，需要重新打开项目文件夹才会生效。",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示设置对话框
void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const SettingsDialog(),
  );
}
