import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'saf_stream_method_channel.dart';

/// Describes the result of a write operation.
class SafNewFile {
  /// The Uri of the destination file.
  final Uri uri;

  /// The name of the destination file.
  final String? fileName;

  SafNewFile(this.uri, this.fileName);

  @override
  String toString() {
    return 'SafWriteResult{uri: $uri, fileName: $fileName}';
  }

  static SafNewFile fromMap(Map<String, dynamic> map) {
    final uriString = map['uri'] as String?;
    if (uriString == null) {
      throw Exception('Unexpected empty uri from `SafFileNewFile`');
    }
    final fileName = map['fileName'] as String?;
    return SafNewFile(Uri.parse(uriString), fileName);
  }
}

/// Contains information about an SAF out stream.
class SafWriteStreamInfo {
  /// A unique string to identity this stream.
  final String session;

  /// The information of the destination file.
  final SafNewFile fileResult;

  SafWriteStreamInfo(this.session, this.fileResult);

  @override
  String toString() {
    return 'SafWriteStreamInfo{session: $session, fileResult: $fileResult}';
  }
}

abstract class SafStreamPlatform extends PlatformInterface {
  /// Constructs a SafStreamPlatform.
  SafStreamPlatform() : super(token: _token);

  static final Object _token = Object();

  static SafStreamPlatform _instance = MethodChannelSafStream();

  /// The default instance of [SafStreamPlatform] to use.
  ///
  /// Defaults to [MethodChannelSafStream].
  static SafStreamPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SafStreamPlatform] when
  /// they register themselves.
  static set instance(SafStreamPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Stream<Uint8List>> readFileStream(String uri,
      {int? bufferSize, int? start}) async {
    throw UnimplementedError('readFileStream() has not been implemented.');
  }

  Future<Uint8List> readFileBytes(String uri, {int? start, int? count}) async {
    throw UnimplementedError('readFileBytes() has not been implemented.');
  }

  Future<void> copyToLocalFile(String srcUri, String destPath) async {
    throw UnimplementedError('copyToLocalFile() has not been implemented.');
  }

  Future<SafNewFile> pasteLocalFile(
      String srcPath, String treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    throw UnimplementedError('pasteLocalFile() has not been implemented.');
  }

  Future<SafNewFile> writeFileBytes(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    throw UnimplementedError('writeFileBytes() has not been implemented.');
  }

  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    throw UnimplementedError('startWriteStream() has not been implemented.');
  }

  Future<void> writeChunk(String session, Uint8List data) async {
    throw UnimplementedError('writeChunk() has not been implemented.');
  }

  Future<void> endWriteStream(String session) async {
    throw UnimplementedError('endWriteStream() has not been implemented.');
  }

  Future<String> startReadCustomFileStream(String uri,
      {int? bufferSize}) async {
    throw UnimplementedError(
        'startReadCustomFileStream() has not been implemented.');
  }

  Future<Uint8List?> readCustomFileStreamChunk(String session) async {
    throw UnimplementedError(
        'readCustomFileStreamChunk() has not been implemented.');
  }

  Future<int> skipCustomFileStreamChunk(String session, int count) async {
    throw UnimplementedError(
        'skipCustomFileStreamChunk() has not been implemented.');
  }

  Future<void> endReadCustomFileStream(String session) async {
    throw UnimplementedError(
        'endReadCustomFileStream() has not been implemented.');
  }
}
