import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:kobo_highlights/db.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

void jumpToMain() {}

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
              onPressed: () async {
                XFile? file = await openFile();
                if (file != null) {
                  await tryDB(file.path);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                }
              },
              style: ButtonStyle(
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic),
              ),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> entries = <String>['a', 'b', 'c'];
  int selectedIndex = -1;
  List<Highlight> selectedHighlights = [];
  String selectedTitle = "Kobo Highlights";

  void _onLayoutDone(_) async {
    _scaffoldKey.currentState!.openDrawer();
  }

  void _changeSelected(index) {
    //TODO: Refactor this.
    selectedIndex = index;
    selectedHighlights = highlights.entries.elementAt(index).value;
    selectedTitle =
        "${highlights.keys.elementAt(index).$1} - ${highlights.keys.elementAt(index).$2}";
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_onLayoutDone);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(selectedTitle),
        leading: Tooltip(
          message: "Open book list",
          waitDuration: Duration(seconds: 1),
          child: IconButton(
            style: ButtonStyle(
              mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic),
            ),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            icon: const Icon(Icons.menu_book),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: ListView.separated(
            itemCount: selectedHighlights.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 20.0);
            },
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(selectedHighlights[index].text),
                shape: BeveledRectangleBorder(
                  side: BorderSide(color: Theme.of(context).primaryColorLight),
                  borderRadius: BorderRadiusGeometry.circular(15.0),
                ),
                trailing: Tooltip(
                  message: "View options",
                  waitDuration: Duration(seconds: 1),
                  child: IconButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      mouseCursor: WidgetStatePropertyAll(
                        SystemMouseCursors.basic,
                      ),
                    ),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: Center(
          child: ListView.separated(
            itemCount: highlights.length,
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(highlights.keys.elementAt(index).$1.toString()),
                subtitle: Text(highlights.keys.elementAt(index).$2.toString()),
                mouseCursor: SystemMouseCursors.basic,
                onTap: () {
                  setState(() {
                    _changeSelected(index);
                  });
                  _scaffoldKey.currentState!.closeDrawer();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
