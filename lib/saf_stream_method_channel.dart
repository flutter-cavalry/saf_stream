import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'saf_stream_platform_interface.dart';

/// An implementation of [SafStreamPlatform] that uses method channels.
class MethodChannelSafStream extends SafStreamPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('saf_stream');

  var _session = 0;

  @override
  Future<Stream<Uint8List>> readFileStream(String uri,
      {int? bufferSize, int? start}) async {
    var session = _nextSession();
    var channelName =
        await methodChannel.invokeMethod<String>('readFileStream', {
      'fileUri': uri.toString(),
      'session': session.toString(),
      'bufferSize': bufferSize,
      'start': start,
    });
    if (channelName == null) {
      throw Exception('Unexpected empty channel name from `readFile`');
    }
    var stream = EventChannel(channelName);
    return stream.receiveBroadcastStream().map((e) => e as Uint8List);
  }

  @override
  Future<Uint8List> readFileSync(String uri, {int? start, int? count}) async {
    if (start != null && count == null) {
      throw ArgumentError('`count` must be provided if `start` is provided');
    }
    if (count != null) {
      if (count <= 0) {
        throw ArgumentError('`count` must be greater than 0');
      }
      start ??= 0;
    }
    final res = await methodChannel.invokeMethod<Uint8List>('readFileSync', {
      'fileUri': uri.toString(),
      'start': start,
      'count': count,
    });
    if (res == null) {
      throw Exception('Unexpected empty response from `readFileSync`');
    }
    return res;
  }

  @override
  Future<void> copyToLocalFile(String srcUri, String destPath) async {
    await methodChannel.invokeMethod<String>('copyToLocalFile', {
      'src': srcUri.toString(),
      'dest': destPath,
    });
  }

  @override
  Future<SafNewFile> pasteLocalFile(
      String srcPath, String treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    var map =
        await methodChannel.invokeMapMethod<String, dynamic>('pasteLocalFile', {
      'localSrc': srcPath,
      'treeUri': treeUri.toString(),
      'fileName': fileName,
      'mime': mime,
      'overwrite': overwrite ?? false,
    });
    if (map == null) {
      throw Exception('Unexpected empty response from `pasteLocalFile`');
    }
    return SafNewFile.fromMap(map);
  }

  @override
  Future<SafNewFile> writeFileSync(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    var map =
        await methodChannel.invokeMapMethod<String, dynamic>('writeFileSync', {
      'treeUri': treeUri.toString(),
      'fileName': fileName,
      'mime': mime,
      'data': data,
      'overwrite': overwrite ?? false,
    });
    if (map == null) {
      throw Exception('Unexpected empty response from `writeFileSync`');
    }
    return SafNewFile.fromMap(map);
  }

  @override
  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime,
      {bool? overwrite}) async {
    var session = _nextSession().toString();
    var map = await methodChannel
        .invokeMapMethod<String, dynamic>('startWriteStream', {
      'treeUri': treeUri.toString(),
      'session': session,
      'fileName': fileName,
      'mime': mime,
      'overwrite': overwrite ?? false,
    });
    if (map == null) {
      throw Exception('Unexpected empty response from `startWriteStream`');
    }
    final newFile = SafNewFile.fromMap(map);
    return SafWriteStreamInfo(session, newFile);
  }

  @override
  Future<void> writeChunk(String session, Uint8List data) async {
    return await methodChannel.invokeMethod<void>('writeChunk', {
      'session': session.toString(),
      'data': data,
    });
  }

  @override
  Future<void> endWriteStream(String session) async {
    return await methodChannel.invokeMethod<void>('endWriteStream', {
      'session': session.toString(),
    });
  }

  int _nextSession() {
    return ++_session;
  }
}
