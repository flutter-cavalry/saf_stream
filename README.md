# saf_stream

[![pub package](https://img.shields.io/pub/v/saf_stream.svg)](https://pub.dev/packages/saf_stream)

Read and write Android SAF `DocumentFile` with streams. Min SDK version: **API 21**.

## Usage

```dart
/// Reads the contents of a file from the given [uri] and returns a stream of bytes.
Future<Stream<Uint8List>> readFileStream(String uri, {int? bufferSize, int? start});

/// Reads the contents of a file from the given [uri].
Future<Uint8List> readFileSync(String uri, {int? start, int? count});

/// Copies a file from the given [uri] to a local file [dest].
Future<void> copyToLocalFile(String src, String dest);

/// Copies the contents of a local file [localSrc] and creates a new file
/// from the given [treeUri], [fileName] and [mime].
/// Returns the Uri of the created file.
Future<SafNewFile> pasteLocalFile(
    String localSrc, Uri treeUri, String fileName, String mime, {bool? overwrite});

/// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
Future<SafNewFile> writeFileSync(
    Uri treeUri, String fileName, String mime, Uint8List data, {bool? overwrite});

/// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
/// to write data into the destination stream. Call [endWriteStream] to close the destination stream.
Future<SafWriteStreamInfo> startWriteStream(
    Uri treeUri, String fileName, String mime, {bool? overwrite});

/// Writes the given [data] to an out stream identified by the given [session].
Future<void> writeChunk(String session, Uint8List data);

/// Closes an out stream identified by the given [session].
Future<void> endWriteStream(String session);
```

## Example

```dart
import 'package:saf_stream/saf_stream.dart';

final _safStreamPlugin = SafStream();

// Read a file.
Uri fileUri = '...';
Stream<List<int>> fileStream = await _safStreamPlugin.readFileStream(uri);

// Write a file.
Uri treeUri = '...';
// Create a session.
final info = await _safStreamPlugin.startWriteStream(treeUri, 'myFile.txt', 'text/plain');
final sessionID = info.session;
// Write chunk with a session ID.
await _safStreamPlugin.writeChunk(sessionID, Uint8List.fromList(utf8.encode('block 1')));
// Write another chunk.
await _safStreamPlugin.writeChunk(sessionID, Uint8List.fromList(utf8.encode('block 2')));
// Close the stream.
await _safStreamPlugin.endWriteStream(sessionID);
```
