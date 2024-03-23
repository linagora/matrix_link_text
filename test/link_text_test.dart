import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_link_text/link_text.dart';

void main() {
  const String text =
      '@[Quang Huy Nguyen 🇻🇳 123] https://github.com/linagora/twake-on-matrix/issues/1183';

  testWidgets('[LinkTextSpans TEST]', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text.rich(
            TextSpan(
              children: [
                LinkTextSpans(text: text, mapTagNameToUrl: {
                  '@[Quang Huy Nguyen 🇻🇳 123]':
                      'https://matrix.to/#/@quanghnguyen:linagora.com'
                })
              ],
            ),
          ),
        ),
      ),
    ));
  });
}
