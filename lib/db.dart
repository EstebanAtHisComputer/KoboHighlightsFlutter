import 'dart:collection';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

var highlights = SplayTreeMap<(String, String), List<String>>(
  (key1, key2) => key1.$1.compareTo(key2.$1),
);

Future tryDB(String filePath) async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(filePath);
  var result = await db.rawQuery('''
  select 
title, text, attribution
from bookmark
left outer join content
on (content.contentID=bookmark.VolumeID and content.ContentType=6)
where  
text is not null;
''');

  for (var entry in result) {
    final title = entry['Title'] as String;
    final author = entry['Attribution'] as String;
    highlights
        .putIfAbsent((title, author), () => [])
        .add(entry['Text'] as String);
  }
}
