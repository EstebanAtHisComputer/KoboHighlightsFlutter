import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kobo_highlights/db.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

void _showAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationIcon: Image(image: AssetImage("assets/logo.png"), height: 128.0),
    applicationVersion: "1.0",
    applicationLegalese: """MIT License

Copyright (c) 2025 EstebanAtHisComputer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

KOBO is a registered trademark owned by RAKUTEN KOBO INC., a TORONTO, ONTARIO based entity.
This software is not affiliated, associated, authorized, or endorsed in any way by RAKUTEN KOBO INC.
""",
  );
}

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
    final file = File(result.path);
    await file.writeAsBytes(fileData);

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

  Future<void> _exportAsImage(BuildContext context, String text) {
    return showDialog(
      context: context,
      requestFocus: true,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Export as image"),
          children: [ExportImageBody(title: selectedTitle, text: text)],
        );
      },
    );
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
                selectedIndex > -1
                    ? MenuItemButton(
                        child: Text("Export all"),
                        onPressed: () {
                          _exportAll(context);
                        },
                      )
                    : SizedBox.shrink(),
                MenuItemButton(
                  child: Text("About this app..."),
                  onPressed: () {
                    _showAbout(context);
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
                      MenuItemButton(
                        child: Text("Export as image"),
                        onPressed: () {
                          _exportAsImage(context, selectedHighlights[index]);
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

class ExportImageBody extends StatefulWidget {
  final String text;
  final String title;

  const ExportImageBody({required this.title, required this.text, super.key});

  @override
  State<ExportImageBody> createState() => _ExportImageBodyState();
}

class _ExportImageBodyState extends State<ExportImageBody> {
  final GlobalKey _cardKey = GlobalKey();

  bool _bigText = false;
  bool _includeAuthor = true;

  //Based on https://medium.com/@henryifebunandu/capture-and-save-flutter-widgets-as-images-a-step-by-step-guide-638e77225f6f
  Future<void> _captureAndSave(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 10.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final String fileName = "${widget.title}.png";
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          XTypeGroup(label: "Image file", extensions: [".png"]),
        ],
      );
      if (result == null) {
        return;
      }
      final file = File(result.path);
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Card(
            child: Padding(
              padding: EdgeInsetsGeometry.all(32),
              child: Column(
                children: [
                  Text(
                    '"${widget.text}"',
                    style: TextStyle(fontSize: _bigText ? 24 : 16),
                  ),
                  _includeAuthor
                      ? Text(
                          widget.title,
                          style: TextStyle(fontSize: _bigText ? 16 : 14),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 225,
              child: SwitchListTile(
                value: _bigText,
                onChanged: (b) {
                  setState(() {
                    _bigText = b;
                  });
                },
                title: Text("Big text"),
              ),
            ),
            SizedBox(
              width: 225,
              child: SwitchListTile(
                value: _includeAuthor,
                onChanged: (b) {
                  setState(() {
                    _includeAuthor = b;
                  });
                },
                title: Text("Include title"),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 12.0,
          children: [
            FilledButton(
              onPressed: () {
                _captureAndSave(context);
              },
              child: Text("Save"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  ColorScheme.of(context).secondary,
                ),
              ),
              child: Text("Close"),
            ),
          ],
        ),
      ],
    );
  }
}
