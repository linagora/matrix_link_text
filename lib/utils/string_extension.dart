import 'package:matrix_link_text/model/pill.dart';

const matrixToScheme = "https://matrix.to/#/";
const matrixScheme = "matrix:";

extension StringExtension on String {
  Pill? toPillModel() {
    final urlLower = toLowerCase();

    if (urlLower.startsWith(matrixScheme) ||
        urlLower.startsWith(matrixToScheme)) {
      var isPill = true;
      var identifier = this;

      if (urlLower.startsWith(matrixToScheme)) {
        final urlPart = substring(matrixToScheme.length).split("?").first;

        try {
          identifier = Uri.decodeComponent(urlPart);
        } catch (_) {
          identifier = urlPart;
        }
        isPill = RegExp(r'^[@#!+][^:]+:[^\/]+$').firstMatch(identifier) != null;
      } else {
        final match = RegExp(r'^matrix:(r|roomid|u)\/([^\/]+)$')
            .firstMatch(urlLower.split('?').first.split('#').first);

        isPill = match != null && match.group(2) != null;

        if (isPill) {
          final sigil = {
            'r': '#',
            'roomid': '#',
            'u': '@',
          }[match.group(1)];

          if (sigil == null) {
            isPill = false;
          } else {
            identifier = sigil + match.group(2)!;
          }
        }
      }

      if (isPill) {
        return Pill(identifier: identifier, url: this);
      }
    }
    return null;
  }
}
