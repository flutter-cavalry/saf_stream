import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'saf_stream_platform_interface.dart';
import 'saf_stream_jni_io.dart';

/// An implementation of [SafStreamPlatform] that uses method channels.
class MethodChannelSafStream extends SafStreamPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('saf_stream');

  var _session = 0;

  @override
  Future<Stream<Uint8List>> readFileStream(
    String uri, {
    int? bufferSize,
    int? start,
  }) async {
    // `readFileStream` on the native side now only opens the stream and
    // registers it under `session` (see SafStreamPlugin.kt) -- a single
    // MethodChannel call. Every chunk after that is pulled directly via JNI
    // in SafStreamJniIo.readStream, with no EventChannel and no per-chunk
    // BinaryMessenger round trip.
    final session = _nextSession().toString();
    final effectiveBufferSize = bufferSize ?? (4 * 1024 * 1024);
    await methodChannel.invokeMethod<String>('readFileStream', {
      'fileUri': uri.toString(),
      'session': session,
      'start': start,
    });
    return SafStreamJniIo.readStream(session, bufferSize: effectiveBufferSize);
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
    // One-shot read, straight through JNI: skips the MethodChannel codec
    // round trip entirely for what can be a very large byte array.
    return SafStreamJniIo.readFileBytes(
      uri.toString(),
      start: start,
      count: count ?? -1,
    );
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
    String srcPath,
    String treeUri,
    String fileName,
    String mime, {
    bool? overwrite,
    bool? append,
  }) async {
    final map = await methodChannel
        .invokeMapMethod<String, dynamic>('pasteLocalFile', {
          'localSrc': srcPath,
          'treeUri': treeUri.toString(),
          'fileName': fileName,
          'mime': mime,
          'overwrite': overwrite ?? false,
          'append': append ?? false,
        });
    if (map == null) {
      throw Exception('Unexpected empty response from `pasteLocalFile`');
    }
    return SafNewFile.fromMap(map);
  }

  @override
  Future<SafNewFile> writeFileBytes(
    String treeUri,
    String fileName,
    String mime,
    Uint8List data, {
    bool? overwrite,
    bool? append,
  }) async {
    final map = await methodChannel
        .invokeMapMethod<String, dynamic>('writeFileBytes', {
          'treeUri': treeUri.toString(),
          'fileName': fileName,
          'mime': mime,
          'data': data,
          'overwrite': overwrite ?? false,
          'append': append ?? false,
        });
    if (map == null) {
      throw Exception('Unexpected empty response from `writeFileBytes`');
    }
    return SafNewFile.fromMap(map);
  }

  @override
  Future<SafNewFile> writeFileUriBytes(
    String fileUri,
    Uint8List data, {
    bool? append,
  }) async {
    // This calls the same native method as `writeFileBytes`, but with a different set of parameters.
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'writeFileBytes',
      {'fileUri': fileUri.toString(), 'data': data, 'append': append ?? false},
    );
    if (map == null) {
      throw Exception('Unexpected empty response from `writeFileUriBytes`');
    }
    return SafNewFile.fromMap(map);
  }

  @override
  Future<SafWriteStreamInfo> startWriteStream(
    String treeUri,
    String fileName,
    String mime, {
    bool? overwrite,
    bool? append,
  }) async {
    final session = _nextSession().toString();
    final map = await methodChannel
        .invokeMapMethod<String, dynamic>('startWriteStream', {
          'treeUri': treeUri.toString(),
          'session': session,
          'fileName': fileName,
          'mime': mime,
          'overwrite': overwrite ?? false,
          'append': append ?? false,
        });
    if (map == null) {
      throw Exception('Unexpected empty response from `startWriteStream`');
    }
    final newFile = SafNewFile.fromMap(map);
    return SafWriteStreamInfo(session, newFile);
  }

  @override
  Future<SafWriteStreamInfo> startWriteFileUriStream(
    String fileUri, {
    bool? append,
  }) async {
    final session = _nextSession().toString();
    // This calls the same native method as `startWriteStream`, but with a different set of parameters.
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'startWriteStream',
      {
        'fileUri': fileUri.toString(),
        'session': session,
        'append': append ?? false,
      },
    );
    if (map == null) {
      throw Exception(
        'Unexpected empty response from `startWriteFileUriStream`',
      );
    }
    final newFile = SafNewFile.fromMap(map);
    return SafWriteStreamInfo(session, newFile);
  }

  @override
  Future<void> writeChunk(String session, Uint8List data) async {
    // Direct JNI call -- this is what used to be one `invokeMethod` per
    // chunk. For a multi-MB file written in, say, 64KB chunks that's
    // hundreds of MethodChannel round trips avoided.
    SafStreamJniIo.writeChunk(session, data);
  }

  @override
  Future<void> endWriteStream(String session) async {
    SafStreamJniIo.endWrite(session);
  }

  // `_customBufferSizes` remembers the bufferSize passed to
  // startReadCustomFileStream, since readCustomFileStreamChunk no longer
  // takes one per call (it just asks JNI for "the next chunk").
  final _customBufferSizes = <String, int>{};

  @override
  Future<String> startReadCustomFileStream(
    String uri, {
    int? bufferSize,
  }) async {
    final session = _nextSession().toString();
    final effectiveBufferSize = bufferSize ?? (4 * 1024 * 1024);
    // Setup-only MethodChannel call: opens the stream and registers it under
    // `session`. Subsequent chunk reads go straight through JNI.
    await methodChannel.invokeMethod<String>('startReadCustomFileStream', {
      'fileUri': uri.toString(),
      'session': session,
    });
    _customBufferSizes[session] = effectiveBufferSize;
    return session;
  }

  @override
  Future<Uint8List?> readCustomFileStreamChunk(String session) async {
    final bufferSize = _customBufferSizes[session] ?? (4 * 1024 * 1024);
    return SafStreamJniIo.readCustomChunk(session, bufferSize);
  }

  @override
  Future<int> skipCustomFileStreamChunk(String session, int count) async {
    return SafStreamJniIo.skip(session, count);
  }

  @override
  Future<void> endReadCustomFileStream(String session) async {
    _customBufferSizes.remove(session);
    SafStreamJniIo.endRead(session);
  }

  int _nextSession() {
    return ++_session;
  }
}
