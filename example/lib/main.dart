import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';
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
  final _safUtil = SafUtil();
  final _safStreamPlugin = SafStream();
  List<SafDocumentFile> _files = [];
  String? _treeUri;
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
                      Text(_output),
                      const SizedBox(height: 10),
                      OutlinedButton(
                          onPressed: _reload, child: const Text('Reload')),
                      OutlinedButton(
                          onPressed: () => _writeFile(null, false),
                          child: const Text('Create a new random file')),
                      OutlinedButton(
                          onPressed: () => _writeFile('1.txt', false),
                          child: const Text('Create 1.txt')),
                      OutlinedButton(
                          onPressed: () => _writeFile('1.txt', true),
                          child: const Text('Create 1.txt (overwrite)')),
                      OutlinedButton(
                          onPressed: () => _pasteLocalFile(false),
                          child: const Text(
                              'Create a.bin from local file (pasteLocalFile)')),
                      OutlinedButton(
                          onPressed: () => _pasteLocalFile(true),
                          child: const Text(
                              'Create a.bin from local file (pasteLocalFile) (overwrite)')),
                      OutlinedButton(
                          onPressed: () => _writeFileBytes(false),
                          child: const Text('Write a.bin bytes')),
                      OutlinedButton(
                          onPressed: () => _writeFileBytes(true),
                          child: const Text('Write a.bin bytes (overwrite)')),
                      ...(_files.where((f) => !f.isDir == true).map((f) =>
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)),
                            child: Column(
                              spacing: 10,
                              children: [
                                Text(f.name),
                                OutlinedButton(
                                    onPressed: () => _readFileStream(f.uri),
                                    child: const Text('Read stream')),
                                OutlinedButton(
                                    onPressed: () => _readFileBytes(f.uri),
                                    child: const Text('Read bytes')),
                                OutlinedButton(
                                    onPressed: () =>
                                        _readCustomFileStream(f.uri),
                                    child: const Text('Read custom stream')),
                                OutlinedButton(
                                    onPressed: () => _copyToLocalFile(f.uri),
                                    child: const Text('Copy to local file')),
                              ],
                            ),
                          ))),
                      const SizedBox(width: 10),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    try {
      if (_treeUri == null) {
        return;
      }
      var files = await _safUtil.list(_treeUri!);
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
      var treeUri = await _safUtil.openDirectory();
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

  Future<void> _readFileStream(String uri) async {
    try {
      _clearOutput();
      var session = ++_session;
      await for (var bytes in await _safStreamPlugin.readFileStream(uri,
          bufferSize: 500 * 1024)) {
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

  Future<void> _readCustomFileStream(String uri) async {
    try {
      _clearOutput();
      final session = await _safStreamPlugin.startReadCustomFileStream(uri,
          bufferSize: 500 * 1024);
      Uint8List? chunk;
      while ((chunk =
              await _safStreamPlugin.readCustomFileStreamChunk(session)) !=
          null) {
        setState(() {
          _output += '<Bytes:${chunk?.length}>\n';
        });
      }
      await _safStreamPlugin.endReadCustomFileStream(session);
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _readFileBytes(String uri) async {
    try {
      _clearOutput();
      final bytes = await _safStreamPlugin.readFileBytes(uri);
      setState(() {
        _output += 'Read file bytes: ${bytes.lengthInBytes} \n';
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

  Future<void> _copyToLocalFile(String uri) async {
    try {
      _clearOutput();
      final dest = tmpPath();
      await _safStreamPlugin.copyToLocalFile(uri, dest);
      final localContents = await File(dest).readAsBytes();
      setState(() {
        _output += 'Copy to local file: ${localContents.length} bytes';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _writeFile(String? fileName, bool overwrite) async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }
      var session = ++_session;
      fileName = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

      var info = await _safStreamPlugin.startWriteStream(
          treeUri, fileName, 'text/plain',
          overwrite: overwrite);
      setState(() {
        _output += '$session - <Writing file $info>\n';
      });
      for (var i = 0; i < 3; i++) {
        setState(() {
          _output += '$session - <Writing chunk ${i + 1}>\n';
        });
        await _safStreamPlugin.writeChunk(
            info.session, utf8.encode(i.toString()));
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

  Future<void> _pasteLocalFile(bool overwrite) async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }

      final localSrc = tmpPath();
      await File(localSrc).writeAsString('✅❌❤️⚒️😊😒');

      final info = await _safStreamPlugin.pasteLocalFile(
          localSrc, treeUri, 'a.bin', 'application/octet-stream',
          overwrite: overwrite);
      setState(() {
        _output = 'Created file: $info\n';
      });
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  Future<void> _writeFileBytes(bool overwrite) async {
    try {
      _clearOutput();
      var treeUri = _treeUri;
      if (treeUri == null) {
        return;
      }

      final info = await _safStreamPlugin.writeFileBytes(
          treeUri,
          'a.bin',
          'application/octet-stream',
          Uint8List.fromList(utf8.encode('✅❌❤️⚒️😊😒')),
          overwrite: overwrite);
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
