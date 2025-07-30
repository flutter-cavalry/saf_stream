# saf_stream

[![pub package](https://img.shields.io/pub/v/saf_stream.svg)](https://pub.dev/packages/saf_stream)

Read and write Android SAF `DocumentFile`. Min SDK version: **API 21**.

> For other SAF APIs, see [saf_util](https://github.com/flutter-cavalry/saf_util)

## Usage

- Use bytes-based APIs for small files or when memory is not a concern.
  - Read: `readFileBytes`
  - Write: `writeFileBytes`
- Use file streams for large files.
  - Read: `readFileStream`
  - Write: `startWriteStream`, `writeChunk`, `endWriteStream`
- APIs to interact with non-SAF files:
  - Copy an SAF file to local file: `copyToLocalFile`
  - Paste local file into an SAF directory: `pasteLocalFile`
- Some advanced read APIs if you need to skip bytes on native side instead of on Dart side using `readFileStream`
  - `startReadCustomFileStream`, `readCustomFileStreamChunk`, `skipCustomFileStreamChunk`, `endReadCustomFileStream`

## Examples

```dart
import 'package:saf_stream/saf_stream.dart';

final _safStreamPlugin = SafStream();

// Read file bytes.
List<int> fileBytes = await _safStreamPlugin.readFileBytes('<SAF file URI>');

// Write file bytes.
await _safStreamPlugin.writeFileBytes(
  // Dest SAF directory URI.
  '<SAF directory Uri>',
  // Dest file name.
  'file.txt',
  // MIME type.
  'text/plain',
  // Data to write.
  utf8.encode('Hello, World!')
);

// Read file stream.
Stream<List<int>> fileStream = await _safStreamPlugin.readFileStream('<SAF file URI>');

// Write file stream.
// Create a session.
final info = await _safStreamPlugin.startWriteStream('SAF directory URI ', '<SAF file URI>', 'text/plain');
final sessionID = info.session;
// Write chunk with a session ID.
await _safStreamPlugin.writeChunk(sessionID, utf8.encode('block 1'));
// Write another chunk.
await _safStreamPlugin.writeChunk(sessionID, utf8.encode('block 2'));
// Close the stream.
await _safStreamPlugin.endWriteStream(sessionID);
```
