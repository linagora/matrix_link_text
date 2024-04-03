//  Copyright (c) 2019 Aleksander Woźniak
//  Copyright (c) 2020 Sorunome
//  Licensed under Apache License v2.0

library matrix_link_text;

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'schemes.dart';
import 'tlds.dart';

typedef LinkTapHandler = void Function(Uri);
typedef TextSpanBuilder = TextSpan Function(
  String? text,
  TextStyle? textStyle,
  GestureRecognizer? recognizer,
);

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
  final Uri url;
  final LinkTapHandler? onLinkTap;

  LinkTextSpan(
      {TextStyle? style,
      required this.url,
      String? text,
      this.onLinkTap,
      List<InlineSpan>? children})
      : super(
          style: style,
          text: text ?? '',
          children: children ?? <InlineSpan>[],
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (onLinkTap != null) {
                onLinkTap(url);
                return;
              }
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw 'Could not launch $url';
              }
            },
        ) {
    _fixRecognizer(this, recognizer!);
  }

  void _fixRecognizer(TextSpan textSpan, GestureRecognizer recognizer) {
    if (textSpan.children?.isEmpty ?? true) {
      return;
    }
    final fixedChildren = <InlineSpan>[];
    for (final child in textSpan.children!) {
      if (child is TextSpan && child.recognizer == null) {
        _fixRecognizer(child, recognizer);
        fixedChildren.add(TextSpan(
          text: child.text,
          style: child.style,
          recognizer: recognizer,
          children: child.children,
        ));
      } else {
        fixedChildren.add(child);
      }
    }
    textSpan.children!.clear();
    textSpan.children!.addAll(fixedChildren);
  }
}

/// Like Text.rich only that it also correctly disposes of all recognizers
class CleanRichText extends StatefulWidget {
  final InlineSpan child;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextScaler? textScaler;

  const CleanRichText(
    this.child, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.textScaler,
  })
      : super(key: key);

  @override
  State<CleanRichText> createState() => _CleanRichTextState();
}

class _CleanRichTextState extends State<CleanRichText> {
  void _disposeTextspan(TextSpan textSpan) {
    textSpan.recognizer?.dispose();
    if (textSpan.children != null) {
      for (final child in textSpan.children!) {
        if (child is TextSpan) {
          _disposeTextspan(child);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.child is TextSpan) {
      _disposeTextspan(widget.child as TextSpan);
    }
  }

  @override
  Widget build(BuildContext build) {
    return Text.rich(
      widget.child,
      textScaler: widget.textScaler,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
  }
}

// whole regex:
// (?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:[^\s\x{200b}]+(?::[^\s\x{200b}]*)?@)?(?:[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.[a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\x{200b}\(]*(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))?|(?!\/\/)[^\s\x{200b}\(]+(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))|(?<!\.)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+)(?:(?=[\/?#])[^\s\x{200b}\(]*(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))?|(?:[^\s\x{200b}]+@)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+))|[#!+$@][^:\s\x{200b}]*:[\w\.\d-]+\.[\w\d-]+)
// Consists of: `startregex(?:urlregex|matrixregex)`
// start regex: (?<=\b|(?<=\W)(?=[#!+$@])|^)
// url regex: (?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:[^\s\x{200b}]+(?::[^\s\x{200b}]*)?@)?(?:[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.[a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\x{200b}\(]*(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))?|(?!\/\/)[^\s\x{200b}\(]+(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))|(?<!\.)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+)(?:(?=[\/?#])[^\s\x{200b}\(]*(?:\([^\s\x{200b}]*[^\s\x{200b}:;,.!?>\]}]|[^\s\x{200b}\):;,.!?>\]}]))?|(?:[^\s\x{200b}]+@)[a-z\d\x{00a1}-\x{ffff}](?:\.?[a-z\d\x{00a1}-\x{ffff}-])*\.(?!http)([a-z\x{00a1}-\x{ffff}][a-z\x{00a1}-\x{ffff}-]+))
// matrix regex: [#!+$@][^:\s\x{200b}]*:[\w\.\d-]+\.[\w\d-]+
// \x{0000} needs to be replaced with \u0000, not done in the comments so that they work with regex101.com
final RegExp _regex = RegExp(
    r'(?<=\b|(?<=\W)(?=[#!+$@])|^)(?:(?<![#!+$@=])(?:([a-z0-9]+):(?:\/\/(?:[^\s\u200b]+(?::[^\s\u200b]*)?@)?(?:[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.[a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\u200b\(]*(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))?|(?!\/\/)[^\s\u200b\(]+(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))|(?<!\.)[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+)(?:(?=[\/?#])[^\s\u200b\(]*(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))?|(?:[^\s\u200b]+@)[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+))|[#!+$@][^:\s\u200b]*:[\w\.\d-]+\.[\w\d-]+)',
    caseSensitive: false);

// fallback regex without lookbehinds for incompatible browsers etc.
// it is slightly worse but still gets the job mostly done
final RegExp _fallbackRegex = RegExp(
    r'(?:\b|(?=[#!+$@])|^)(?:(?:([a-z0-9]+):(?:\/\/(?:[^\s\u200b]+(?::[^\s\u200b]*)?@)?(?:[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.[a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+|\d{1,3}(?:\.\d{1,3}){3}|\[[\da-f:]{3,}\]|localhost)(?::\d+)?(?:(?=[\/?#])[^\s\u200b\(]*(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))?|(?!\/\/)[^\s\u200b\(]+(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))|[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+)(?:(?=[\/?#])[^\s\u200b\(]*(?:\([^\s\u200b]*[^\s\u200b:;,.!?>\]}]|[^\s\u200b\):;,.!?>\]}]))?|(?:[^\s\u200b]+@)[a-z\d\u00a1-\uffff](?:\.?[a-z\d\u00a1-\uffff-])*\.(?!http)([a-z\u00a1-\uffff][a-z\u00a1-\uffff-]+))|[#!+$@][^:\s\u200b]*:[\w\.\d-]+\.[\w\d-]+)',
    caseSensitive: false);

final RegExp _estimateRegex = RegExp(r'[^\s\u200b][\.:][^\s\u200b]');

// ignore: non_constant_identifier_names
TextSpan LinkTextSpans(
    {required String text,
    TextStyle? textStyle,
    TextStyle? linkStyle,
    LinkTapHandler? onLinkTap,
    ThemeData? themeData,
    TextSpanBuilder? textSpanBuilder}) {
  textSpanBuilder ??= (text, style, recognizer) => TextSpan(
        text: text,
        style: style,
        recognizer: recognizer,
      );
  Future<void> launchUrlIfHandler(Uri url) async {
    if (onLinkTap != null) {
      onLinkTap(url);
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  textStyle ??= themeData?.textTheme.bodyMedium;
  linkStyle ??= themeData?.textTheme.bodyMedium?.copyWith(
    color: themeData.colorScheme.secondary,
    decoration: TextDecoration.underline,
  );

  // first estimate if we are going to have matches at all
  final estimateMatches = _estimateRegex.allMatches(text);
  if (estimateMatches.isEmpty) {
    return textSpanBuilder(text, textStyle, null);
  }

  // Our _regex uses lookbehinds for nicer matching, which isn't supported by all browsers yet.
  // Sadly, an error is only thrown on usage. So, we try to match against an empty string to get
  // our error ASAP and then determine the regex we use based on that.
  RegExp regexToUse;
  try {
    _regex.hasMatch('');
    regexToUse = _regex;
  } catch (_) {
    regexToUse = _fallbackRegex;
  }

  List<RegExpMatch>? links;
  List<String>? textParts;
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
    void processChunk() {
      if (textParts == null || links == null) {
        abort = true;
        links = null;
        textParts = null;
        return;
      }
      // we gotta make sure to save the text fragment between the current and the last chunk
      final firstFragment = text.substring(lastEnd, curStart);
      if (firstFragment.isNotEmpty) {
        textParts!.last += firstFragment;
      }
      // fetch our current fragment...
      final fragment = text.substring(curStart, curEnd);
      // add all the links
      links!.addAll(regexToUse.allMatches(fragment));

      // and fetch the text parts
      final fragmentTextParts = fragment.split(regexToUse);
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
      textParts!.last += fragmentTextParts.removeAt(0);
      textParts!.addAll(fragmentTextParts);
      // and save the lastEnd for later
      lastEnd = curEnd;
    }

    for (final e in estimateMatches) {
      const int kChunkSize = 120;
      final start = max(e.start - kChunkSize, 0);
      final end = min(e.start + kChunkSize, text.length);
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
      if (lastFragment.isNotEmpty && textParts != null) {
        textParts!.last += lastFragment;
      }
    }
  }
  links ??= regexToUse.allMatches(text).toList();
  if (links!.isEmpty) {
    return textSpanBuilder(text, textStyle, null);
  }

  textParts ??= text.split(regexToUse);
  final textSpans = <InlineSpan>[];

  int i = 0;
  for (var part in textParts!) {
    textSpans.add(textSpanBuilder(part, textStyle, null));

    if (i < links!.length) {
      final element = links![i];
      final linkText = element.group(0) ?? '';
      var link = linkText;
      final scheme = element.group(1);
      final tldUrl = element.group(2);
      final tldEmail = element.group(3);
      var valid = true;
      if (scheme?.isNotEmpty ?? false) {
        // we have to validate the scheme
        valid = kAllSchemes.contains(scheme!.toLowerCase());
      }
      if (valid && (tldUrl?.isNotEmpty ?? false)) {
        // we have to validate if the tld exists
        valid = kAllTlds.contains(tldUrl!.toLowerCase());
        link = 'https://$link';
      }
      if (valid && (tldEmail?.isNotEmpty ?? false)) {
        // we have to validate if the tld exists
        valid = kAllTlds.contains(tldEmail!.toLowerCase());
        link = 'mailto:$link';
      }
      final uri = Uri.tryParse(link);
      if (valid && uri != null) {
          textSpans.add(
            textSpanBuilder(
              linkText,
              linkStyle,
              TapGestureRecognizer()..onTap = () => launchUrlIfHandler(uri),
            ),
          );
      } else {
        textSpans.add(textSpanBuilder(linkText, textStyle, null));
      }

      i++;
    }
  }
  return TextSpan(text: '', children: textSpans);
}

class LinkText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;

  const LinkText({
    Key? key,
    required this.text,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onLinkTap,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CleanRichText(
      LinkTextSpans(
        text: text,
        textStyle: textStyle,
        linkStyle: linkStyle,
        onLinkTap: onLinkTap,
        themeData: Theme.of(context),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}