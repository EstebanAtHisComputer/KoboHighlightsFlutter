import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManagerPlus.ensureInitialized(0);
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    title: "Kobo Highlights",
    titleBarStyle: TitleBarStyle.normal,
    skipTaskbar: false,
  );
  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.show();
  });
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

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Image(image: AssetImage("assets/logo.png")),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              child: const Text("Open"),
            ),
            Padding(padding: EdgeInsetsGeometry.all(4.0)),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: const Text("this is the main page")));
  }
}
