import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'global.dart';
import 'pages/home.dart';
import 'pages/project_setting.dart';
import 'pages/settings.dart';
import 'utils/touch_utils.dart';

const appVersion = "V0.1";
const appName = "Android Trans Tool";
const appTitle = "$appName $appVersion";

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

Future<void> main() async {
  log.d("main: logPath=$logPath");

  await Config.init();
  Config.loadConfig();

  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setMinimumSize(const Size(400, 400));
      await windowManager.setTitle(appTitle);
      await windowManager.show();
      // await windowManager.setPreventClose(true);
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme() {
    final data = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // 修改拖动条加宽, 常显示
        scrollbarTheme: ScrollbarThemeData(
          thickness: MaterialStateProperty.all(16),
          thumbVisibility: MaterialStateProperty.all<bool>(true),
        ));
    if (kIsWeb) {
      return data;
    } else {
      return data.useSystemChineseFont(Brightness.light);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'US'), // 美国英语
        Locale('zh', 'CN'), // 中文简体
        //其他Locales
      ],
      scrollBehavior: MyCustomScrollBehavior(),
      title: appTitle,
      initialRoute: "/",
      theme: _buildTheme(),
      routes: {
        "/": (context) => const MyHomePage(title: appTitle), //注册首页路由
        "setting": (context) => const SettingPage(),
        "project_setting": (context) => const ProjectSettingPage(),
      },
    );
  }
}
