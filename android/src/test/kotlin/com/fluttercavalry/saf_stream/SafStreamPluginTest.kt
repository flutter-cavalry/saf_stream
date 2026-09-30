package com.fluttercavalry.saf_stream

import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import java.io.ByteArrayInputStream
import java.io.EOFException
import java.io.OutputStream
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class SafStreamPluginTest {
    @Test
    fun skipToOffset_handlesPartialSkips() {
        val stream =
            object : ByteArrayInputStream(byteArrayOf(10, 20, 30)) {
                override fun skip(n: Long): Long = super.skip(n.coerceAtMost(1L))
            }

        SafStreamJni.skipToOffset(stream, 2L)
        assertEquals(30, stream.read())
    }

    @Test
    fun skipToOffset_beyondEofLeavesStreamAtEof() {
        val stream = ByteArrayInputStream(byteArrayOf(10, 20))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            assertFailsWith<EOFException> {
                SafStreamJni.skipToOffset(stream, 3L)
            }
        } else {
            SafStreamJni.skipToOffset(stream, 3L)
            assertEquals(-1, stream.read())
        }
    }

    @Test
    fun reset_closesAllRegisteredStreams() {
        var inputClosed = false
        var outputClosed = false
        val inputStream =
            object : ByteArrayInputStream(byteArrayOf(1)) {
                override fun close() {
                    inputClosed = true
                }
            }
        val outputStream =
            object : OutputStream() {
                override fun write(value: Int) {}

                override fun close() {
                    outputClosed = true
                }
            }
        SafStreamJni.registerInputStream("input", inputStream)
        SafStreamJni.registerOutputStream("output", outputStream)

        SafStreamJni.reset()

        assertTrue(inputClosed)
        assertTrue(outputClosed)
    }

    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = SafStreamPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }
}
