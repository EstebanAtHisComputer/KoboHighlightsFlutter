import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kobo_highlights/db.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

Future<void> _errorDialog(BuildContext context, String title, String text) {
  return showDialog(
    context: context,
    requestFocus: true,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: Icon(Icons.error),
        title: Text(title),
        content: Text(text),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Ok"),
          ),
        ],
      );
    },
  );
}

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
                  try {
                    await tryDB(file.path);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MainPage(),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _errorDialog(
                        context,
                        "Error loading Database",
                        e.toString(),
                      );
                    }
                  }
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
  final ScrollController controller = ScrollController();

  int selectedIndex = -1;
  List<String> selectedHighlights = [];
  String selectedTitle = "Kobo Highlights";

  void _onLayoutDone(_) async {
    _scaffoldKey.currentState!.openDrawer();
  }

  void _changeSelected(index) {
    selectedIndex = index;
    selectedHighlights = highlights.entries.elementAt(index).value;
    selectedTitle =
        "${highlights.keys.elementAt(index).$1} - ${highlights.keys.elementAt(index).$2}";
    controller.jumpTo(-60);
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

    final Uint8List fileData = utf8.encode(text);

    const String mimeType = 'text/plain';
    final XFile textFile = XFile.fromData(
      fileData,
      mimeType: mimeType,
      name: fileName,
    );
    await textFile.saveTo(result.path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Highlight exported!")));
    }
  }

  void _exportAll(BuildContext context) {
    final String content = selectedHighlights.join("\n\n");
    _exportHighlight(context, content);
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
        toolbarHeight: 72,
        title: Column(
          children: [
            Text(selectedTitle),
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  if (selectedIndex > 0) {
                    selectedIndex--;
                    setState(() {
                      _changeSelected(selectedIndex);
                    });
                  }
                },
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  if (selectedIndex < highlights.keys.length - 1) {
                    selectedIndex++;
                    setState(() {
                      _changeSelected(selectedIndex);
                    });
                  }
                },
              },
              child: Focus(
                autofocus: true,
                descendantsAreFocusable: false,
                descendantsAreTraversable: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    selectedIndex > 0
                        ? Tooltip(
                            message: "Previous book (Left arrow)",
                            waitDuration: Duration(seconds: 1),
                            child: IconButton(
                              style: ButtonStyle(
                                mouseCursor: WidgetStatePropertyAll(
                                  SystemMouseCursors.basic,
                                ),
                              ),
                              onPressed: () {
                                selectedIndex--;
                                setState(() {
                                  _changeSelected(selectedIndex);
                                });
                              },
                              icon: Icon(Icons.arrow_circle_left_outlined),
                            ),
                          )
                        : SizedBox.shrink(),
                    selectedIndex < highlights.keys.length - 1
                        ? Tooltip(
                            message: "Next book (Right arrow)",
                            waitDuration: Duration(seconds: 1),
                            child: IconButton(
                              style: ButtonStyle(
                                mouseCursor: WidgetStatePropertyAll(
                                  SystemMouseCursors.basic,
                                ),
                              ),
                              onPressed: () {
                                selectedIndex++;
                                setState(() {
                                  _changeSelected(selectedIndex);
                                });
                              },
                              icon: Icon(Icons.arrow_circle_right_outlined),
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                MenuItemButton(
                  child: Text("Export all"),
                  onPressed: () {
                    _exportAll(context);
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
            controller: controller,
            itemCount: selectedHighlights.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 20.0);
            },
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: SelectableText(selectedHighlights[index]),
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
                          _copyToClipboard(context, selectedHighlights[index]);
                        },
                      ),
                      MenuItemButton(
                        child: Text("Export"),
                        onPressed: () {
                          _exportHighlight(context, selectedHighlights[index]);
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
                tileColor: selectedIndex == index
                    ? Theme.of(context).highlightColor
                    : Colors.transparent,
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
