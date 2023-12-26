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
  static const minBottomFlex = 0.1;
  static const maxBottomFlex = 0.5;
  static const debounceTime = 1000;

  double leftFlex = Config.leftPanelFlex.value;
  double bottomFlex = Config.bottomPanelFlex.value;

  Timer? _debounce;

  // 用于优化拖放逻辑
  double leftDragStartValue = 0;
  double leftDragStartOffset = 0;
  double bottomDragStartValue = 0;
  double bottomDragStartOffset = 0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double leftWidth = screenSize.width * leftFlex;
    final bottomHeight = screenSize.height * bottomFlex;

    return Column(children: [
      if (widget.top != null) widget.top!,
      Expanded(
          child: Row(
        children: [
          SizedBox(width: leftWidth, child: widget.left),
          MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (DragStartDetails details) {
                    // 当用户开始拖动时，计算leftWidth值
                    leftDragStartValue = leftFlex;
                    leftDragStartOffset = details.globalPosition.dx;
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    // 当用户拖动时，更新leftWidth值
                    setState(() {
                      // 更新leftFlex值，确保它在0到1之间
                      final offsetValue =
                          details.globalPosition.dx - leftDragStartOffset;
                      leftFlex =
                          leftDragStartValue + offsetValue / screenSize.width;
                      leftFlex = leftFlex.clamp(minLeftFlex, maxLeftFlex);
                    });
                  },
                  onHorizontalDragEnd: (DragEndDetails details) {
                    _updateConfigFileDebounced();
                  },
                  child: const VerticalDivider(
                    width: 4,
                    thickness: 2,
                  ))),
          Expanded(flex: 1, child: widget.right)
        ],
      )),
      if (widget.bottom != null)
        MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (DragStartDetails details) {
                  // 当用户开始拖动时，计算leftWidth值
                  bottomDragStartValue = bottomFlex;
                  bottomDragStartOffset = details.globalPosition.dy;
                },
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  // 当用户拖动时，更新leftWidth值
                  setState(() {
                    // 更新leftFlex值，确保它在0到1之间
                    final offsetValue =
                        bottomDragStartOffset - details.globalPosition.dy;
                    bottomFlex =
                        bottomDragStartValue + offsetValue / screenSize.height;
                    bottomFlex = bottomFlex.clamp(minBottomFlex, maxBottomFlex);
                  });
                },
                onVerticalDragEnd: (DragEndDetails details) {
                  _updateConfigFileDebounced();
                },
                child: const Divider(
                  height: 4,
                  thickness: 2,
                ))),
      if (widget.bottom != null)
        SizedBox(height: bottomHeight, child: widget.bottom!),
      if (widget.statusBar != null) widget.statusBar!,
    ]);
  }

  void _updateConfigFileDebounced() {
    // 取消之前的timer
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // 启动新的timer，等待
    _debounce = Timer(const Duration(milliseconds: debounceTime), () {
      Config.leftPanelFlex.value = leftFlex;
      Config.bottomPanelFlex.value = bottomFlex;
    });
  }
}
