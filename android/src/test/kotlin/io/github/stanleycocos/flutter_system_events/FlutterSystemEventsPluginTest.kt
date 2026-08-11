package io.github.stanleycocos.flutter_system_events

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import android.content.Intent
import android.os.PowerManager
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
        assertEquals(mapOf("type" to "screen", "change" to "off"), screenEventFromAction(Intent.ACTION_SCREEN_OFF))
    }

    @Test
    fun screenChangeFromAction_mapsScreenOn() {
        assertEquals("on", screenChangeFromAction(Intent.ACTION_SCREEN_ON))
        assertEquals(mapOf("type" to "screen", "change" to "on"), screenEventFromAction(Intent.ACTION_SCREEN_ON))
    }

    @Test
    fun screenChangeFromAction_mapsUserPresent() {
        assertEquals("unlocked", screenChangeFromAction(Intent.ACTION_USER_PRESENT))
        assertEquals(mapOf("type" to "screen", "change" to "unlocked"), screenEventFromAction(Intent.ACTION_USER_PRESENT))
    }

    @Test
    fun normalizedBrightness_convertsAndroidBrightnessRange() {
        assertEquals(0.0, normalizedBrightness(0))
        assertEquals(128.0 / 255.0, normalizedBrightness(128))
        assertEquals(1.0, normalizedBrightness(255))
        assertEquals(1.0, normalizedBrightness(300))
        assertNull(normalizedBrightness(-1))
    }

    @Test
    fun screenBrightnessEvent_buildsBrightnessPayloads() {
        assertEquals(
            mapOf("type" to "screen", "change" to "brightness", "brightness" to 128.0 / 255.0),
            screenBrightnessEvent(128),
        )
        assertNull(screenBrightnessEvent(-1))
    }

    @Test
    fun screenshotEvent_buildsScreenshotPayload() {
        assertEquals(mapOf("type" to "screenshot"), screenshotEvent())
    }

    @Test
    fun networkSnapshot_comparesConnectivityStateOnly() {
        assertEquals(
            NetworkSnapshot(mapOf("type" to "network", "online" to true, "networkType" to "wifi")),
            NetworkSnapshot(mapOf("type" to "network", "online" to true, "networkType" to "wifi")),
        )
    }

    @Test
    fun batterySnapshot_comparesBatteryStateOnly() {
        assertEquals(
            BatterySnapshot(mapOf("type" to "battery", "level" to 100, "charging" to true, "state" to "full")),
            BatterySnapshot(mapOf("type" to "battery", "level" to 100, "charging" to true, "state" to "full")),
        )
    }

    @Test
    fun thermalSnapshot_comparesThermalStateOnly() {
        assertEquals(
            ThermalSnapshot(mapOf("type" to "thermal", "state" to "nominal")),
            ThermalSnapshot(mapOf("type" to "thermal", "state" to "nominal")),
        )
    }

    @Test
    fun thermalStatusName_mapsAndroidThermalStatuses() {
        assertEquals("nominal", thermalStatusName(PowerManager.THERMAL_STATUS_NONE))
        assertEquals("fair", thermalStatusName(PowerManager.THERMAL_STATUS_LIGHT))
        assertEquals("fair", thermalStatusName(PowerManager.THERMAL_STATUS_MODERATE))
        assertEquals("serious", thermalStatusName(PowerManager.THERMAL_STATUS_SEVERE))
        assertEquals("critical", thermalStatusName(PowerManager.THERMAL_STATUS_CRITICAL))
        assertEquals("emergency", thermalStatusName(PowerManager.THERMAL_STATUS_EMERGENCY))
        assertEquals("shutdown", thermalStatusName(PowerManager.THERMAL_STATUS_SHUTDOWN))
        assertEquals("unknown", thermalStatusName(-1))
    }

    @Test
    fun thermalEvent_buildsThermalPayload() {
        assertEquals(
            mapOf("type" to "thermal", "state" to "serious"),
            thermalEvent(PowerManager.THERMAL_STATUS_SEVERE),
        )
    }

    @Test
    fun eventConfig_parsesScreenshotFlag() {
        assertEquals(false, FlutterSystemEventsPlugin.EventConfig.legacy().screenshot)
        assertEquals(
            true,
            FlutterSystemEventsPlugin.EventConfig.from(mapOf("screenshot" to true)).screenshot,
        )
        assertEquals(
            false,
            FlutterSystemEventsPlugin.EventConfig.from(mapOf("screenshot" to false)).screenshot,
        )
    }

    @Test
    fun eventConfig_parsesThermalFlag() {
        assertEquals(false, FlutterSystemEventsPlugin.EventConfig.legacy().thermal)
        assertEquals(
            true,
            FlutterSystemEventsPlugin.EventConfig.from(mapOf("thermal" to true)).thermal,
        )
        assertEquals(
            false,
            FlutterSystemEventsPlugin.EventConfig.from(mapOf("thermal" to false)).thermal,
        )
    }

    @Test
    fun logicalPixelsFromPhysicalPixels_convertsAndroidPixelsToLogicalPixels() {
        assertEquals(100.0, logicalPixelsFromPhysicalPixels(300, 3.0f))
        assertEquals(100.0, logicalPixelsFromPhysicalPixels(250, 2.5f))
        assertEquals(200.0, logicalPixelsFromPhysicalPixels(150, 0.75f))
        assertEquals(0.0, logicalPixelsFromPhysicalPixels(0, 3.0f))
        assertEquals(300.0, logicalPixelsFromPhysicalPixels(300, 0.0f))
    }
}
