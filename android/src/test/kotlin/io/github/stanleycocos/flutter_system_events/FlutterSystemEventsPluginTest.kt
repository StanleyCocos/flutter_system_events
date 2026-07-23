package io.github.stanleycocos.flutter_system_events

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class FlutterSystemEventsPluginTest {
    @Test
    fun onMethodCall_initialize_returnsSuccess() {
        val plugin = FlutterSystemEventsPlugin()
        val call = MethodCall("initialize", null)
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).success(null)
    }

    @Test
    fun onMethodCall_dispose_returnsSuccess() {
        val plugin = FlutterSystemEventsPlugin()
        val call = MethodCall("dispose", null)
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).success(null)
    }

    @Test
    fun onMethodCall_unknown_returnsNotImplemented() {
        val plugin = FlutterSystemEventsPlugin()
        val call = MethodCall("unknown", null)
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).notImplemented()
    }
}
