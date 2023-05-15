//  Copyright (c) 2019 Aleksander Woźniak
//  Licensed under Apache License v2.0

import 'package:flutter/material.dart';
import 'package:matrix_link_text/link_text.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkText Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'LinkText Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _text =
      'Lorem ipsum https://flutter.dev\nhttps://pub.dev dolor https://google.com sit amet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24.0),
              _buildNormalText(),
              const SizedBox(height: 64.0),
              _buildLinkText(),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Normal Text Widget',
          textAlign: TextAlign.center,
          style: const TextStyle().copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12.0),
        Text(_text, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildLinkText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'LinkText Widget',
          textAlign: TextAlign.center,
          style: const TextStyle().copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12.0),
        LinkText(text: _text, textAlign: TextAlign.center),
      ],
    );
  }
}
