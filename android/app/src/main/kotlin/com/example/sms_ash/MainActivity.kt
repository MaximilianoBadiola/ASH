package com.example.sms_ash // Cambia esto para que coincida con tu paquete

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sms_ash/sms" // Cambia esto para que coincida con tu paquete
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkSmsPermission") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val hasPermission = ActivityCompat.checkSelfPermission(context, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
                    if (!hasPermission) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 1)
                    }
                    result.success(hasPermission)
                } else {
                    // Para versiones anteriores a Marshmallow (6.0), los permisos se otorgan en tiempo de instalación
                    result.success(true)
                }
            } else if (call.method == "sendSMS") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                
                if (phoneNumber == null || message == null) {
                    result.error("INVALID_ARGUMENTS", "Phone number or message is null", null)
                    return@setMethodCallHandler
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (ActivityCompat.checkSelfPermission(context, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 1)
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                        return@setMethodCallHandler
                    }
                }
                
                try {
                    val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        context.getSystemService(SmsManager::class.java)
                    } else {
                        SmsManager.getDefault()
                    }
                    
                    smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SMS_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}