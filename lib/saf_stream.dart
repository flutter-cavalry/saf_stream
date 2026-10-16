import 'dart:typed_data';

import 'saf_stream_platform_interface.dart';

class SafStream {
  /// Returns a stream of bytes read from the file identified by [uri].
  ///
  /// If provided, [bufferSize] sets the number of bytes read per chunk, and
  /// [start] sets the byte offset at which reading begins.
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

  /// Reads the file identified by [uri] and returns its contents as a [Uint8List].
  /// Unlike [readFileStream], this method reads the entire file at once.
  ///
  /// If [start] and [count] are provided, reads up to [count] bytes starting
  /// at byte offset [start].
  Future<Uint8List> readFileBytes(String uri, {int? start, int? count}) async {
    return SafStreamPlatform.instance.readFileBytes(
      uri,
      start: start,
      count: count,
    );
  }

  /// Reads the file identified by [uri] and returns its contents as a [Uint8List].
  /// Unlike [readFileStream], this method reads the entire file at once.
  ///
  /// If [start] and [count] are provided, reads up to [count] bytes starting
  /// at byte offset [start].
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

  /// Copies the local file at [srcPath] to a new file in the SAF directory
  /// identified by [treeUri], using [fileName] and [mime].
  ///
  /// Returns a [SafNewFile] containing the URI and name of the created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a
  /// new name is generated and returned in the [SafNewFile].
  /// If [append] is true, the data is appended to the file if it already exists.
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

  /// Writes [data] to a file in the SAF directory identified by [treeUri],
  /// using [fileName] and [mime]. SAF may change the name if a file with the
  /// requested name already exists; the returned [SafNewFile] contains the
  /// actual name and URI.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a
  /// new name is generated and returned in the [SafNewFile].
  /// If [append] is true, [data] is appended to the file if it already exists.
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

  /// Writes [data] to the file identified by [fileUri].
  ///
  /// If [append] is true, [data] is appended to the file.
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

  /// Writes [data] to a file in the SAF directory identified by [treeUri],
  /// using [fileName] and [mime].
  ///
  /// Returns a [SafNewFile] containing the URI and name of the created file.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a
  /// new name is generated and returned in the [SafNewFile].
  /// If [append] is true, [data] is appended to the file if it already exists.
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

  /// Opens a file stream for writing to a file in the SAF directory identified
  /// by [treeUri], using [fileName] and [mime]. SAF may change the name if a
  /// file with the requested name already exists; the returned [SafNewFile]
  /// contains the actual name and URI.
  ///
  /// To write data, call [writeChunk] with the [session] from the returned
  /// [SafWriteStreamInfo]. Call [endWriteStream] to close the stream.
  ///
  /// If [overwrite] is true, the file will be overwritten if it already exists.
  /// If [overwrite] is false and a file with the same name already exists, a
  /// new name is generated and returned in [SafWriteStreamInfo].
  /// If [append] is true, data is appended to the file if it already exists.
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

  /// Opens a file stream for writing to the file identified by [fileUri].
  ///
  /// To write data, call [writeChunk] with the [session] from the returned
  /// [SafWriteStreamInfo]. Call [endWriteStream] to close the stream.
  ///
  /// If [append] is true, data is appended to the file.
  Future<SafWriteStreamInfo> startWriteFileUriStream(
    String fileUri, {
    bool? append,
  }) async {
    return SafStreamPlatform.instance.startWriteFileUriStream(
      fileUri,
      append: append,
    );
  }

  /// Writes [data] to the output stream identified by [session].
  Future<void> writeChunk(String session, Uint8List data) async {
    return SafStreamPlatform.instance.writeChunk(session, data);
  }

  /// Closes the output stream identified by [session].
  Future<void> endWriteStream(String session) async {
    return SafStreamPlatform.instance.endWriteStream(session);
  }

  /// Opens a file stream like [readFileStream] and returns a session that lets
  /// you control the reading process.
  Future<String> startReadCustomFileStream(
    String uri, {
    int? bufferSize,
  }) async {
    return SafStreamPlatform.instance.startReadCustomFileStream(
      uri,
      bufferSize: bufferSize,
    );
  }

  /// Reads the next chunk from the custom file stream identified by [session].
  Future<Uint8List?> readCustomFileStreamChunk(String session) async {
    return SafStreamPlatform.instance.readCustomFileStreamChunk(session);
  }

  /// Skips up to [count] bytes in the custom file stream identified by [session].
  Future<int> skipCustomFileStreamChunk(String session, int count) async {
    return SafStreamPlatform.instance.skipCustomFileStreamChunk(session, count);
  }

  /// Closes the custom file stream identified by [session].
  Future<void> endReadCustomFileStream(String session) async {
    return SafStreamPlatform.instance.endReadCustomFileStream(session);
  }
}
