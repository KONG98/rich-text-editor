import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import 'quill/models/documents/document.dart';
import 'quill/widgets/controller.dart';
import 'quill/widgets/default_styles.dart';
import 'quill/widgets/editor.dart';
import 'quill/widgets/toolbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quill Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadFromAssets();
  }

  Future<void> _loadFromAssets() async {
    Document doc = Document()..insert(0, 'Empty asset');
    doc = doc..insert(11, 'data');
    setState(() {
      _controller = QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '我的文本编辑器',
        ),
        actions: [],
      ),
      body: _buildWelcomeEditor(context),
    );
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    var quillEditor = QuillEditor(
        controller: _controller!,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: _focusNode,
        autoFocus: false,
        readOnly: false,
        placeholder: 'Add content',
        expands: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          h1: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 32.0,
                color: Colors.blue,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              const Tuple2(16.0, 0.0),
              const Tuple2(0.0, 0.0),
              null),
          sizeSmall: const TextStyle(fontSize: 9.0),
        ));
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: QuillEditor(
                controller: _controller!,
                scrollController: ScrollController(),
                scrollable: true,
                focusNode: _focusNode,
                autoFocus: false,
                readOnly: false,
                placeholder: 'Add content',
                expands: false,
                padding: EdgeInsets.zero,
                customStyles: DefaultStyles(
                  h1: DefaultTextBlockStyle(
                      const TextStyle(
                        fontSize: 32.0,
                        color: Colors.blue,
                        height: 1.15,
                        fontWeight: FontWeight.w300,
                      ),
                      const Tuple2(16.0, 0.0),
                      const Tuple2(0.0, 0.0),
                      null),
                  sizeSmall: const TextStyle(fontSize: 9.0),
                ),
              ),
            ),
          ),
          Container(
            child: Toolbar.basic(
              controller: _controller!,
            ),
          ),
        ],
      ),
    );
  }
}
