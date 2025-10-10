import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _copyToClipboard(BuildContext context, String text) {
    String res = "$text ($selectedTitle)";
    Clipboard.setData(ClipboardData(text: res));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Copied to clipboard!")));
  }

  void _exportHighlight(BuildContext context, String text) async {
    final String fileName = "$selectedTitle.txt";
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        XTypeGroup(label: "Text file", extensions: [".txt"]),
      ],
    );
    if (result == null) {
      return;
    }

    final Uint8List fileData = Uint8List.fromList(text.codeUnits);
    const String mimeType = 'text/plain';
    final XFile textFile = XFile.fromData(
      fileData,
      mimeType: mimeType,
      name: fileName,
    );
    await textFile.saveTo(result.path);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Highlight exported!")));
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
        actions: [
          Tooltip(
            message: "More...",
            waitDuration: Duration(seconds: 1),
            child: MenuAnchor(
              menuChildren: [
                selectedIndex > 0
                    ? MenuItemButton(
                        child: Text("Previous book"),
                        onPressed: () {
                          selectedIndex--;
                          setState(() {
                            _changeSelected(selectedIndex);
                          });
                        },
                      )
                    : SizedBox.shrink(),
                selectedIndex < highlights.keys.length - 1
                    ? MenuItemButton(
                        child: Text("Next book"),
                        onPressed: () {
                          setState(() {
                            selectedIndex++;
                            _changeSelected(selectedIndex);
                          });
                        },
                      )
                    : SizedBox.shrink(),
                MenuItemButton(
                  child: Text("Export all"),
                  onPressed: () {
                    print("Not implemented yet");
                  },
                ),
              ],
              builder: (context, controller, child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: const Icon(Icons.more_horiz),
                );
              },
            ),
          ),
        ],
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
                title: SelectableText(selectedHighlights[index].text),
                shape: BeveledRectangleBorder(
                  side: BorderSide(color: Theme.of(context).primaryColorLight),
                  borderRadius: BorderRadiusGeometry.circular(15.0),
                ),
                trailing: Tooltip(
                  message: "View options",
                  waitDuration: Duration(seconds: 1),
                  child: MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        child: Text("Copy to clipboard"),
                        onPressed: () {
                          _copyToClipboard(
                            context,
                            selectedHighlights[index].text,
                          );
                        },
                      ),
                      MenuItemButton(
                        child: Text("Export"),
                        onPressed: () {
                          _exportHighlight(
                            context,
                            selectedHighlights[index].text,
                          );
                        },
                      ),
                    ],
                    builder: (context, controller, child) {
                      return IconButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        icon: const Icon(Icons.more_horiz),
                      );
                    },
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
                isThreeLine: true,
                subtitle: Text(
                  "${highlights.keys.elementAt(index).$2}\n${highlights.values.elementAt(index).length} highlight(s)",
                ),
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
