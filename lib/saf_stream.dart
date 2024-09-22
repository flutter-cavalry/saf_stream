import 'dart:typed_data';

import 'saf_stream_platform_interface.dart';

class SafStream {
  /// Reads the contents of a file from the given [uri] and returns a stream of bytes.
  Future<Stream<Uint8List>> readFile(Uri uri, {int? bufferSize}) async {
    return SafStreamPlatform.instance.readFile(uri, bufferSize: bufferSize);
  }

  /// Reads the contents of a file from the given [uri].
  Future<Uint8List> readFileSync(Uri uri) async {
    return SafStreamPlatform.instance.readFileSync(uri);
  }

  /// Copies a file from the given [uri] to a local file [dest].
  Future<void> copyToLocalFile(Uri src, String dest) async {
    return SafStreamPlatform.instance.copyToLocalFile(src, dest);
  }

  /// Copies the contents of a local file [localSrc] and creates a new file
  /// from the given [treeUri], [fileName] and [mime].
  /// Returns the Uri of the created file.
  Future<SafNewFile> pasteLocalFile(
      String localSrc, Uri treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .pasteLocalFile(localSrc, treeUri, fileName, mime);
  }

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  Future<SafNewFile> writeFileSync(
      Uri treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .writeFileSync(treeUri, fileName, mime, data);
  }

  /// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// to write data into the destination stream. Call [endWriteStream] to close the destination stream.
  Future<SafWriteStreamInfo> startWriteStream(
      Uri treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance.startWriteStream(treeUri, fileName, mime);
  }

  /// Writes the given [data] to an out stream identified by the given [session].
  Future<void> writeChunk(String session, Uint8List data) async {
    return SafStreamPlatform.instance.writeChunk(session, data);
  }

  /// Closes an out stream identified by the given [session].
  Future<void> endWriteStream(String session) async {
    return SafStreamPlatform.instance.endWriteStream(session);
  }
}
