# saf_stream

[![pub package](https://img.shields.io/pub/v/saf_stream.svg)](https://pub.dev/packages/saf_stream)

Read and write Android SAF `DocumentFile` with streams. Min SDK version: **API 21**.

## Usage

```dart
/// Creates a stream from the given [uri].
Future<Stream<Uint8List>> readFile(Uri uri, {int? bufferSize});

/// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
/// to write data into the destination stream. Call [endWriteStream] close the destination stream.
Future<SafWriteStreamInfo> startWriteStream(
    Uri treeUri, String fileName, String mime);

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
Stream<List<int>> fileStream = await _safStreamPlugin.readFile(uri);

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
