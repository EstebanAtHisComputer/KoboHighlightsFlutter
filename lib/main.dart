import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'package:kobo_highlights/pages/intro_page.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await WindowManagerPlus.ensureInitialized(0);
    WindowOptions windowOptions = const WindowOptions(
      size: Size(855, 861),
      center: true,
      title: "Kobo Highlights",
      titleBarStyle: TitleBarStyle.normal,
      skipTaskbar: false,
    );
    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      await WindowManagerPlus.current.show();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kobo Highlights',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      home: const IntroPage(),
    );
  }
}
