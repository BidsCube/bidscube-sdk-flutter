package com.bidscube.bidscube_sdk_flutter

import android.content.Context
import android.view.View
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for creating native ad views in Flutter
 *
 * This factory is registered with Flutter to allow rendering native Android
 * ad views created by the Bidscube SDK within Flutter layouts.
 */
class BidscubeAdViewFactory(private val viewRegistry: MutableMap<String, View>) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        val viewKey = creationParams?.get("viewKey") as? String

        return BidscubeAdPlatformView(context, viewId, viewKey, viewRegistry)
    }
}

/**
 * Platform view wrapper for native Bidscube ad views
 */
class BidscubeAdPlatformView(
    private val context: Context,
    private val viewId: Int,
    private val viewKey: String?,
    private val viewRegistry: MutableMap<String, View>
) : PlatformView {

    private var nativeView: View? = null

    init {
        // Retrieve the cached view from the registry
        nativeView = if (!viewKey.isNullOrEmpty()) {
            viewRegistry[viewKey]
        } else {
            null
        }

        if (nativeView == null) {
            // Fallback: create a placeholder view if not found
            nativeView = View(context).apply {
                setBackgroundColor(android.graphics.Color.LTGRAY)
            }
        }
    }

    override fun getView(): View = nativeView ?: View(context)

    override fun dispose() {
        // Clean up resources if needed
        if (!viewKey.isNullOrEmpty()) {
            viewRegistry.remove(viewKey)
        }
    }
}

