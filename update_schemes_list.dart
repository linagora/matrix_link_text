import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

const kIcaanUrl =
    'https://www.iana.org/assignments/uri-schemes/uri-schemes-1.csv';
const kOutFile = './lib/schemes.dart';

void main() async {
  final res = utf8.decode((await http.get(Uri.parse(kIcaanUrl))).bodyBytes);
  final file = await File(kOutFile).open(mode: FileMode.write);
  await file.writeString('const kAllSchemes = {\n');
  for (final row in res.split('\n')) {
    final scheme = row.split(',').first.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-z]+$').hasMatch(scheme) || scheme.isEmpty) {
      continue;
    }

    await file.writeString('  "$scheme",\n');
  }
  await file.writeString('};\n');
  await file.close();
}
