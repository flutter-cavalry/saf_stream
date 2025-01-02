# saf_stream

[![pub package](https://img.shields.io/pub/v/saf_stream.svg)](https://pub.dev/packages/saf_stream)

Read and write Android SAF `DocumentFile`. Min SDK version: **API 21**.

> For other SAF APIs, see [saf_util](https://github.com/flutter-cavalry/saf_util)

## Usage

|                     | Read              | Write             | Description                                          |
| ------------------- | ----------------- | ----------------- | ---------------------------------------------------- |
| Bytes (`Uint8List`) | `readFileBytes`   | `writeFileBytes`  | Good for small files or when memory is not a concern |
| Streams             | `readFileStream`  | `writeFileStream` | For large files                                      |
| Non-SAF files       | `copyToLocalFile` | `pasteLocalFile`  | When you need to interact with non-SAF files         |

```dart
class SafStream {
  /// Reads the contents of a file from the given [uri]. Unlike [readFileStream],
  /// this method reads the entire file at once and returns a [Uint8List].
  ///
  /// If [start] and [count] are provided, reads [count] bytes starting from [start].
  Future<Uint8List> readFileBytes(String uri, {int? start, int? count});

  /// Reads the contents of a file from the given [uri] and returns a stream of bytes.
  ///
  /// If [bufferSize] is provided, the stream will read data in chunks of [bufferSize] bytes.
  /// If [start] is provided, the stream will start reading from the given position.
  Future<Stream<Uint8List>> readFileStream(String uri,
      {int? bufferSize, int? start});

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  ///
  /// Returns a [SafNewFile], which contains the Uri and file name of newly created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  Future<SafNewFile> writeFileBytes(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite});

  /// Copies a SAF file from the given [srcUri] to a local file [destPath].
  Future<void> copyToLocalFile(String srcUri, String destPath);

  /// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// to write data into the destination stream. Call [endWriteStream] to close the destination stream.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafWriteStreamInfo].
  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime,
      {bool? overwrite});

  /// Writes the given [data] to an out stream identified by the given [session].
  Future<void> writeChunk(String session, Uint8List data);

  /// Closes an out stream identified by the given [session].
  Future<void> endWriteStream(String session);

  /// Copies the contents of a local file [srcPath] and creates a new file
  /// from the given [treeUri], [fileName] and [mime].
  ///
  /// Returns a [SafNewFile], which contains the Uri and file name of newly created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  Future<SafNewFile> pasteLocalFile(
      String srcPath, String treeUri, String fileName, String mime,
      {bool? overwrite});
}
```

## Example

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
