import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_storage/saf.dart';
import 'dart:async';

import 'package:shared_storage/shared_storage.dart' as saf;
import 'package:saf_stream/saf_stream.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _safStreamPlugin = SafStream();
  List<DocumentFile> _files = [];
  Uri? _treeUri;
  String _output = '';
  int _session = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              OutlinedButton(
                  onPressed: _selectFolder,
                  child: const Text('Select a folder')),
              OutlinedButton(
                  onPressed: () => _writeFile(null),
                  child: const Text('Create a new random file')),
              OutlinedButton(
                  onPressed: () => _writeFile('1.txt'),
                  child: const Text('Create 1.txt')),
              ...(_files.map((f) => Row(
                    children: [
                      Text(f.name ?? ''),
                      const SizedBox(width: 10),
                      Text(f.isFile == true ? 'F' : 'D'),
                      const SizedBox(width: 10),
                      OutlinedButton(
                          onPressed: () => _readFile(f.uri),
                          child: const Text('Read stream'))
                    ],
                  ))),
              const SizedBox(width: 10),
              const Text('Output'),
              Text(_output)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFolder() async {
    try {
      var treeUri = await saf.openDocumentTree(persistablePermission: false);
      if (treeUri == null) {
        return;
      }
      _treeUri = treeUri;
      const List<DocumentFileColumn> columns = <DocumentFileColumn>[
        DocumentFileColumn.displayName,
        DocumentFileColumn.size,
        DocumentFileColumn.lastModified,
        DocumentFileColumn
            .id, // Optional column, will be available/queried regardless if is or not included here
        DocumentFileColumn.mimeType,
      ];
      var files = await saf.listFiles(treeUri, columns: columns).toList();
      setState(() {
        _files = files;
        _output = '';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _readFile(Uri uri) async {
    try {
      var session = ++_session;
      await for (var bytes
          in await _safStreamPlugin.readFile(uri, bufferSize: 500 * 1024)) {
        setState(() {
          _output += '$session - <Bytes:${bytes.length}>\n';
        });
      }
      setState(() {
        _output += '$session - <Done>\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _writeFile(String? fileName) async {
    try {
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }
      var session = ++_session;
      fileName = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

      var info = await _safStreamPlugin.startWriteStream(
          treeUri, fileName, 'text/plain');
      setState(() {
        _output += '$session - <Writing uri ${info.uri}>\n';
      });
      for (var i = 0; i < 3; i++) {
        setState(() {
          _output += '$session - <Writing chunk ${i + 1}>\n';
        });
        await _safStreamPlugin.writeChunk(
            info.session, Uint8List.fromList(utf8.encode(i.toString())));
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      await _safStreamPlugin.endWriteStream(info.session);
      setState(() {
        _output += '$session - <Finished writing uri ${info.uri}>\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }
}
