import 'package:flutter/material.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  // 存储日志的List
  List<String> logMessages = [];

  // 控制器用于控制滚动
  final ScrollController _scrollController = ScrollController();

  // 将日志列表转换为一个字符串
  String get logText => logMessages.join('\n');

  void _ensureToEnd() {
    // 确保控件已经构建完成后进行滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void addLogMessage(String message) {
    setState(() {
      // 将新的日志信息添加到列表的开始位置
      logMessages.add(message);
    });

    _ensureToEnd();
  }

  void clearLog() {
    setState(() {
      logMessages.clear();
    });
    _ensureToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(
      children: <Widget>[
        Expanded(
          // 使用SelectableText显示日志信息
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SelectableText(
              logText, // 将日志信息转换成文本
              style: const TextStyle(fontFamily: 'monospace'), // 等宽字体显示日志
            ),
          ),
        ),
        const Divider(height: 4.0),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: <Widget>[
              Expanded(
                // 日志添加按钮
                child: ElevatedButton(
                  onPressed: () {
                    // 示例: 每次点击按钮，添加当前时间戳到日志
                    addLogMessage('${DateTime.now()} 测试日志');
                  },
                  child: const Text('添加日志'),
                ),
              ),
              Expanded(
                // 日志添加按钮
                child: ElevatedButton(
                  onPressed: () {
                    clearLog();
                  },
                  child: const Text('清除日志'),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
