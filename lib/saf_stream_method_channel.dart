import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'saf_stream_platform_interface.dart';

/// Contains information about an SAF out stream.
class SafWriteStreamInfo {
  /// A unique string to identity this stream.
  final String session;

  /// The Uri of the destination file.
  final Uri uri;

  /// The name of the destination file.
  final String fileName;

  SafWriteStreamInfo(this.session, this.uri, this.fileName);
}

/// An implementation of [SafStreamPlatform] that uses method channels.
class MethodChannelSafStream extends SafStreamPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('saf_stream');

  var _session = 0;

  @override
  Future<Stream<Uint8List>> readFile(Uri uri, {int? bufferSize}) async {
    var session = _nextSession();
    var channelName = await methodChannel.invokeMethod<String>('readFile', {
      'fileUri': uri.toString(),
      'session': session.toString(),
      'bufferSize': bufferSize
    });
    if (channelName == null) {
      throw Exception('Unexpected empty channel name from `readFile`');
    }
    var stream = EventChannel(channelName);
    return stream.receiveBroadcastStream().map((e) => e as Uint8List);
  }

  @override
  Future<void> readFileToLocal(Uri src, String dest) async {
    await methodChannel.invokeMethod<String>('readFileToLocal', {
      'src': src.toString(),
      'dest': dest,
    });
  }

  @override
  Future<Uri> writeFileFromLocal(
      String localSrc, Uri treeUri, String fileName, String mime) async {
    var uri = await methodChannel.invokeMethod<String>('writeFileFromLocal', {
      'localSrc': localSrc,
      'treeUri': treeUri.toString(),
      'fileName': fileName,
      'mime': mime
    });
    if (uri == null) {
      throw Exception('Unexpected empty Uri');
    }
    return Uri.parse(uri);
  }

  @override
  Future<SafWriteStreamInfo> startWriteStream(
      Uri treeUri, String fileName, String mime) async {
    var session = _nextSession().toString();
    var map = await methodChannel
        .invokeMapMethod<String, dynamic>('startWriteStream', {
      'treeUri': treeUri.toString(),
      'session': session,
      'fileName': fileName,
      'mime': mime
    });
    if (map == null) {
      throw Exception('Unexpected empty response from `startWriteStream`');
    }
    final uri = Uri.parse(map['uri']);
    final newFileName = map['fileName'];
    return SafWriteStreamInfo(session, uri, newFileName);
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
