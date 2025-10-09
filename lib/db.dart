import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Highlight {
  final String title;
  final String text;
  final String attribution;
  const Highlight({
    required this.title,
    required this.text,
    required this.attribution,
  });
}

Map<(String, String), List<Highlight>> highlights = {};

Future tryDB(String filePath) async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(filePath);
  var result = await db.rawQuery('''
  select 
title, text,annotation, attribution
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
        .add(
          Highlight(
            title: title,
            text: entry['Text'] as String,
            attribution: author,
          ),
        );
  }

  return highlights;
}
