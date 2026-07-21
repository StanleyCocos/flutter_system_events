package com.example.flutter_system_events

import android.app.Activity
import android.graphics.Rect
import android.view.ViewTreeObserver
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterSystemEventsPlugin */
class FlutterSystemEventsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var events: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var keyboardListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    private var keyboardVisible = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_system_events")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_system_events/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "initialize" -> {
                startKeyboard()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopKeyboard()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        events = eventSink
    }

    override fun onCancel(arguments: Any?) {
        events = null
        stopKeyboard()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        stopKeyboard()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        stopKeyboard()
        activity = null
    }

    private fun startKeyboard() {
        stopKeyboard()
        val root = activity?.window?.decorView ?: return
        val listener = ViewTreeObserver.OnGlobalLayoutListener {
            val rect = Rect()
            root.getWindowVisibleDisplayFrame(rect)
            val height = root.rootView.height
            val keyboardHeight = (height - rect.bottom).coerceAtLeast(0)
            val visible = keyboardHeight > height * 0.15
            if (visible != keyboardVisible) {
                keyboardVisible = visible
                events?.success(
                    mapOf(
                        "type" to "keyboard",
                        "visible" to visible,
                        "height" to if (visible) keyboardHeight else 0,
                    ),
                )
            }
        }
        root.viewTreeObserver.addOnGlobalLayoutListener(listener)
        keyboardListener = listener
    }

    private fun stopKeyboard() {
        val root = activity?.window?.decorView
        keyboardListener?.let { root?.viewTreeObserver?.removeOnGlobalLayoutListener(it) }
        keyboardListener = null
        keyboardVisible = false
    }
}
