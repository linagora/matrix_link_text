import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:punycode/punycode.dart';

const ICAAN_URL = 'https://data.iana.org/TLD/tlds-alpha-by-domain.txt';
const OUT_FILE = './lib/tlds.dart';

void main() async {
  final res = utf8.decode((await http.get(ICAAN_URL)).bodyBytes);
  final file = await File(OUT_FILE).open(mode: FileMode.write);
  await file.writeString('const ALL_TLDS = [\n');
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
  await file.writeString('];\n');
  await file.close();
}
