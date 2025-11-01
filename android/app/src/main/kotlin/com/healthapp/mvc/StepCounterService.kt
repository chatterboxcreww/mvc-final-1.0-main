package com.healthapp.mvc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.*

class StepCounterService : Service(), SensorEventListener {
    companion object {
        private const val TAG = "StepCounterService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "step_counter_channel"
        private const val SHARED_PREFS = "step_counter_prefs"
        private const val KEY_DAILY_STEPS = "daily_steps"
        private const val KEY_LAST_DATE = "last_date"
        private const val KEY_TOTAL_STEPS = "total_steps"
        private const val KEY_STEP_HISTORY = "step_history"
        
        @Volatile
        private var instance: StepCounterService? = null
        
        fun getInstance(): StepCounterService? = instance
        
        fun getCurrentSteps(context: Context): Int {
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
            return prefs.getInt(KEY_DAILY_STEPS, 0)
        }
        
        fun getServiceStatus(): Boolean {
            return instance != null
        }
        
        fun addManualSteps(context: Context, steps: Int) {
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
            val currentSteps = prefs.getInt(KEY_DAILY_STEPS, 0)
            val newSteps = currentSteps + steps
            
            prefs.edit()
                .putInt(KEY_DAILY_STEPS, newSteps)
                .apply()
            
            instance?.updateNotification(newSteps)
            Log.d(TAG, "Manual steps added: $steps, Total: $newSteps")
        }
        
        fun resetDailySteps(context: Context) {
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
            prefs.edit()
                .putInt(KEY_DAILY_STEPS, 0)
                .apply()
            
            instance?.updateNotification(0)
            Log.d(TAG, "Daily steps reset")
        }
        
        fun getHistoricalSteps(context: Context): Map<String, Any> {
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
            val history = prefs.getString(KEY_STEP_HISTORY, "{}") ?: "{}"
            val totalSteps = prefs.getInt(KEY_TOTAL_STEPS, 0)
            
            return mapOf(
                "history" to history,
                "totalSteps" to totalSteps
            )
        }
    }
    
    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    private var stepCounterSensor: Sensor? = null
    private lateinit var sharedPrefs: SharedPreferences
    private lateinit var notificationManager: NotificationManager
    
    private var initialSteps = -1
    private var dailySteps = 0
    private var lastDate = ""
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        Log.d(TAG, "Service created")
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        stepDetectorSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        
        sharedPrefs = getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        createNotificationChannel()
        loadSavedData()
        registerSensorListeners()
        
        startForeground(NOTIFICATION_ID, createNotification(dailySteps))
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        unregisterSensorListeners()
        Log.d(TAG, "Service destroyed")
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Step Counter",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows daily step count"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(steps: Int): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE else 0
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Daily Steps")
            .setContentText("$steps steps today")
            .setSmallIcon(android.R.drawable.ic_menu_directions)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    private fun updateNotification(steps: Int) {
        notificationManager.notify(NOTIFICATION_ID, createNotification(steps))
    }
    
    private fun loadSavedData() {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        lastDate = sharedPrefs.getString(KEY_LAST_DATE, "") ?: ""
        
        if (lastDate != today) {
            // New day - reset daily steps and save yesterday's count
            if (lastDate.isNotEmpty()) {
                saveHistoricalData(lastDate, dailySteps)
            }
            dailySteps = 0
            sharedPrefs.edit()
                .putString(KEY_LAST_DATE, today)
                .putInt(KEY_DAILY_STEPS, 0)
                .apply()
        } else {
            dailySteps = sharedPrefs.getInt(KEY_DAILY_STEPS, 0)
        }
        
        Log.d(TAG, "Loaded data - Date: $today, Steps: $dailySteps")
    }
    
    private fun saveHistoricalData(date: String, steps: Int) {
        try {
            val history = sharedPrefs.getString(KEY_STEP_HISTORY, "{}") ?: "{}"
            val totalSteps = sharedPrefs.getInt(KEY_TOTAL_STEPS, 0)
            
            // Simple JSON-like storage
            val updatedHistory = if (history == "{}") {
                "{\"$date\":$steps}"
            } else {
                history.dropLast(1) + ",\"$date\":$steps}"
            }
            
            sharedPrefs.edit()
                .putString(KEY_STEP_HISTORY, updatedHistory)
                .putInt(KEY_TOTAL_STEPS, totalSteps + steps)
                .apply()
            
            Log.d(TAG, "Saved historical data for $date: $steps steps")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving historical data", e)
        }
    }
    
    private fun registerSensorListeners() {
        stepCounterSensor?.let { sensor ->
            val registered = sensorManager.registerListener(
                this, sensor, SensorManager.SENSOR_DELAY_UI
            )
            Log.d(TAG, "Step counter sensor registered: $registered")
        }
        
        stepDetectorSensor?.let { sensor ->
            val registered = sensorManager.registerListener(
                this, sensor, SensorManager.SENSOR_DELAY_UI
            )
            Log.d(TAG, "Step detector sensor registered: $registered")
        }
        
        if (stepCounterSensor == null && stepDetectorSensor == null) {
            Log.w(TAG, "No step sensors available")
        }
    }
    
    private fun unregisterSensorListeners() {
        sensorManager.unregisterListener(this)
        Log.d(TAG, "Sensor listeners unregistered")
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let { sensorEvent ->
            when (sensorEvent.sensor.type) {
                Sensor.TYPE_STEP_COUNTER -> handleStepCounter(sensorEvent.values[0].toInt())
                Sensor.TYPE_STEP_DETECTOR -> handleStepDetector()
            }
        }
    }
    
    private fun handleStepCounter(totalSteps: Int) {
        if (initialSteps == -1) {
            initialSteps = totalSteps
            Log.d(TAG, "Initial step counter value: $initialSteps")
        }
        
        val todaySteps = totalSteps - initialSteps
        if (todaySteps >= 0 && todaySteps != dailySteps) {
            dailySteps = todaySteps
            saveStepCount()
            updateNotification(dailySteps)
            notifyFlutter()
            Log.d(TAG, "Step counter updated: $dailySteps")
        }
    }
    
    private fun handleStepDetector() {
        dailySteps++
        saveStepCount()
        updateNotification(dailySteps)
        notifyFlutter()
        Log.d(TAG, "Step detected - Total: $dailySteps")
    }
    
    private fun saveStepCount() {
        sharedPrefs.edit()
            .putInt(KEY_DAILY_STEPS, dailySteps)
            .apply()
    }
    
    private fun notifyFlutter() {
        try {
            val activity = MainActivity.getInstance()
            if (activity != null) {
                activity.runOnUiThread {
                    try {
                        val methodChannel = activity.getMethodChannel()
                        if (methodChannel != null) {
                            methodChannel.invokeMethod(
                                "onKotlinStepUpdate",
                                mapOf("steps" to dailySteps)
                            )
                        } else {
                            Log.w(TAG, "Method channel is null, cannot notify Flutter")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error invoking method on Flutter channel", e)
                    }
                }
            } else {
                Log.w(TAG, "MainActivity instance is null, cannot notify Flutter")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter", e)
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        Log.d(TAG, "Sensor accuracy changed: ${sensor?.name}, accuracy: $accuracy")
    }
}
