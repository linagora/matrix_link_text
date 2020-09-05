//  Copyright (c) 2019 Aleksander Woźniak
//  Copyright (c) 2020 Sorunome
//  Licensed under Apache License v2.0

library matrix_link_text;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LinkTapHandler = void Function(String);

class LinkTextSpan extends TextSpan {
  // Beware!
  //
  // This class is only safe because the TapGestureRecognizer is not
  // given a deadline and therefore never allocates any resources.
  //
  // In any other situation -- setting a deadline, using any of the less trivial
  // recognizers, etc -- you would have to manage the gesture recognizer's
  // lifetime and call dispose() when the TextSpan was no longer being rendered.
  //
  // Since TextSpan itself is @immutable, this means that you would have to
  // manage the recognizer from outside the TextSpan, e.g. in the State of a
  // stateful widget that then hands the recognizer to the TextSpan.
  final String url;

  LinkTextSpan(
      {TextStyle style,
      this.url,
      String text,
      LinkTapHandler onLinkTap,
      List<InlineSpan> children})
      : super(
          style: style,
          text: text,
          children: children ?? <InlineSpan>[],
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onLinkTap?.call(url);
            },
        );
}

// whole regex:
// (?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@|\d{1,3}(?:\.\d{1,3}){3}|(?:(?:[a-z\d\x{00a1}-\x{ffff}]+-?)*[a-z\d\x{00a1}-\x{ffff}]+)(?:\.(?:[a-z\d\x{00a1}-\x{ffff}]+-?)*[a-z\d\x{00a1}-\x{ffff}]+)*(?:\.[a-z\x{00a1}-\x{ffff}]{2,6}))(?::\d+)?(?:[^\s\(]*(?:\(\S*[^\s:;,.]|[^\s\):;,.]))?|[#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+)
// Consists of: `startregex(?:urlregex|matrixregex)`
// start regex: (?<=\b|(?<=\W)(?=[#!+$@])|^)
// url regex: (?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@|\d{1,3}(?:\.\d{1,3}){3}|(?:(?:[a-z\d\x{00a1}-\x{ffff}]+-?)*[a-z\d\x{00a1}-\x{ffff}]+)(?:\.(?:[a-z\d\x{00a1}-\x{ffff}]+-?)*[a-z\d\x{00a1}-\x{ffff}]+)*(?:\.[a-z\x{00a1}-\x{ffff}]{2,6}))(?::\d+)?(?:[^\s\(]*(?:\(\S*[^\s:;,.]|[^\s\):;,.]))?
// matrix regex: [#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+
// \x{0000} needs to be replaced with \u0000, not done in the comments so that they work with regex101.com
final RegExp _regex = RegExp(
    r"(?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@|\d{1,3}(?:\.\d{1,3}){3}|(?:(?:[a-z\d\u00a1-\uffff]+-?)*[a-z\d\u00a1-\uffff]+)(?:\.(?:[a-z\d\u00a1-\uffff]+-?)*[a-z\d\u00a1-\uffff]+)*(?:\.[a-z\u00a1-\uffff]{2,6}))(?::\d+)?(?:[^\s\(]*(?:\(\S*[^\s:;,.]|[^\s\):;,.]))?|[#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+)");

// ignore: non_constant_identifier_names
TextSpan LinkTextSpans(
    {String text,
    TextStyle textStyle,
    TextStyle linkStyle,
    LinkTapHandler onLinkTap,
    ThemeData themeData}) {
  assert(text != null);
  final _launchUrl = (String url) async {
    if (onLinkTap != null) {
      onLinkTap(url);
      return;
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  };

  textStyle ??= themeData?.textTheme?.bodyText2;
  linkStyle ??= themeData?.textTheme?.bodyText2?.copyWith(
    color: themeData?.accentColor,
    decoration: TextDecoration.underline,
  );

  final links = _regex.allMatches(text);
  if (links.isEmpty) {
    return TextSpan(
      text: text,
      style: textStyle,
    );
  }

  final textParts = text.split(_regex);
  final textSpans = <TextSpan>[];

  int i = 0;
  textParts.forEach((part) {
    textSpans.add(TextSpan(text: part, style: textStyle));

    if (i < links.length) {
      final link = links.elementAt(i).group(0);
      textSpans.add(
        LinkTextSpan(
          text: link,
          style: linkStyle,
          url: link,
          onLinkTap: _launchUrl,
        ),
      );

      i++;
    }
  });
  return TextSpan(children: textSpans);
}

class LinkText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final TextStyle linkStyle;
  final TextAlign textAlign;
  final LinkTapHandler onLinkTap;

  const LinkText({
    Key key,
    @required this.text,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onLinkTap,
  })  : assert(text != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      LinkTextSpans(
        text: text,
        textStyle: textStyle,
        linkStyle: linkStyle,
        onLinkTap: onLinkTap,
        themeData: Theme.of(context),
      ),
      textAlign: textAlign,
    );
  }
}
