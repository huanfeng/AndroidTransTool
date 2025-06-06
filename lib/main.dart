import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'global.dart';
import 'pages/home.dart';
import 'pages/project_setting.dart';
import 'utils/touch_utils.dart';

const appName = "Android Trans Tool";
String appTitle = appName;

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

// 初始化应用版本
Future<void> initAppVersion() async {
  try {
    // 读取应用信息
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    // 更新应用标题
    appTitle = "$appName v$version";
  } catch (e) {
    // 使用默认标题
    appTitle = "$appName v1.0.0";
  }
}

Future<void> main() async {
  // 必须最早初始化, 不然可能会出现依赖问题
  await Config.init();

  // 初始化版本信息
  await initAppVersion();

  log.d("main: logPath=$logPath");
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
          thickness: WidgetStateProperty.all(16),
          thumbVisibility: WidgetStateProperty.all<bool>(true),
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
        "/": (context) => MyHomePage(title: appTitle), //注册首页路由
        "project_setting": (context) => const ProjectSettingPage(),
      },
    );
  }
}
