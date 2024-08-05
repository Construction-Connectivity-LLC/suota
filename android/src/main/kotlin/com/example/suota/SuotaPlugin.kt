package com.example.renesas_suota

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.util.Log
import androidx.core.content.ContextCompat.getSystemService
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import androidx.lifecycle.Lifecycle
import com.dialog.suotalib.dialogs.SupportCustomDialogFragment
import com.dialog.suotalib.global.SuotaLibConfig
import com.dialog.suotalib.global.SuotaProfile
import com.dialog.suotalib.global.SuotaProfile.SuotaProtocolState
import com.dialog.suotalib.interfaces.callbacks.ISuotaManagerCallback.SuotaLogType
import com.dialog.suotalib.suota.SuotaFile
import com.dialog.suotalib.suota.SuotaManager
import com.dialog.suotalib.suota.SuotaManagerCallback
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** RenesasSuotaPlugin */
class SuotaPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var activity: FlutterFragmentActivity
  private lateinit var lifecycle: Lifecycle

  private var sink: EventChannel.EventSink? = null
  private lateinit var suotaManager: SuotaManager

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "renesas_suota")
    context = flutterPluginBinding.applicationContext
    EventChannel(flutterPluginBinding.binaryMessenger, "renesas_suota/events").setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          sink = events
          events?.success(mapOf("event" to "listen"))
        }

        override fun onCancel(arguments: Any?) {
          sink = null
        }

      }
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "installUpdate") {
      installUpdate(call, result)
    } else {
      result.notImplemented()
    }
  }

  private fun installUpdate(call: MethodCall, result: Result) {
    val path = call.argument<String>("path")
    val fileName = call.argument<String>("fileName")
    val remoteId = call.argument<String>("remoteId")
    val bluetoothManager: BluetoothManager? =
      getSystemService(context, BluetoothManager::class.java)
    val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    if (bluetoothAdapter == null) {
      result.error("Bluetooth not available", "Bluetooth not available", null)
    }
    val remoteDevice = bluetoothAdapter?.getRemoteDevice(remoteId)
    if (remoteDevice == null) {
      result.error("Remote device not found", "Remote device not found", null)
    }
    suotaManager = SuotaManager(context, remoteDevice, object : SuotaManagerCallback() {

      override fun pendingRebootDialog(rebootDialog: SupportCustomDialogFragment?) {
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
          rebootDialog?.showDialog((activity as FragmentActivity).supportFragmentManager);
        } else {
//                    suotaActivity.setPendingRebootDialog(rebootDialog);
        }
      }

      override fun onSuotaLog(state: SuotaProtocolState?, type: SuotaLogType?, log: String?) {
      }

      override fun onUploadProgress(percent: Float) {
        Log.d("RenesasSuotaPlugin", "onUploadProgress: $percent")
        sink?.success(mapOf("progress" to percent))
      }

      override fun onSuccess(totalElapsedSeconds: Double, imageUploadElapsedSeconds: Double) {
        result.success(true)
      }

      override fun onFailure(errorCode: Int) {
        val errorMsg = SuotaProfile.Errors.suotaErrorCodeList.get(errorCode)
        result.error(errorCode.toString(), errorMsg, null)
      }

      override fun onDeviceReady() {
        val suotaFile = SuotaFile(path, fileName)
        suotaManager.suotaFile = suotaFile
        suotaManager.initializeSuota(
          SuotaLibConfig.Default.BLOCK_SIZE,
          SuotaLibConfig.Default.MISO_GPIO,
          SuotaLibConfig.Default.MOSI_GPIO,
          SuotaLibConfig.Default.CS_GPIO,
          SuotaLibConfig.Default.SCK_GPIO,
          SuotaLibConfig.Default.IMAGE_BANK
        )
        suotaManager.startUpdate()
      }

    })
    suotaManager.setUiContext(context)
    suotaManager.connect()

  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity as FlutterFragmentActivity;
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    val fragmentManager: FragmentManager = activity.supportFragmentManager
    println("fragmentManager: $fragmentManager")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    TODO("Not yet implemented")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    TODO("Not yet implemented")
  }

  override fun onDetachedFromActivity() {
    TODO("Not yet implemented")
  }
}
