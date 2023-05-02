package com.fluttercavalry.saf_stream

import android.content.Context
import android.net.Uri
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

/** SafStreamPlugin */
class SafStreamPlugin : FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
  private var writeStreams = mutableMapOf<String, OutputStream>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    pluginBinding = flutterPluginBinding
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "saf_stream")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "readFile" -> {
        // Arguments are enforced on dart side.
        val fileUriStr = call.argument<String>("fileUri")!!
        val session = call.argument<String>("session")!!
        var bufferSize = call.argument<Int>("bufferSize") ?: 4 * 1024 * 1024

        try {
          val inStream = context.contentResolver.openInputStream(Uri.parse(fileUriStr))
            ?: throw Exception("Stream creation failed")
          var streamHandler = ReadFileHandler(inStream, bufferSize)
          val channelName = "saf_stream/readFile/$session"
          EventChannel(pluginBinding?.binaryMessenger, channelName).setStreamHandler(streamHandler)

          result.success(channelName)
        } catch (err: Exception) {
          result.error("ReadFileError", err.message, null)
        }
      }

      "readFileToLocal" -> {
        val fileUriStr = Uri.parse(call.argument<String>("src")!!)
        val dest = call.argument<String>("dest")!!

        CoroutineScope(Dispatchers.IO).launch {
          val inputStream = context.contentResolver.openInputStream(fileUriStr)
          val outputStream = FileOutputStream(File(dest))
          outputStream?.let { inputStream?.copyTo(it) }
          launch(Dispatchers.Main) {
            result.success(null)
          }
        }
      }

      "startWriteStream" -> {
        try {
          // Arguments are enforced on dart side.
          val treeUriStr = call.argument<String>("treeUri")!!
          val fileName = call.argument<String>("fileName")!!
          val mime = call.argument<String>("mime")!!
          val session = call.argument<String>("session")!!

          val dir = DocumentFile.fromTreeUri(context, Uri.parse(treeUriStr))
            ?: throw Exception("Directory not found")

          var fileUri = dir.findFile(fileName) ?: dir.createFile(mime, fileName) ?: throw Exception("File creation failed")
          var outStream = context.contentResolver.openOutputStream(fileUri.uri, "wt")
            ?: throw Exception("Stream creation failed")
          writeStreams[session] = outStream

          result.success(fileUri.uri.toString())
        } catch (err: Exception) {
          result.error("StartWriteStream", err.message, null)
        }
      }
      "writeChunk" -> {
        try {
          // Arguments are enforced on dart side.
          val session = call.argument<String>("session")!!
          var data = call.argument<ByteArray>("data")!!

          var outStream = writeStreams[session]
          if (outStream == null) {
            result.error("WriteChunk", "Stream not found", null)
            return
          }

          CoroutineScope(Dispatchers.IO).launch {
            try {
              outStream.write(data)
              launch(Dispatchers.Main) { result.success(null) }
            } catch (err: Exception) {
              launch(Dispatchers.Main) { result.error("WriteFileChunkError", err.message, null) }
            }
          }
        } catch (err: Exception) {
          result.error("WriteChunk", err.message, null)
        }
      }
      "endWriteStream" -> {
        try {
          // Arguments are enforced on dart side.
          val session = call.argument<String>("session")!!

          var outStream = writeStreams[session]
          if (outStream == null) {
            result.error("EndWriteStream", "Stream not found", null)
            return
          }

          CoroutineScope(Dispatchers.IO).launch {
            try {
              outStream.close()
              launch(Dispatchers.Main) { result.success(null) }
            } catch (err: Exception) {
              launch(Dispatchers.Main) { result.error("CloseWriteStreamError", err.message, null) }
            }
          }
        } catch (err: Exception) {
          result.error("EndWriteStream", err.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

class ReadFileHandler constructor(
  val inStream: InputStream,
  val bufferSize: Int
) : EventChannel.StreamHandler {
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(p0: Any?, sink: EventChannel.EventSink) {
    eventSink = sink
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val buffer = ByteArray(bufferSize)
        inStream.use { stream ->
          var rc: Int = stream.read(buffer)
          while (rc != -1) {
            var chunk = buffer.copyOf(rc)
            launch(Dispatchers.Main) { sink.success(chunk) }
            rc = stream.read(buffer)
          }
          launch(Dispatchers.Main) { sink.endOfStream() }
        }
      } catch (err: Exception) {
        launch(Dispatchers.Main) { sink.error("ReadFileError", err.message, null) }
      }
    }
  }

  override fun onCancel(p0: Any?) {
    eventSink = null
  }
}
