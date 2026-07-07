import 'dart:typed_data';

import 'saf_stream_platform_interface.dart';

class SafStream {
  /// Reads the contents of a file from the given [uri] and returns a stream of bytes.
  ///
  /// If [bufferSize] is provided, the stream will read data in chunks of [bufferSize] bytes.
  /// If [start] is provided, the stream will start reading from the given position.
  Future<Stream<Uint8List>> readFileStream(
    String uri, {
    int? bufferSize,
    int? start,
  }) async {
    return SafStreamPlatform.instance.readFileStream(
      uri,
      bufferSize: bufferSize,
      start: start,
    );
  }

  /// Reads the contents of a file from the given [uri]. Unlike [readFileStream],
  /// this method reads the entire file at once and returns a [Uint8List].
  ///
  /// If [start] and [count] are provided, reads [count] bytes starting from [start].
  Future<Uint8List> readFileBytes(String uri, {int? start, int? count}) async {
    return SafStreamPlatform.instance.readFileBytes(
      uri,
      start: start,
      count: count,
    );
  }

  /// Reads the contents of a file from the given [uri]. Unlike [readFileStream],
  /// this method reads the entire file at once and returns a [Uint8List].
  ///
  /// If [start] and [count] are provided, reads [count] bytes starting from [start].
  @Deprecated(
    'Use [readFileBytes] instead. It is the same method with a different name. The [readFileSync] is confusing because it is not synchronous.',
  )
  Future<Uint8List> readFileSync(String uri, {int? start, int? count}) async {
    return SafStreamPlatform.instance.readFileBytes(
      uri,
      start: start,
      count: count,
    );
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
  /// If [append] is true, the data will be appended to the file if it already exists.
  Future<SafNewFile> pasteLocalFile(
    String srcPath,
    String treeUri,
    String fileName,
    String mime, {
    bool? overwrite,
    bool? append,
  }) async {
    return SafStreamPlatform.instance.pasteLocalFile(
      srcPath,
      treeUri,
      fileName,
      mime,
      overwrite: overwrite,
      append: append,
    );
  }

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  /// Note that SAF may change the file name if a file with the same name already exists. The resulting
  /// [SafNewFile] contains the actual file name and Uri.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  /// If [append] is true, the data will be appended to the file if it already exists.
  Future<SafNewFile> writeFileBytes(
    String treeUri,
    String fileName,
    String mime,
    Uint8List data, {
    bool? overwrite,
    bool? append,
  }) async {
    return SafStreamPlatform.instance.writeFileBytes(
      treeUri,
      fileName,
      mime,
      data,
      overwrite: overwrite,
      append: append,
    );
  }

  /// Writes the given [data] to a file identified by the given [fileUri].
  /// Note that SAF may change the file name if a file with the same name already exists. The resulting
  /// [SafNewFile] contains the actual file name and Uri.
  ///
  /// If [append] is true, the data will be appended to the file if it already exists.
  Future<SafNewFile> writeFileUriBytes(
    String fileUri,
    Uint8List data, {
    bool? append,
  }) async {
    return SafStreamPlatform.instance.writeFileUriBytes(
      fileUri,
      data,
      append: append,
    );
  }

  /// Writes the given [data] to a file identified by the given [treeUri], [fileName] and [mime].
  ///
  /// Returns a [SafNewFile], which contains the Uri and file name of newly created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafNewFile].
  /// If [append] is true, the data will be appended to the file if it already exists.
  @Deprecated(
    'Use [writeFileBytes] instead. It is the same method with a different name. The [writeFileSync] is confusing because it is not synchronous.',
  )
  Future<SafNewFile> writeFileSync(
    String treeUri,
    String fileName,
    String mime,
    Uint8List data, {
    bool? overwrite,
    bool? append,
  }) async {
    return SafStreamPlatform.instance.writeFileBytes(
      treeUri,
      fileName,
      mime,
      data,
      overwrite: overwrite,
      append: append,
    );
  }

  /// Creates a file stream for writing data to a file identified by the given [treeUri], [fileName] and [mime].
  /// Note that SAF may change the file name if a file with the same name already exists. The resulting
  /// [SafNewFile] contains the actual file name and Uri.
  ///
  /// To write data to the stream, call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// Call [endWriteStream] to close the the stream.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a new name
  /// will be generated and returned in the resulting [SafWriteStreamInfo].
  /// If [append] is true, the data will be appended to the file if it already exists.
  Future<SafWriteStreamInfo> startWriteStream(
    String treeUri,
    String fileName,
    String mime, {
    bool? overwrite,
    bool? append,
  }) async {
    return SafStreamPlatform.instance.startWriteStream(
      treeUri,
      fileName,
      mime,
      overwrite: overwrite,
      append: append,
    );
  }

  /// Creates a file stream for writing data to a file identified by the given [fileUri].
  ///
  /// To write data to the stream, call [writeChunk] with the [session] from [SafWriteStreamInfo]
  /// Call [endWriteStream] to close the the stream.
  ///
  /// If [append] is true, the data will be appended to the file if it already exists.
  Future<SafWriteStreamInfo> startWriteFileUriStream(
    String fileUri, {
    bool? append,
  }) async {
    return SafStreamPlatform.instance.startWriteFileUriStream(
      fileUri,
      append: append,
    );
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
  Future<String> startReadCustomFileStream(
    String uri, {
    int? bufferSize,
  }) async {
    return SafStreamPlatform.instance.startReadCustomFileStream(
      uri,
      bufferSize: bufferSize,
    );
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
