package com.hiddify.hiddify

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.intercom.android.sdk.Intercom

class IntercomHandler : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    companion object {
        const val CHANNEL_NAME = "com.hiddify.app/intercom"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "displayMessenger" -> {
                Intercom.client().displayMessenger()
                result.success(true)
            }
            "displayHelpCenter" -> {
                Intercom.client().displayHelpCenter()
                result.success(true)
            }
            "displayLauncher" -> {
                Intercom.client().setLauncherVisibility(Intercom.Visibility.VISIBLE)
                result.success(true)
            }
            "hideLauncher" -> {
                Intercom.client().setLauncherVisibility(Intercom.Visibility.GONE)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
