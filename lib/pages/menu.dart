import 'dart:collection';

import 'package:android_trans_tool/main.dart';
import 'package:flutter/material.dart';

enum MenuEntry {
  auto('自动化', isDir: true, icon: Icons.auto_awesome),
  help('帮助', isDir: true, icon: Icons.help),
  about('关于', icon: Icons.info),
  openFolder('打开项目', icon: Icons.file_open),
  settings('设置', icon: Icons.settings_applications),
  autoRes('自动翻译资源...', icon: Icons.list_alt),
  autoProject('自动翻译项目...', icon: Icons.folder_copy),
  ;

  final String label;
  final bool isDir;
  final IconData? icon;

  const MenuEntry(this.label, {this.isDir = false, this.icon});
}

class MenuEnabledController {
  final Set<MenuEntry> _disableSet = HashSet();

  _MainMenuState? _state;

  void _attach(_MainMenuState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void enable(MenuEntry entry) {
    _disableSet.remove(entry);
    _state?.update();
  }

  void disable(MenuEntry entry) {
    _disableSet.add(entry);
    _state?.update();
  }

  void toggle(MenuEntry entry) {
    if (isDisable(entry)) {
      enable(entry);
    } else {
      disable(entry);
    }
  }

  bool isDisable(MenuEntry entry) {
    return _disableSet.contains(entry);
  }
}

class MainMenu extends StatefulWidget {
  Function(MenuEntry)? onMenuPressed;
  MenuEnabledController enabledController;

  MainMenu(
      {super.key, this.onMenuPressed, MenuEnabledController? enabledController})
      : enabledController = enabledController ?? MenuEnabledController();

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final MenuController _menuController = MenuController();

  _MainMenuState() {}

  @override
  void initState() {
    super.initState();
    widget.enabledController._attach(this);
  }

  @override
  void dispose() {
    widget.enabledController._detach();
    super.dispose();
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: appName,
      applicationVersion: appVersion,
    );
  }

  void _onPressed(MenuEntry selection) {
    if (selection == MenuEntry.about) {
      _showAbout();
    } else {
      widget.onMenuPressed?.call(selection);
    }
  }

  Widget _buildItem(MenuEntry entry) {
    if (entry.isDir) return _buildSubmenu(entry, []);
    return MenuItemButton(
      leadingIcon: entry.icon != null ? Icon(entry.icon) : null,
      onPressed: widget.enabledController.isDisable(entry)
          ? null
          : () => _onPressed(entry),
      child: Text(entry.label),
    );
  }

  SubmenuButton _buildSubmenu(MenuEntry entry, List<MenuEntry> list) {
    return SubmenuButton(
      menuChildren: list.map((e) => _buildItem(e)).toList(),
      leadingIcon: entry.icon != null ? Icon(entry.icon) : null,
      child: Text(entry.label),
    );
  }

  List<Widget> buildMenuList() {
    return <Widget>[
      _buildItem(MenuEntry.openFolder),
      _buildSubmenu(MenuEntry.auto, [MenuEntry.autoRes, MenuEntry.autoProject]),
      _buildItem(MenuEntry.settings),
      _buildSubmenu(MenuEntry.help, [MenuEntry.about]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      style: MenuStyle(
        backgroundColor: MaterialStateColor.resolveWith(
            (states) => Theme.of(context).colorScheme.background),
      ),
      controller: _menuController,
      children: buildMenuList(),
    );
  }

  void update() {
    setState(() {});
  }
}
