# saf_stream

[![pub package](https://img.shields.io/pub/v/saf_stream.svg)](https://pub.dev/packages/saf_stream)

Read and write Android Storage Access Framework (SAF) documents. Minimum Android version: **API 21**.

> For other SAF APIs, see [saf_util](https://github.com/flutter-cavalry/saf_util)

## Usage

[API reference](https://pub.dev/documentation/saf_stream/latest/saf_stream/SafStream-class.html)

- Use byte-based APIs for small files or when loading the entire file into memory is acceptable.
  - Read: `readFileBytes`
  - Write:
    - `writeFileBytes` (writes to a directory using a file name)
    - `writeFileUriBytes` (writes to a file identified by its URI)
- Use file streams for large files.
  - Read: `readFileStream`
  - Write:
    - Start a stream with `startWriteStream` (directory and file name) or `startWriteFileUriStream` (file URI).
    - Write chunks with `writeChunk`.
    - Close the stream with `endWriteStream`.
- To copy between SAF documents and local files, use `copyToLocalFile` or `pasteLocalFile`.
- Write APIs support the optional `overwrite` and `append` parameters.
- To skip bytes on the native side rather than in Dart, use the advanced read APIs. This can reduce memory use:
  - `startReadCustomFileStream`, `readCustomFileStreamChunk`, `skipCustomFileStreamChunk`, `endReadCustomFileStream`

## Examples

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:saf_stream/saf_stream.dart';

final _safStreamPlugin = SafStream();

// Read file bytes.
Uint8List fileBytes = await _safStreamPlugin.readFileBytes('<SAF file URI>');

// Write file bytes.
await _safStreamPlugin.writeFileBytes(
  // Destination SAF directory URI.
  '<SAF directory Uri>',
  // Destination file name.
  'file.txt',
  // MIME type.
  'text/plain',
  // Data to write.
  Uint8List.fromList(utf8.encode('Hello, World!')),
);

// Read file stream.
Stream<List<int>> fileStream = await _safStreamPlugin.readFileStream('<SAF file URI>');

// Write file stream.
// Start a write session.
final info = await _safStreamPlugin.startWriteStream(
  '<SAF directory URI>',
  'file.txt',
  'text/plain',
);
final sessionID = info.session;
// Write chunk with a session ID.
await _safStreamPlugin.writeChunk(sessionID, utf8.encode('block 1'));
// Write another chunk.
await _safStreamPlugin.writeChunk(sessionID, utf8.encode('block 2'));
// Close the stream.
await _safStreamPlugin.endWriteStream(sessionID);
```
