import 'dart:typed_data';

import 'saf_stream_platform_interface.dart';

class SafStream {
  /// Reads the contents of a file from the given [uri] and returns a stream of bytes.
  ///
  /// If [bufferSize] is provided, the stream will read data in chunks of [bufferSize] bytes.
  /// If [start] is provided, the stream will start reading from the given position.
  Future<Stream<Uint8List>> readFileStream(String uri,
      {int? bufferSize, int? start}) async {
    return SafStreamPlatform.instance
        .readFileStream(uri, bufferSize: bufferSize, start: start);
  }

  /// Reads the contents of a file from the given [uri]. Unlike [readFileStream],
  /// this method reads the entire file at once and returns a [Uint8List].
  ///
  /// If [start] and [count] are provided, reads [count] bytes starting from [start].
  Future<Uint8List> readFileBytes(String uri, {int? start, int? count}) async {
    return SafStreamPlatform.instance
        .readFileBytes(uri, start: start, count: count);
  }

  /// Reads the contents of a file from the given [uri]. Unlike [readFileStream],
  /// this method reads the entire file at once and returns a [Uint8List].
  ///
  /// If [start] and [count] are provided, reads [count] bytes starting from [start].
  @Deprecated(
      'Use [readFileBytes] instead. It is the same method with a different name. The [readFileSync] is confusing because it is not synchronous.')
  Future<Uint8List> readFileSync(String uri, {int? start, int? count}) async {
    return SafStreamPlatform.instance
        .readFileBytes(uri, start: start, count: count);
  }

  /// Copies a SAF file from the given [srcUri] to a local file [destPath].
  Future<void> copyToLocalFile(String srcUri, String destPath) async {
    return SafStreamPlatform.instance.copyToLocalFile(srcUri, destPath);
  }

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
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .pasteLocalFile(srcPath, treeUri, fileName, mime, overwrite: overwrite);
  }

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  ///
  /// Returns a [SafNewFile], which contains the Uri and file name of newly created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  Future<SafNewFile> writeFileBytes(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .writeFileBytes(treeUri, fileName, mime, data, overwrite: overwrite);
  }

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  ///
  /// Returns a [SafNewFile], which contains the Uri and file name of newly created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  @Deprecated(
      'Use [writeFileBytes] instead. It is the same method with a different name. The [writeFileSync] is confusing because it is not synchronous.')
  Future<SafNewFile> writeFileSync(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .writeFileBytes(treeUri, fileName, mime, data, overwrite: overwrite);
  }

  /// Returns a [SafWriteStreamInfo]. Call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// to write data into the destination stream. Call [endWriteStream] to close the destination stream.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafWriteStreamInfo].
  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    return SafStreamPlatform.instance
        .startWriteStream(treeUri, fileName, mime, overwrite: overwrite);
  }

  /// Writes the given [data] to an out stream identified by the given [session].
  Future<void> writeChunk(String session, Uint8List data) async {
    return SafStreamPlatform.instance.writeChunk(session, data);
  }

  /// Closes an out stream identified by the given [session].
  Future<void> endWriteStream(String session) async {
    return SafStreamPlatform.instance.endWriteStream(session);
  }

  /// Like [readFileStream], but returns a session where you can control the reading process.
  Future<String> startReadCustomFileStream(String uri,
      {int? bufferSize}) async {
    return SafStreamPlatform.instance
        .startReadCustomFileStream(uri, bufferSize: bufferSize);
  }

  /// Reads a chunk of bytes from a custom file stream identified by the given [session].
  Future<Uint8List?> readCustomFileStreamChunk(String session) async {
    return SafStreamPlatform.instance.readCustomFileStreamChunk(session);
  }

  /// Skips [count] bytes from a custom file stream identified by the given [session].
  Future<int> skipCustomFileStreamChunk(String session, int count) async {
    return SafStreamPlatform.instance.skipCustomFileStreamChunk(session, count);
  }

  /// Closes a custom file stream identified by the given [session].
  Future<void> endReadCustomFileStream(String session) async {
    return SafStreamPlatform.instance.endReadCustomFileStream(session);
  }
}
