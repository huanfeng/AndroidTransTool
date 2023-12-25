import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';

// 左边是一个列表，右边是Page的布局
class SimplePanelLayout extends StatefulWidget {
  const SimplePanelLayout(
      {super.key,
      required this.left,
      required this.right,
      this.top,
      this.statusBar,
      this.bottom});

  final Widget left;
  final Widget right;

  // 用于上栏
  final Widget? top;

  // 用于状态栏
  final Widget? statusBar;

  // 用于日志框
  final Widget? bottom;

  @override
  State<SimplePanelLayout> createState() => _SimplePanelLayoutState();
}

class _SimplePanelLayoutState extends State<SimplePanelLayout> {
  static const minLeftFlex = 0.1;
  static const maxLeftFlex = 0.9;
  static const debounceTime = 1000;

  double leftFlex = Config.leftPanelFlex.value;

  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double leftWidth = screenWidth * leftFlex;

    return Column(children: [
      if (widget.top != null) widget.top!,
      Expanded(
          child: Row(
        children: [
          Container(width: leftWidth, child: widget.left),
          MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    // 当用户拖动时，更新leftWidth值
                    setState(() {
                      // 更新leftFlex值，确保它在0到1之间
                      leftFlex += details.primaryDelta! / screenWidth;
                      leftFlex = leftFlex.clamp(minLeftFlex, maxLeftFlex);
                    });
                    _updateConfigFileDebounced();
                  },
                  child: const VerticalDivider(
                    width: 4,
                    thickness: 2,
                  ))),
          Expanded(flex: 1, child: widget.right)
        ],
      )),
      if (widget.bottom != null) widget.bottom!,
      if (widget.statusBar != null) widget.statusBar!,
    ]);
  }

  void _updateConfigFileDebounced() {
    // 取消之前的timer
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // 启动新的timer，等待300毫秒
    _debounce = Timer(const Duration(milliseconds: debounceTime), () {
      Config.leftPanelFlex.value = leftFlex;
    });
  }
}
