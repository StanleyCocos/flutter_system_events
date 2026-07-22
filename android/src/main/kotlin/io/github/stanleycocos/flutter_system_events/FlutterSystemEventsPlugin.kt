package io.github.stanleycocos.flutter_system_events

import android.app.Activity
import android.app.Application
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.graphics.Rect
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
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
    private var appContext: Context? = null
    private var events: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var initialized = false
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null
    private var keyboardListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    private var keyboardVisible = false
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var memoryCallbacks: ComponentCallbacks2? = null
    private var config = EventConfig.legacy()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
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
                config = EventConfig.from(call.arguments)
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
        appContext = null
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
        if (config.keyboard) startKeyboard()
        if (config.lifecycle) startLifecycle()
        if (config.network) startNetwork()
        if (config.memory) startMemory()
    }

    private fun stopAll() {
        stopKeyboard()
        stopLifecycle()
        stopNetwork()
        stopMemory()
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

    private fun startNetwork() {
        val manager = appContext?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) = emitNetwork(manager)
            override fun onLost(network: Network) = emitNetwork(manager)
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) = emitNetwork(manager)
        }
        manager.registerNetworkCallback(NetworkRequest.Builder().build(), callback)
        networkCallback = callback
        emitNetwork(manager)
    }

    private fun emitNetwork(manager: ConnectivityManager) {
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork)
        val online = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        val networkType = when {
            !online -> "none"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            else -> "other"
        }
        events?.success(mapOf("type" to "network", "online" to online, "networkType" to networkType))
    }

    private fun stopNetwork() {
        val manager = appContext?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        networkCallback?.let { manager?.unregisterNetworkCallback(it) }
        networkCallback = null
    }

    private fun startMemory() {
        val context = appContext ?: return
        val callbacks = object : ComponentCallbacks2 {
            override fun onLowMemory() = emitMemory("low", 0)
            override fun onTrimMemory(level: Int) = emitMemory("trim", level)
            override fun onConfigurationChanged(newConfig: Configuration) {}
        }
        context.registerComponentCallbacks(callbacks)
        memoryCallbacks = callbacks
    }

    private fun emitMemory(state: String, level: Int) {
        events?.success(mapOf("type" to "memory", "state" to state, "level" to level))
    }

    private fun stopMemory() {
        memoryCallbacks?.let { appContext?.unregisterComponentCallbacks(it) }
        memoryCallbacks = null
    }

    private data class EventConfig(
        val keyboard: Boolean,
        val lifecycle: Boolean,
        val network: Boolean,
        val memory: Boolean,
        val battery: Boolean,
    ) {
        companion object {
            fun legacy() = EventConfig(
                keyboard = true,
                lifecycle = true,
                network = true,
                memory = true,
                battery = false,
            )

            fun from(arguments: Any?): EventConfig {
                val map = arguments as? Map<*, *> ?: return legacy()
                return EventConfig(
                    keyboard = map["keyboard"] == true,
                    lifecycle = map["lifecycle"] == true,
                    network = map["network"] == true,
                    memory = map["memory"] == true,
                    battery = map["battery"] == true,
                )
            }
        }
    }
}
