package com.fluttercavalry.saf_stream

import android.content.Context
import androidx.annotation.Keep
import androidx.core.net.toUri
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.ConcurrentHashMap

/**
 * JNI-callable bridge used for the hot, byte-heavy read/write paths.
 *
 * Called directly from Dart at runtime via package:jni's low-level API
 * (`JClass.forName` + `staticMethodId` + `.call(...)`), NOT via jnigen
 * codegen -- same reasoning as before (jnigen can't resolve
 * `android.content.Context` etc. at codegen time; at runtime the JVM
 * already has these classes loaded, so reflective lookup sidesteps that).
 *
 * Payloads are now raw `ByteArray` ([B), not Base64 Strings. package:jni
 * has a documented type for this (`JByteArray`, source-verified in
 * pkgs/jni/lib/src/primitive_jarrays.dart: `JByteArray.of(Iterable<int>)`
 * to build one from Dart bytes, `.getRange(start, end)` to pull the bytes
 * back out) -- the byte[] marshalling this class previously avoided *is*
 * supported, it just isn't in the one hand-picked example on pub.dev.
 * Base64 was costing 33% extra bytes on the wire plus encode/decode CPU
 * on both sides, on top of transcoding a large String through JNI's
 * modified-UTF-8 twice per chunk. None of that is needed.
 */
@Keep
object SafStreamJni {
    @JvmStatic
    @Volatile
    var appContext: Context? = null

    private val inputStreams = ConcurrentHashMap<String, InputStream>()
    private val outputStreams = ConcurrentHashMap<String, OutputStream>()
    private val readBuffers = ConcurrentHashMap<String, ByteArray>()
    private val EMPTY = ByteArray(0)

    private fun ctx(): Context =
        appContext ?: throw IllegalStateException("SafStreamJni.appContext has not been initialized")

    // ---------------------------------------------------------------------
    // Reading
    // ---------------------------------------------------------------------

    fun registerInputStream(
        session: String,
        stream: InputStream,
    ) {
        inputStreams[session] = stream
    }

    /**
     * Reads up to [length] bytes from the stream registered under
     * [session]. Returns an empty (zero-length) array at EOF. Called
     * directly from Dart via JNI, in a loop -- this is the hot path.
     *
     * Reuses a per-session buffer instead of allocating a fresh `length`
     * -byte array on every call: at a 64 KB chunk size against a 100 MB
     * file that's ~1600 allocations (and matching GC churn) removed.
     */
    @JvmStatic
    fun readChunk(
        session: String,
        length: Int,
    ): ByteArray {
        val stream = inputStreams[session] ?: throw Exception("Read stream not found for session: $session")
        var buffer = readBuffers[session]
        if (buffer == null || buffer.size != length) {
            buffer = ByteArray(length)
            readBuffers[session] = buffer
        }
        val n = stream.read(buffer, 0, length)
        if (n <= 0) return EMPTY
        return if (n == length) buffer else buffer.copyOf(n)
    }

    /** Skips [count] bytes on the stream registered under [session]. */
    @JvmStatic
    fun skipInput(
        session: String,
        count: Long,
    ): Long {
        val stream = inputStreams[session] ?: throw Exception("Read stream not found for session: $session")
        return stream.skip(count)
    }

    /** Closes and unregisters the input stream for [session]. */
    @JvmStatic
    fun closeInputStream(session: String) {
        inputStreams.remove(session)?.close()
        readBuffers.remove(session)
    }

    /**
     * One-shot read (backs `readFileBytes`). Not chunked, so a plain JNI
     * call (no session bookkeeping) is enough; still skips the
     * MethodChannel codec round trip for what can be a very large payload.
     */
    @JvmStatic
    fun readFileBytes(
        uriStr: String,
        start: Long,
        count: Int,
    ): ByteArray {
        val stream =
            ctx().contentResolver.openInputStream(uriStr.toUri())
                ?: throw Exception("Failed to open input stream for $uriStr")
        stream.use {
            if (start > 0) {
                it.skip(start)
            }
            return if (count > 0) {
                val buffer = ByteArray(count)
                val n = it.read(buffer, 0, count)
                if (n <= 0) EMPTY else buffer.copyOf(n)
            } else {
                it.buffered().readBytes()
            }
        }
    }

    // ---------------------------------------------------------------------
    // Writing
    // ---------------------------------------------------------------------

    fun registerOutputStream(
        session: String,
        stream: OutputStream,
    ) {
        outputStreams[session] = stream
    }

    /**
     * Writes [data] to the stream registered under [session]. Called
     * directly from Dart via JNI, once per chunk -- this is the hot path
     * that used to be a `writeChunk` MethodChannel call per chunk.
     */
    @JvmStatic
    fun writeChunk(
        session: String,
        data: ByteArray,
    ) {
        val stream = outputStreams[session] ?: throw Exception("Write stream not found for session: $session")
        stream.write(data)
    }

    /** Flushes, closes and unregisters the output stream for [session]. */
    @JvmStatic
    fun closeOutputStream(session: String) {
        outputStreams.remove(session)?.let {
            it.flush()
            it.close()
        }
    }

    /** Used for cleanup if a session is abandoned (e.g. app killed mid-stream). */
    fun reset() {
        inputStreams.values.forEach { runCatching { it.close() } }
        outputStreams.values.forEach { runCatching { it.close() } }
        inputStreams.clear()
        outputStreams.clear()
        readBuffers.clear()
    }
}
