package com.fluttercavalry.saf_stream

import android.content.Context
import androidx.core.net.toUri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

/** SafStreamPlugin */
class SafStreamPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = flutterPluginBinding
        context = flutterPluginBinding.applicationContext
        // Hand the Android Context to the JNI bridge so methods called
        // directly from Dart (bypassing this MethodChannel) can still reach
        // the ContentResolver.
        SafStreamJni.appContext = context
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "saf_stream")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "readFileStream" -> {
                // Only opens the stream and registers it with the JNI bridge
                // under `session`. Actual chunk reads happen via direct JNI
                // calls to `SafStreamJni.readChunk` from Dart, not through an
                // EventChannel. This avoids one BinaryMessenger round trip
                // per chunk.
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val fileUriStr = call.argument<String>("fileUri")!!
                        val session = call.argument<String>("session")!!
                        val start = (call.argument<Number>("start")?.toLong()) ?: 0L

                        val inStream =
                            context.contentResolver.openInputStream(fileUriStr.toUri())
                                ?: throw Exception("Stream creation failed")
                        if (start != 0L) {
                            inStream.skip(start)
                        }
                        SafStreamJni.registerInputStream(session, inStream)
                        launch(Dispatchers.Main) {
                            result.success(session)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "copyToLocalFile" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val fileUriStr = call.argument<String>("src")!!.toUri()
                        val dest = call.argument<String>("dest")!!
                        val inputStream = context.contentResolver.openInputStream(fileUriStr)
                        inputStream?.use { input ->
                            val file = File(dest)
                            file.outputStream().use { output ->
                                input.buffered().copyTo(output)
                            }
                        }
                        result.success(null)
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "readFileBytes" -> {
                // Note: this path is also directly callable from Dart via JNI
                // (`SafStreamJni.readFileBytes`), skipping this MethodChannel
                // entirely. It's kept here too so the plugin still works for
                // any caller that only wired up the MethodChannel side (e.g.
                // during a partial migration, or on hosts where the JNI
                // plugin failed to initialize).
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val fileUriStr = call.argument<String>("fileUri")!!
                        val start = (call.argument<Number>("start")?.toLong()) ?: 0L
                        val count = call.argument<Int>("count") ?: -1

                        val bytes = SafStreamJni.readFileBytes(fileUriStr, start, count)
                        launch(Dispatchers.Main) {
                            result.success(bytes)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
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
                        val append = call.argument<Boolean>("append")!!

                        val dir =
                            DocumentFile.fromTreeUri(context, treeUriStr.toUri())
                                ?: throw Exception("Directory not found")

                        val (newFile, outStream) = createOutStreamFromDir(dir, fileName, mime, overwrite, append)
                        val inStream = FileInputStream(File(localSrc))

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        inStream.use { input ->
                            outStream.use { output ->
                                input.copyTo(output)
                            }
                        }

                        launch(Dispatchers.Main) {
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "writeFileBytes" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")
                        val fileName = call.argument<String>("fileName")
                        val fileUri = call.argument<String>("fileUri")
                        val mime = call.argument<String>("mime")?:""
                        val data = call.argument<ByteArray>("data")!!
                        val overwrite = call.argument<Boolean>("overwrite")?:false
                        val append = call.argument<Boolean>("append")?:false

                        val (newFile, outStream) = createOutStreamFromFileOrDir(fileUri, treeUriStr, fileName, mime, overwrite, append)

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        outStream.use { it.write(data) }
                        launch(Dispatchers.Main) {
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "startWriteStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")
                        val fileName = call.argument<String>("fileName")
                        val fileUri = call.argument<String>("fileUri")
                        val mime = call.argument<String>("mime")?:""
                        val session = call.argument<String>("session")!!
                        val overwrite = call.argument<Boolean>("overwrite")?:false
                        val append = call.argument<Boolean>("append")?:false

                        val (newFile, outStream) = createOutStreamFromFileOrDir(fileUri, treeUriStr, fileName, mime, overwrite, append)

                        val map = HashMap<String, Any?>()
                        map["uri"] = newFile.uri.toString()
                        map["fileName"] = newFile.name

                        SafStreamJni.registerOutputStream(session, outStream)
                        launch(Dispatchers.Main) {
                            result.success(map)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            // `writeChunk` and `endWriteStream` are no longer called from
            // Dart in the normal path -- Dart calls `SafStreamJni.writeChunk`
            // / `SafStreamJni.closeOutputStream` directly via JNI instead, to
            // avoid one MethodChannel round trip per chunk. These handlers
            // are kept as a MethodChannel-only fallback.
            "writeChunk" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val session = call.argument<String>("session")!!
                        val data = call.argument<ByteArray>("data")!!
                        SafStreamJni.writeChunk(session, data)
                        launch(Dispatchers.Main) { result.success(null) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "endWriteStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val session = call.argument<String>("session")!!
                        SafStreamJni.closeOutputStream(session)
                        launch(Dispatchers.Main) { result.success(null) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("CloseWriteStreamError", err.message, null)
                        }
                    }
                }
            }

            // The custom-read-stream family shares the exact same registry as
            // `readFileStream` now (`SafStreamJni.inputStreams`), keyed by
            // session. `readCustomFileStreamChunk` / `skipCustomFileStreamChunk`
            // / `endReadCustomFileStream` are no longer called from Dart in
            // the normal path -- Dart calls `SafStreamJni.readChunk` /
            // `skipInput` / `closeInputStream` directly via JNI. These
            // handlers remain as a MethodChannel-only fallback.
            "startReadCustomFileStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val fileUriStr = call.argument<String>("fileUri")!!
                        val session = call.argument<String>("session")!!

                        val inStream =
                            context.contentResolver.openInputStream(fileUriStr.toUri())
                                ?: throw Exception("Stream creation failed")
                        SafStreamJni.registerInputStream(session, inStream)
                        launch(Dispatchers.Main) { result.success(null) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "readCustomFileStreamChunk" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val session = call.argument<String>("session")!!
                        val bufferSize = call.argument<Int>("bufferSize") ?: (4 * 1024 * 1024)
                        val bytes = SafStreamJni.readChunk(session, bufferSize)
                        launch(Dispatchers.Main) {
                            result.success(if (bytes.isEmpty()) null else bytes)
                        }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "skipCustomFileStreamChunk" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val session = call.argument<String>("session")!!
                        val count = call.argument<Int>("count")!!
                        val skipped = SafStreamJni.skipInput(session, count.toLong())
                        launch(Dispatchers.Main) { result.success(skipped.toInt()) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("PluginError", err.message, null)
                        }
                    }
                }
            }

            "endReadCustomFileStream" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val session = call.argument<String>("session")!!
                        SafStreamJni.closeInputStream(session)
                        launch(Dispatchers.Main) { result.success(null) }
                    } catch (err: Exception) {
                        launch(Dispatchers.Main) {
                            result.error("CloseReadStreamError", err.message, null)
                        }
                    }
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun createOutStreamFromDir(
        dir: DocumentFile,
        fileName: String,
        mime: String,
        overwrite: Boolean,
        append: Boolean,
    ): Pair<DocumentFile, OutputStream> {
        val outStream: OutputStream
        val newFile: DocumentFile
        if (overwrite || append) {
            val curFile = dir.findFile(fileName)
            newFile =
                curFile ?: dir.createFile(mime, fileName)
                    ?: throw Exception("File creation failed at $fileName (createOutStream, overwrite=$overwrite, append=$append)")
            outStream = context.contentResolver.openOutputStream(newFile.uri, if (append) "wa" else "wt")
                ?: throw Exception("Stream creation failed at $fileName (createOutStream, overwrite=$overwrite, append=$append")
        } else {
            newFile = dir.createFile(mime, fileName)
                ?: throw Exception("File creation failed at $fileName (createOutStream, overwrite=0")
            outStream = context.contentResolver.openOutputStream(newFile.uri)
                ?: throw Exception("Stream creation failed at $fileName (createOutStream, overwrite=0")
        }
        return Pair(newFile, outStream)
    }

    private fun createOutStreamFromFileUri(
        fileUriStr: String,
        append: Boolean,
    ): Pair<DocumentFile, OutputStream> {
        val fileUri = fileUriStr.toUri()
        val newFile =
            DocumentFile.fromSingleUri(context, fileUri)
                ?: throw Exception("File not found at $fileUriStr (createOutStreamFromFileUri)")
        val outStream =
            context.contentResolver.openOutputStream(newFile.uri, if (append) "wa" else "wt")
                ?: throw Exception("Stream creation failed at $fileUriStr (createOutStreamFromFileUri, append=$append")
        return Pair(newFile, outStream)
    }

    private fun createOutStreamFromFileOrDir(
        fileUriStr: String?,
        treeUriStr: String?,
        fileName: String?,
        mime: String,
        overwrite: Boolean,
        append: Boolean,
    ): Pair<DocumentFile, OutputStream> =
        if (fileUriStr != null) {
            createOutStreamFromFileUri(fileUriStr, append)
        } else if (treeUriStr != null && fileName != null) {
            val dir =
                DocumentFile.fromTreeUri(context, treeUriStr.toUri())
                    ?: throw Exception("Directory not found at $treeUriStr (createOutStreamFromFileOrDir)")
            createOutStreamFromDir(dir, fileName, mime, overwrite, append)
        } else {
            throw Exception("Either fileUri or treeUri and fileName must be provided (createOutStreamFromFileOrDir)")
        }
}


