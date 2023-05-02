import 'dart:typed_data';

import 'package:saf_stream/saf_stream_method_channel.dart';

import 'saf_stream_platform_interface.dart';

class SafStream {
  /// Creates a stream from the given [uri].
  Future<Stream<Uint8List>> readFile(Uri uri, {int? bufferSize}) async {
    return SafStreamPlatform.instance.readFile(uri, bufferSize: bufferSize);
  }

  /// Copies a file from the given [uri] to the [dest].
  Future<void> readFileToLocal(Uri src, String dest) async {
    return SafStreamPlatform.instance.readFileToLocal(src, dest);
  }

  /// Copies the contents of [localSrc] and creates a new file from the given [treeUri], [fileName] and [mime].
  /// Returns the Uri of the created file.
  Future<Uri> writeFileFromLocal(
      String localSrc, Uri treeUri, String fileName, String mime) async {
    return SafStreamPlatform.instance
        .writeFileFromLocal(localSrc, treeUri, fileName, mime);
  }

  /// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// to write data into the destination stream. Call [endWriteStream] close the destination stream.
  Future<SafWriteStreamInfo> startWriteStream(
      Uri treeUri, String fileName, String mime) async {
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
