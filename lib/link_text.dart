//  Copyright (c) 2019 Aleksander Woźniak
//  Copyright (c) 2020 Sorunome
//  Licensed under Apache License v2.0

library matrix_link_text;

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import 'tlds.dart';
import 'schemes.dart';

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
// (?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:\S+(?::\S*)?@)?(?:[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.[a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?!\/\/)[^\s\(]+(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))|(?<!\.)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+)(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?:\S+@)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+))|[#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+)
// Consists of: `startregex(?:urlregex|matrixregex)`
// start regex: (?<=\b|(?<=\W)(?=[#!+$@])|^)
// url regex: (?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:\S+(?::\S*)?@)?(?:[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.[a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?!\/\/)[^\s\(]+(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))|(?<!\.)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+)(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?:\S+@)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+))
// matrix regex: [#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+
// \x{0000} needs to be replaced with \u0000, not done in the comments so that they work with regex101.com
final RegExp _regex = RegExp(
    r'(?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:\S+(?::\S*)?@)?(?:[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.[a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?!\/\/)[^\s\(]+(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))|(?<!\.)[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+)(?:(?=[\/?#])[^\s\(]*(?:\(\S*[^\s:;,.!?]|[^\s\):;,.!?]))?|(?:\S+@)[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+))|[#!+$@][^:\s]*:[\w\.\d-]+\.[\w-\d]+)',
    caseSensitive: false);

final RegExp _estimateRegex = RegExp(r'\S[\.:]\S');

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

  // first estimate if we are going to have matches at all
  final estimateMatches = _estimateRegex.allMatches(text);
  if (estimateMatches.isEmpty) {
    return TextSpan(
      text: text,
      style: textStyle,
      children: [],
    );
  }

  List<RegExpMatch> links;
  List<String> textParts;
  if (text.length > 300) {
    // we have a super long text, let's try to split it up
    links = [];
    // thing greatly simplify if the textParts.last is already a string
    textParts = [''];
    // now we will separate the `text` into chunks around their matches, and then apply the regex
    // only to those substrings.
    // As we already estimated some matches, we know the for-loop will run at least once, simplifying things
    // we will need to make sure to merge overlapping chunks together
    var curStart = -1; // the current chunk start
    var curEnd = 0; // the current chunk end
    var lastEnd = 0; // the last chunk end, where we stopped parsing
    var abort = false; // should we abort and fall back to the slow method?
    final processChunk = () {
      // we gotta make sure to save the text fragment between the current and the last chunk
      final firstFragment = text.substring(lastEnd, curStart);
      if (firstFragment.isNotEmpty) {
        textParts.last += firstFragment;
      }
      // fetch our current fragment...
      final fragment = text.substring(curStart, curEnd);
      // add all the links
      links.addAll(_regex.allMatches(fragment));

      // and fetch the text parts
      final fragmentTextParts = fragment.split(_regex);
      // if the first of last text part is empty, that means that the chunk wasn't big enough to fit the full URI
      // thus we abort and fall back to the slow method
      if ((fragmentTextParts.first.isEmpty && curStart > 0) ||
          (fragmentTextParts.last.isEmpty && curEnd < text.length)) {
        abort = true;
        links = null;
        textParts = null;
        return;
      }
      // add all the text parts correctly
      textParts.last += fragmentTextParts.removeAt(0);
      textParts.addAll(fragmentTextParts);
      // and save the lastEnd for later
      lastEnd = curEnd;
    };
    for (final e in estimateMatches) {
      const CHUNK_SIZE = 120;
      final start = max(e.start - CHUNK_SIZE, 0);
      final end = min(e.start + CHUNK_SIZE, text.length);
      if (start < curEnd) {
        // merge blocks
        curEnd = end;
      } else {
        // new block! And proccess the last chunk!
        if (curStart != -1) {
          processChunk();
        }
        curStart = start;
        curEnd = end;
      }
      if (abort) {
        break;
      }
    }
    // we musn't forget to proccess the last chunk
    if (!abort) {
      processChunk();
    }
    if (!abort) {
      // and we musn't forget to add the last fragment
      final lastFragment = text.substring(lastEnd, text.length);
      if (lastFragment.isNotEmpty) {
        textParts.last += lastFragment;
      }
    }
  }
  links ??= _regex.allMatches(text).toList();
  if (links.isEmpty) {
    return TextSpan(
      text: text,
      style: textStyle,
      children: [],
    );
  }

  textParts ??= text.split(_regex);
  final textSpans = <InlineSpan>[];

  int i = 0;
  textParts.forEach((part) {
    textSpans.add(TextSpan(text: part, style: textStyle));

    if (i < links.length) {
      final element = links[i];
      final linkText = element.group(0);
      var link = linkText;
      final scheme = element.group(1);
      final tldUrl = element.group(2);
      final tldEmail = element.group(3);
      var valid = true;
      if ((scheme ?? '').isNotEmpty) {
        // we have to validate the scheme
        valid = ALL_SCHEMES.contains(scheme.toLowerCase());
      }
      if (valid && (tldUrl ?? '').isNotEmpty) {
        // we have to validate if the tld exists
        valid = ALL_TLDS.contains(tldUrl.toLowerCase());
        link = 'https://' + link;
      }
      if (valid && (tldEmail ?? '').isNotEmpty) {
        // we have to validate if the tld exists
        valid = ALL_TLDS.contains(tldEmail.toLowerCase());
        link = 'mailto:' + link;
      }
      if (valid) {
        if (kIsWeb) {
          // on web recognizer in TextSpan does not work properly, so we use normal text w/ inkwell
          textSpans.add(
            WidgetSpan(
              child: InkWell(
                onTap: () => _launchUrl(link),
                child: Text(linkText, style: linkStyle),
              ),
            ),
          );
        } else {
          textSpans.add(
            LinkTextSpan(
              text: linkText,
              style: linkStyle,
              url: link,
              onLinkTap: _launchUrl,
            ),
          );
        }
      } else {
        textSpans.add(TextSpan(text: linkText, style: textStyle));
      }

      i++;
    }
  });
  return TextSpan(text: '', children: textSpans);
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
