import 'package:flutter/cupertino.dart';

// 左边是一个列表，右边是Page的布局
class SimplePanelLayout extends StatefulWidget {
  const SimplePanelLayout(
      {super.key,
      required this.left,
      required this.right,
      this.top,
      this.bottom});

  final Widget left;
  final Widget right;

  // 用于上栏
  final Widget? top;

  // 用于状态栏
  final Widget? bottom;

  @override
  State<SimplePanelLayout> createState() => _SimplePanelLayoutState();
}

class _SimplePanelLayoutState extends State<SimplePanelLayout> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (widget.top != null) widget.top!,
      Expanded(
          child: Row(
        children: [
          Expanded(flex: 1, child: widget.left),
          Expanded(flex: 3, child: widget.right)
        ],
      )),
      if (widget.bottom != null) widget.bottom!,
    ]);
  }
}
