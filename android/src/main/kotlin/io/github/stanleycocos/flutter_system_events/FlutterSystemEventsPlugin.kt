package io.github.stanleycocos.flutter_system_events

import android.app.Activity
import android.app.Application
import android.graphics.Rect
import android.os.Bundle
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
    private var initialized = false
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null
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
                initialized = true
                startAll()
                result.success(null)
            }
            "dispose" -> {
                initialized = false
                stopAll()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopAll()
        initialized = false
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        events = eventSink
    }

    override fun onCancel(arguments: Any?) {
        events = null
        initialized = false
        stopAll()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (initialized) startAll()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        stopAll()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (initialized) startAll()
    }

    override fun onDetachedFromActivity() {
        stopAll()
        activity = null
    }

    private fun startAll() {
        stopAll()
        startKeyboard()
        startLifecycle()
    }

    private fun stopAll() {
        stopKeyboard()
        stopLifecycle()
    }

    private fun startLifecycle() {
        val currentActivity = activity ?: return
        val callbacks = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(activity: Activity) = emitLifecycle(activity, "resumed")
            override fun onActivityPaused(activity: Activity) = emitLifecycle(activity, "inactive")
            override fun onActivityStopped(activity: Activity) = emitLifecycle(activity, "paused")
            override fun onActivityDestroyed(activity: Activity) = emitLifecycle(activity, "detached")
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityCreated(activity: Activity, state: Bundle?) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
        }
        currentActivity.application.registerActivityLifecycleCallbacks(callbacks)
        lifecycleCallbacks = callbacks
    }

    private fun emitLifecycle(source: Activity, state: String) {
        if (source == activity) events?.success(mapOf("type" to "lifecycle", "state" to state))
    }

    private fun stopLifecycle() {
        val currentActivity = activity
        lifecycleCallbacks?.let { currentActivity?.application?.unregisterActivityLifecycleCallbacks(it) }
        lifecycleCallbacks = null
    }

    private fun startKeyboard() {
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
