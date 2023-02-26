import 'dart:typed_data';

import 'package:saf_stream/saf_stream_method_channel.dart';

import 'saf_stream_platform_interface.dart';

class SafStream {
  Future<Stream<Uint8List>> readFile(String uri, {int? bufferSize}) async {
    return SafStreamPlatform.instance.readFile(uri, bufferSize: bufferSize);
  }

  Future<SafWriteStreamInfo> startWriteStream(
      String treeUri, String fileName, String mime) async {
    return SafStreamPlatform.instance.startWriteStream(treeUri, fileName, mime);
  }

  Future<void> writeChunk(String session, Uint8List data) async {
    return SafStreamPlatform.instance.writeChunk(session, data);
  }

  Future<void> endWriteStream(String session) async {
    return SafStreamPlatform.instance.endWriteStream(session);
  }
}
