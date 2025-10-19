package com.icmexpo.bmd_flutter_tools


import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.util.Log

// import com.twilio.verify_sna.ProcessUrlResult
// import com.twilio.verify_sna.TwilioVerifySna
import com.icmexpo.bmd_flutter_tools.BuildConfig


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import java.io.IOException

import kotlinx.coroutines.*
import kotlinx.serialization.*
import kotlinx.serialization.json.Json

import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response




/* =====================================================================================================================
 * MARK: Main Activity
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class MainActivity: FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)

        val context = getApplicationContext();

        /* -------------------------------------------------------------------------------------------------------------
         * MARK: Method Channel
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handles communication between Flutter and the platform
         */
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "icmMethodChannel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sna" -> {
                        // TODO: wire SNA flow; returning test value for now
                        result.success("test")
                    }

                    "getBuildTime" -> {
                        // Read the BUILD_TIME constant generated at compile time
                        val buildTime: String = BuildConfig.BUILD_TIME
                        result.success(buildTime)
                    }

                    else -> {
                        // Handle not-implemented method calls
                        result.notImplemented()
                    }
                }
            }
    }
}
