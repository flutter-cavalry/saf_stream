import 'dart:async';
import 'dart:typed_data';

import 'package:jni/jni.dart';


///    `JStaticMethodId`s are resolved once and cached (`static final`,
///    matching the pattern package:jni's own generated bindings use in
///    `core_bindings.dart`), not re-resolved with `staticMethodId(...)` on
///    every chunk. `GetStaticMethodID` is a reflective symbol-table lookup;
///    at a 64 KB chunk size against a 100 MB file that's ~1600 lookups per
///    direction that were previously happening on every single call.
class SafStreamJniIo {
  SafStreamJniIo._();

  static final JClass _class =
      JClass.forName('com/fluttercavalry/saf_stream/SafStreamJni');

  static final _idReadChunk =
      _class.staticMethodId('readChunk', '(Ljava/lang/String;I)[B');
  static final _idSkipInput =
      _class.staticMethodId('skipInput', '(Ljava/lang/String;J)J');
  static final _idCloseInputStream =
      _class.staticMethodId('closeInputStream', '(Ljava/lang/String;)V');
  static final _idWriteChunk =
      _class.staticMethodId('writeChunk', '(Ljava/lang/String;[B)V');
  static final _idCloseOutputStream =
      _class.staticMethodId('closeOutputStream', '(Ljava/lang/String;)V');
  static final _idReadFileBytes = _class.staticMethodId(
      'readFileBytes', '(Ljava/lang/String;JI)[B');

  static Uint8List _readChunk(String session, int length) {
    final jSession = session.toJString();
    try {
      final jResult = _idReadChunk.call(
        _class,
        JByteArray.type,
        [jSession, length],
      );
      try {
        return _toUint8List(jResult);
      } finally {
        jResult.release();
      }
    } finally {
      jSession.release();
    }
  }

  /// Pull-based chunked read. Replaces the old EventChannel-pushed stream:
  /// Dart now asks for chunks in a loop instead of native code pushing
  /// them, which also means reads can be paused/cancelled without extra
  /// plumbing (just stop calling readChunk).
  static Stream<Uint8List> readStream(
    String session, {
    required int bufferSize,
  }) {
    late StreamController<Uint8List> controller;
    var cancelled = false;

    Future<void> pump() async {
      try {
        while (!cancelled) {
          final chunk = _readChunk(session, bufferSize);
          if (chunk.isEmpty) break;
          controller.add(chunk);
        }
      } catch (err, st) {
        if (!cancelled) controller.addError(err, st);
      } finally {
        if (!cancelled) await controller.close();
        endRead(session);
      }
    }

    controller = StreamController<Uint8List>(
      onListen: () {
        unawaited(pump());
      },
      onCancel: () {
        cancelled = true;
      },
    );
    return controller.stream;
  }

  /// Single chunk pull, used by the `startReadCustomFileStream` /
  /// `readCustomFileStreamChunk` family. Returns null at EOF.
  static Uint8List? readCustomChunk(String session, int bufferSize) {
    final chunk = _readChunk(session, bufferSize);
    return chunk.isEmpty ? null : chunk;
  }

  static int skip(String session, int count) {
    final jSession = session.toJString();
    try {
      return _idSkipInput.call(_class, jlong.type, [jSession, count]);
    } finally {
      jSession.release();
    }
  }

  static void endRead(String session) {
    final jSession = session.toJString();
    try {
      _idCloseInputStream.call(_class, jvoid.type, [jSession]);
    } finally {
      jSession.release();
    }
  }

  static void writeChunk(String session, Uint8List data) {
    final jSession = session.toJString();
    final jData = JByteArray.from(data);
    try {
      _idWriteChunk.call(_class, jvoid.type, [jSession, jData]);
    } finally {
      jSession.release();
      jData.release();
    }
  }

  static void endWrite(String session) {
    final jSession = session.toJString();
    try {
      _idCloseOutputStream.call(_class, jvoid.type, [jSession]);
    } finally {
      jSession.release();
    }
  }

  static Uint8List readFileBytes(String uri, {required int start, required int count}) {
    final jUri = uri.toJString();
    try {
      final jResult = _idReadFileBytes.call(
        _class,
        JByteArray.type,
        [jUri, start, count],
      );
      try {
        return _toUint8List(jResult);
      } finally {
        jResult.release();
      }
    } finally {
      jUri.release();
    }
  }

  /// `JByteArray.getRange` returns an `Int8List` view over natively
  /// allocated (malloc'd) memory. Java `byte` and Dart's `Uint8List` are
  /// both single bytes with the same bit pattern (just a signed/unsigned
  /// read of it), so this reinterprets the same buffer instead of copying
  /// element-by-element -- the copy still has to happen once (native
  /// malloc'd memory can't be handed to the rest of Dart as-is), but this
  /// does it as a single `memcpy`-backed `Uint8List.fromList` on the
  /// underlying bytes rather than the signed/unsigned-aware element loop.
  static Uint8List _toUint8List(JByteArray jArray) {
    final n = jArray.length;
    if (n == 0) return Uint8List(0);
    final int8 = jArray.getRange(0, n);
    return Uint8List.fromList(int8.buffer.asUint8List(int8.offsetInBytes, n));
  }
}
