import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:punycode/punycode.dart';

const kIcaanUrl = 'https://data.iana.org/TLD/tlds-alpha-by-domain.txt';
const kOutFile = './lib/tlds.dart';

void main() async {
  final res = utf8.decode((await http.get(Uri.parse(kIcaanUrl))).bodyBytes);
  final file = await File(kOutFile).open(mode: FileMode.write);
  await file.writeString('const kAllTlds = {\n');
  for (var tld in res.split('\n')) {
    tld = tld.trim().toLowerCase();
    if (tld.startsWith('#') || tld.isEmpty) {
      continue;
    }
    if (tld.startsWith('xn--')) {
      // decode unicode TLD
      await file.writeString('  "${punycodeDecode(tld.substring(4))}",\n');
    }
    await file.writeString('  "$tld",\n');
  }
  await file.writeString('};\n');
  await file.close();
}
