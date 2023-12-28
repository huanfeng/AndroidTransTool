import 'package:flutter/material.dart';

class LogController {
  // 用于控制日志显示的控件
  _LogViewState? _state;

  void _attach(_LogViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void addLog(String message) {
    _state?.addLog(message);
  }

  void addLogs(List<String> messages) {
    _state?.addLogs(messages);
  }

  void clearLog() {
    _state?.clearLog();
  }
}

class LogView extends StatefulWidget {
  final LogController? logController;

  const LogView({super.key, this.logController});

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

  @override
  void initState() {
    super.initState();
    widget.logController?._attach(this);
  }

  @override
  void dispose() {
    widget.logController?._detach();
    super.dispose();
  }

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

  void addLog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // 将新的日志信息添加到列表的开始位置
        logMessages.add(message);
      });
      _ensureToEnd();
    });
  }

  void addLogs(List<String> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // 将新的日志信息添加到列表的开始位置
        logMessages.addAll(messages);
      });
      _ensureToEnd();
    });
  }

  void clearLog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        logMessages.clear();
      });
      _ensureToEnd();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(4.0),
            child: SelectableText(
              logText, // 将日志信息转换成文本
              style: const TextStyle(fontFamily: 'monospace'), // 等宽字体显示日志
            ),
          ),
        ),
        const VerticalDivider(width: 4.0),
        Container(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // 示例: 每次点击按钮，添加当前时间戳到日志
                  addLog('${DateTime.now()} 测试日志');
                },
                onLongPress: () {
                  addLog(
                      '这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果，这是一条长日志，用于测试日志显示的滚动效果');
                },
                child: const Text('添加日志'),
              ),
              const SizedBox(height: 4.0),
              ElevatedButton(
                onPressed: () {
                  clearLog();
                },
                child: const Text('清除日志'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
