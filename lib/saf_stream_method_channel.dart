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
  Future<Uint8List> readFileBytes(String uri, {int? start, int? count}) async {
    start ??= 0;
    if (start < 0) {
      throw ArgumentError('`start` must be greater than or equal to 0');
    }
    if (count != null) {
      if (count <= 0) {
        throw ArgumentError('`count` must be greater than 0');
      }
    }
    final res = await methodChannel.invokeMethod<Uint8List>('readFileBytes', {
      'fileUri': uri.toString(),
      'start': start,
      'count': count,
    });
    if (res == null) {
      throw Exception('Unexpected empty response from `readFileBytes`');
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
  Future<SafNewFile> writeFileBytes(
      String treeUri, String fileName, String mime, Uint8List data,
      {bool? overwrite}) async {
    var map =
        await methodChannel.invokeMapMethod<String, dynamic>('writeFileBytes', {
      'treeUri': treeUri.toString(),
      'fileName': fileName,
      'mime': mime,
      'data': data,
      'overwrite': overwrite ?? false,
    });
    if (map == null) {
      throw Exception('Unexpected empty response from `writeFileBytes`');
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

  @override
  Future<String> startReadCustomFileStream(String uri,
      {int? bufferSize}) async {
    var session = _nextSession().toString();
    await methodChannel.invokeMethod<String>('startReadCustomFileStream', {
      'fileUri': uri.toString(),
      'session': session,
      'bufferSize': bufferSize,
    });
    return session;
  }

  @override
  Future<Uint8List?> readCustomFileStreamChunk(String session) async {
    return await methodChannel
        .invokeMethod<Uint8List>('readCustomFileStreamChunk', {
      'session': session.toString(),
    });
  }

  @override
  Future<int> skipCustomFileStreamChunk(String session, int count) async {
    final res =
        await methodChannel.invokeMethod<int>('skipCustomFileStreamChunk', {
      'session': session.toString(),
      'count': count,
    });
    return res ?? 0;
  }

  @override
  Future<void> endReadCustomFileStream(String session) async {
    await methodChannel.invokeMethod<void>('endReadCustomFileStream', {
      'session': session.toString(),
    });
  }

  int _nextSession() {
    return ++_session;
  }
}
