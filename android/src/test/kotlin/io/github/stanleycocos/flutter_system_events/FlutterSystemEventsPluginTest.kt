package io.github.stanleycocos.flutter_system_events

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import android.content.Intent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

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

    @Test
    fun orientationNameFromRotation_mapsAndroidRotations() {
        assertEquals("portraitUp", orientationNameFromRotation(0))
        assertEquals("landscapeLeft", orientationNameFromRotation(1))
        assertEquals("portraitDown", orientationNameFromRotation(2))
        assertEquals("landscapeRight", orientationNameFromRotation(3))
        assertEquals("unknown", orientationNameFromRotation(-1))
    }

    @Test
    fun timeReasonFromAction_mapsAndroidActions() {
        assertEquals("timeChanged", timeReasonFromAction("android.intent.action.TIME_SET"))
        assertEquals("timezoneChanged", timeReasonFromAction("android.intent.action.TIMEZONE_CHANGED"))
        assertEquals("dateChanged", timeReasonFromAction("android.intent.action.DATE_CHANGED"))
        assertEquals("unknown", timeReasonFromAction(null))
    }

    @Test
    fun screenChangeFromAction_mapsScreenOff() {
        assertEquals("off", screenChangeFromAction(Intent.ACTION_SCREEN_OFF))
    }

    @Test
    fun screenChangeFromAction_mapsScreenOn() {
        assertEquals("on", screenChangeFromAction(Intent.ACTION_SCREEN_ON))
    }

    @Test
    fun screenChangeFromAction_mapsUserPresent() {
        assertEquals("unlocked", screenChangeFromAction(Intent.ACTION_USER_PRESENT))
    }

    @Test
    fun normalizedBrightness_convertsAndroidBrightnessRange() {
        assertEquals(0.0, normalizedBrightness(0))
        assertEquals(128.0 / 255.0, normalizedBrightness(128))
        assertEquals(1.0, normalizedBrightness(255))
        assertEquals(1.0, normalizedBrightness(300))
        assertNull(normalizedBrightness(-1))
    }
}
