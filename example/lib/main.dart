import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:mg_shared_storage/shared_storage.dart' as saf;
import 'package:saf_stream/saf_stream.dart';
import 'package:tmp_path/tmp_path.dart';

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
  List<saf.DocumentFile> _files = [];
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
          child: Container(
            padding: const EdgeInsets.all(10),
            child: _treeUri == null
                ? OutlinedButton(
                    onPressed: _selectFolder,
                    child: const Text('Select a folder'))
                : Column(
                    children: [
                      OutlinedButton(
                          onPressed: _reload, child: const Text('Reload')),
                      OutlinedButton(
                          onPressed: () => _writeFile(null),
                          child: const Text('Create a new random file')),
                      OutlinedButton(
                          onPressed: () => _writeFile('1.txt'),
                          child: const Text('Create 1.txt')),
                      OutlinedButton(
                          onPressed: () => _pasteLocalFile(),
                          child: const Text(
                              'Create a.bin from local file (pasteLocalFile)')),
                      OutlinedButton(
                          onPressed: () => _writeFileSync(),
                          child: const Text('Write a.bin sync')),
                      ...(_files.where((f) => f.isFile == true).map((f) =>
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)),
                            child: Column(
                              children: [
                                Text(f.name ?? ''),
                                _sep(),
                                OutlinedButton(
                                    onPressed: () => _readFile(f.uri),
                                    child: const Text('Read stream')),
                                _sep(),
                                OutlinedButton(
                                    onPressed: () => _readFileSync(f.uri),
                                    child: const Text('Read sync')),
                                _sep(),
                                OutlinedButton(
                                    onPressed: () => _copyToLocalFile(f.uri),
                                    child: const Text('Copy to local file')),
                              ],
                            ),
                          ))),
                      const SizedBox(width: 10),
                      _sep(),
                      Text(_output)
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sep() {
    return const SizedBox(width: 10);
  }

  Future<void> _reload() async {
    try {
      if (_treeUri == null) {
        return;
      }
      const List<saf.DocumentFileColumn> columns = <saf.DocumentFileColumn>[
        saf.DocumentFileColumn.displayName,
        saf.DocumentFileColumn.size,
        saf.DocumentFileColumn.lastModified,
        saf.DocumentFileColumn
            .id, // Optional column, will be available/queried regardless if is or not included here
        saf.DocumentFileColumn.mimeType,
      ];
      var files = await saf.listFiles(_treeUri!, columns: columns).toList();
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

  Future<void> _selectFolder() async {
    try {
      var treeUri = await saf.openDocumentTree(persistablePermission: false);
      if (treeUri == null) {
        return;
      }
      _treeUri = treeUri;
      await _reload();
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _readFile(Uri uri) async {
    try {
      _clearOutput();
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

  Future<void> _readFileSync(Uri uri) async {
    try {
      _clearOutput();
      var session = ++_session;
      final bytes = await _safStreamPlugin.readFileSync(uri);
      setState(() {
        _output += '$session - Bytes: ${bytes.lengthInBytes} \n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }

  Future<void> _copyToLocalFile(Uri uri) async {
    try {
      _clearOutput();
      final dest = tmpPath();
      await _safStreamPlugin.copyToLocalFile(uri, dest);
      final localContents = await File(dest).readAsBytes();
      setState(() {
        _output += 'Local contents:\n$localContents\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _writeFile(String? fileName) async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }
      var session = ++_session;
      fileName = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

      var info = await _safStreamPlugin.startWriteStream(
          treeUri, fileName, 'text/plain');
      setState(() {
        _output += '$session - <Writing file $info>\n';
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
        _output += '$session - <Finished writing $info>\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _pasteLocalFile() async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }

      final localSrc = tmpPath();
      await File(localSrc).writeAsString('✅❌❤️⚒️😊😒');

      final info = await _safStreamPlugin.pasteLocalFile(
          localSrc, treeUri, 'a.bin', 'application/octet-stream');
      setState(() {
        _output = 'Created file: $info\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _writeFileSync() async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }

      final info = await _safStreamPlugin.writeFileSync(
          treeUri,
          'a.bin',
          'application/octet-stream',
          Uint8List.fromList(utf8.encode('✅❌❤️⚒️😊😒')));
      setState(() {
        _output = 'Created file: $info\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }
}
