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
import java.io.FileInputStream
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
            "readFileStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        // Arguments are enforced on dart side.
                        val fileUriStr = call.argument<String>("fileUri")!!
                        val session = call.argument<String>("session")!!
                        val bufferSize = call.argument<Int>("bufferSize") ?: (4 * 1024 * 1024)
                        val start = call.argument<Int>("start")


                        val inStream =
                            context.contentResolver.openInputStream(Uri.parse(fileUriStr))
                                ?: throw Exception("Stream creation failed")
                        launch(Dispatchers.Main) {
                            val streamHandler = ReadFileHandler(inStream, bufferSize, start)
                            val channelName = "saf_stream/readFile/$session"
                            EventChannel(
                                pluginBinding?.binaryMessenger,
                                channelName
                            ).setStreamHandler(
                                streamHandler
                            )

                            result.success(channelName)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("ReadFileError", err.message, null)
                        }
                    }
                }
            }

            "copyToLocalFile" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    val fileUriStr = Uri.parse(call.argument<String>("src")!!)
                    val dest = call.argument<String>("dest")!!

                    val inputStream = context.contentResolver.openInputStream(fileUriStr)
                    val outputStream = FileOutputStream(File(dest))
                    outputStream.use { inputStream?.copyTo(it) }
                    inputStream?.close()
                    launch(Dispatchers.Main) {
                        result.success(null)
                    }
                }
            }


            "readFileSync" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    val fileUriStr = Uri.parse(call.argument<String>("fileUri")!!)
                    val start = call.argument<Int>("start")
                    val count = call.argument<Int>("count")

                    val bytes = context.contentResolver.openInputStream(fileUriStr)?.use {
                        if (start != null) {
                            it.skip(start.toLong())
                        }
                        if (count != null) {
                            val buffer = ByteArray(count)
                            val read = it.read(buffer, 0, count)
                            if (read <= 0) {
                                ByteArray(0)
                            } else {
                                buffer.copyOf(read)
                            }
                        } else {
                            it.buffered().readBytes()
                        }
                    }
                    launch(Dispatchers.Main) {
                        result.success(bytes)
                    }
                }
            }

            "pasteLocalFile" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        // Arguments are enforced on dart side.
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val fileName = call.argument<String>("fileName")!!
                        val mime = call.argument<String>("mime")!!
                        val localSrc = call.argument<String>("localSrc")!!
                        val overwrite = call.argument<Boolean>("overwrite")!!

                        val dir = DocumentFile.fromTreeUri(context, Uri.parse(treeUriStr))
                            ?: throw Exception("Directory not found")

                        val (newFile, outStream) = _createFile(dir, fileName, mime, overwrite)
                        val inStream = FileInputStream(File(localSrc))

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        outStream.use { inStream.copyTo(it) }
                        launch(Dispatchers.Main) {
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("StartWriteStream", err.message, null)
                        }
                    }
                }
            }

            "writeFileSync" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val fileName = call.argument<String>("fileName")!!
                        val mime = call.argument<String>("mime")!!
                        val data = call.argument<ByteArray>("data")!!
                        val overwrite = call.argument<Boolean>("overwrite")!!
                        val dir = DocumentFile.fromTreeUri(context, Uri.parse(treeUriStr))
                            ?: throw Exception("Directory not found")

                        val (newFile, outStream) = _createFile(dir, fileName, mime, overwrite)

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        outStream.use { it.write(data) }
                        launch(Dispatchers.Main) {
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("StartWriteStream", err.message, null)
                        }
                    }
                }
            }

            "startWriteStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        // Arguments are enforced on dart side.
                        val treeUriStr = call.argument<String>("treeUri")!!
                        val fileName = call.argument<String>("fileName")!!
                        val mime = call.argument<String>("mime")!!
                        val session = call.argument<String>("session")!!
                        val overwrite = call.argument<Boolean>("overwrite")!!

                        val dir = DocumentFile.fromTreeUri(context, Uri.parse(treeUriStr))
                            ?: throw Exception("Directory not found")
                        val (newFile, outStream) = _createFile(dir, fileName, mime, overwrite)

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        launch(Dispatchers.Main) {
                            // Access `writeStreams` in main thread.
                            writeStreams[session] = outStream
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("StartWriteStream", err.message, null)
                        }
                    }
                }
            }

            "writeChunk" -> {
                val session = call.argument<String>("session")!!
                // Access `writeStreams` in main thread.
                val outStream = writeStreams[session]
                if (outStream == null) {
                    result.error("WriteChunk", "Stream not found", null)
                } else {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val data = call.argument<ByteArray>("data")!!
                            outStream.write(data)
                            launch(Dispatchers.Main) { result.success(null) }
                        } catch (err: Exception) {
                            result.error("WriteChunk", err.message, null)
                        }
                    }
                }
            }

            "endWriteStream" -> {
                val session = call.argument<String>("session")!!
                // Access `writeStreams` in main thread.
                val outStream = writeStreams[session]
                if (outStream == null) {
                    result.error("WriteChunk", "Stream not found", null)
                } else {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            outStream.close()
                            launch(Dispatchers.Main) { result.success(null) }
                        } catch (err: Exception) {
                            launch(Dispatchers.Main) { result.error("CloseWriteStreamError", err.message, null) }
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun _createFile(dir: DocumentFile, fileName: String, mime: String, overwrite: Boolean) : Pair<DocumentFile, OutputStream> {
        val outStream: OutputStream
        val newFile: DocumentFile
        if (overwrite) {
            val curFile = dir.findFile(fileName)
            newFile = curFile ?: dir.createFile(mime, fileName) ?: throw Exception("File creation failed")
            outStream = context.contentResolver.openOutputStream(newFile.uri, "wt")
                ?: throw Exception("Stream creation failed")
        } else {
            newFile = dir.createFile(mime, fileName)
                ?: throw Exception("File creation failed")
            outStream = context.contentResolver.openOutputStream(newFile.uri)
                ?: throw Exception("Stream creation failed")
        }
        return Pair(newFile, outStream)
    }
}

class ReadFileHandler constructor(
        val inStream: InputStream,
        val bufferSize: Int,
        val start: Int?
) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(p0: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val buffer = ByteArray(bufferSize)
                inStream.use { stream ->
                    if (start != null) {
                        stream.skip(start.toLong())
                    }
                    var rc: Int = stream.read(buffer)
                    while (rc != -1) {
                        val chunk = buffer.copyOf(rc)
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
