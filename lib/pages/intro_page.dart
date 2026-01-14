import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:kobo_highlights/db.dart';
import 'package:package_info_plus/package_info_plus.dart';

import './main_page.dart';
import '../utils.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override
  State<StatefulWidget> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String version = "VER_NOT_FOUND";

  _fetchVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String appVersion = packageInfo.version;
    setState(() {
      version = "$appName $appVersion";
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image(
              image: Theme.of(context).brightness == Brightness.dark
                  ? AssetImage("assets/logo.png")
                  : AssetImage("assets/logo_black.png"),
            ),
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
                      errorDialog(
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
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Opacity(opacity: 0.5, child: Text(version)),
      ),
    );
  }
}
