package com.healthapp.mvc

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private var instance: MainActivity? = null
        fun getInstance(): MainActivity? = instance
    }
    
    private val CHANNEL = "step_counter_service"
    private lateinit var methodChannel: MethodChannel
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startStepService" -> {
                    try {
                        val intent = Intent(this, StepCounterService::class.java)
                        startForegroundService(intent)
                        result.success("Step counting service started")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start step service", e.message)
                    }
                }
                "stopStepService" -> {
                    try {
                        val intent = Intent(this, StepCounterService::class.java)
                        stopService(intent)
                        result.success("Step counting service stopped")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop step service", e.message)
                    }
                }
                "getCurrentSteps" -> {
                    try {
                        val steps = StepCounterService.getCurrentSteps(this)
                        result.success(steps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get current steps", e.message)
                    }
                }
                "getServiceStatus" -> {
                    try {
                        val isActive = StepCounterService.getServiceStatus()
                        result.success(mapOf("isActive" to isActive))
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get service status", e.message)
                    }
                }
                "addManualSteps" -> {
                    try {
                        val steps = call.argument<Int>("steps") ?: 0
                        StepCounterService.addManualSteps(this, steps)
                        result.success("Manual steps added: $steps")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to add manual steps", e.message)
                    }
                }
                "resetDailySteps" -> {
                    try {
                        StepCounterService.resetDailySteps(this)
                        result.success("Daily steps reset")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to reset daily steps", e.message)
                    }
                }
                "getHistoricalSteps" -> {
                    try {
                        val historyData = StepCounterService.getHistoricalSteps(this)
                        result.success(historyData)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get historical steps", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    fun getMethodChannel(): MethodChannel = methodChannel
}
