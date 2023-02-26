import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'saf_stream_method_channel.dart';

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

  Future<Stream<Uint8List>> readFile(String uri, {int? bufferSize}) async {
    throw UnimplementedError('readFile() has not been implemented.');
  }

  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime) async {
    throw UnimplementedError('startWriteStream() has not been implemented.');
  }

  Future<void> writeChunk(String session, Uint8List data) async {
    throw UnimplementedError('writeChunk() has not been implemented.');
  }

  Future<void> endWriteStream(String session) async {
    throw UnimplementedError('endWriteStream() has not been implemented.');
  }
}
