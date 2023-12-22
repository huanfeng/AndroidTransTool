import 'package:android_trans_tool/main.dart';
import 'package:flutter/material.dart';

class MenuState {
  bool enabled = true;
}

enum MenuEntry {
  file('文件', isDir: true),
  help('帮助', isDir: true, icon: Icons.help),
  about('关于', icon: Icons.info),
  openFolder('打开项目', icon: Icons.file_open),
  settings('设置', icon: Icons.settings_applications),
  ;

  final String label;
  final bool isDir;
  final IconData? icon;

  const MenuEntry(this.label, {this.isDir = false, this.icon});
}

class MainMenu extends StatefulWidget {
  Function(MenuEntry)? onMenuPressed;

  MainMenu({super.key, this.onMenuPressed});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final MenuController _menuController = MenuController();

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: appName,
      applicationVersion: appVersion,
    );
  }

  void _onPressed(MenuEntry selection) {
    // setState(() {});
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
      onPressed: () => _onPressed(entry),
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
      _buildItem(MenuEntry.file),
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
}
