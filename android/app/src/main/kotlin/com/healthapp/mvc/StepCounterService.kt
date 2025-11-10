package com.healthapp.mvc

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.sqrt

class StepCounterService : Service(), SensorEventListener {
    
    private lateinit var sensorManager: SensorManager
    private var stepCounterSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null
    private var gyroscopeSensor: Sensor? = null
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var methodChannel: MethodChannel? = null
    
    // Step counting state
    private var totalStepsSinceBoot = 0
    private var baselineSteps = 0
    private var dailySteps = 0
    private var lastSaveTime = 0L
    private var isInitialized = false
    
    // Sensor fusion for false positive filtering
    private var lastAccelValues = FloatArray(3)
    private var lastGyroValues = FloatArray(3)
    private var lastStepTime = 0L
    private var isMoving = false
    private var isWalking = false
    
    // Accelerometer-based step detection (fallback)
    private var accelStepCount = 0
    private var lastAccelMagnitude = 0f
    private var stepThreshold = 11.5f // Tunable threshold
    private var lastStepDetectionTime = 0L
    private val minStepInterval = 200L // Minimum 200ms between steps
    
    // Activity recognition
    private var activityType = "unknown" // walking, running, stationary, vehicle
    private var consecutiveStationaryReadings = 0
    
    companion object {
        const val CHANNEL_ID = "step_counter_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "com.healthapp.mvc.START_STEP_TRACKING"
        const val ACTION_STOP = "com.healthapp.mvc.STOP_STEP_TRACKING"
        const val PREFS_NAME = "step_counter_prefs"
        const val KEY_BASELINE = "baseline_steps"
        const val KEY_DAILY_STEPS = "daily_steps"
        const val KEY_LAST_DATE = "last_date"
        const val KEY_TOTAL_STEPS = "total_steps_since_boot"
        
        // Sensor fusion thresholds
        const val MOVEMENT_THRESHOLD = 0.5f
        const val WALKING_GYRO_THRESHOLD = 0.3f
        const val VEHICLE_ACCEL_THRESHOLD = 15f
        const val STATIONARY_THRESHOLD = 0.2f
    }
    
    override fun onCreate() {
        super.onCreate()
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        accelerometerSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gyroscopeSensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        
        // Acquire wake lock for background operation
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "HealthApp::StepCounterWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
        
        loadState()
        checkForNewDay()
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        registerSensors()
        
        isInitialized = true
    }
    
    private fun registerSensors() {
        // Register step counter sensor (primary)
        stepCounterSensor?.let {
            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
        
        // Register accelerometer for sensor fusion and fallback
        accelerometerSensor?.let {
            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
        
        // Register gyroscope for activity recognition
        gyroscopeSensor?.let {
            sensorManager.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                // Service already started in onCreate
            }
            ACTION_STOP -> {
                stopSelf()
            }
        }
        return START_STICKY
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        
        when (event.sensor.type) {
            Sensor.TYPE_STEP_COUNTER -> handleStepCounter(event)
            Sensor.TYPE_ACCELEROMETER -> handleAccelerometer(event)
            Sensor.TYPE_GYROSCOPE -> handleGyroscope(event)
        }
    }
    
    private fun handleStepCounter(event: SensorEvent) {
        val currentSteps = event.values[0].toInt()
        
        if (!isInitialized) {
            baselineSteps = currentSteps
            totalStepsSinceBoot = currentSteps
            saveState()
            isInitialized = true
            return
        }
        
        // Validate with sensor fusion
        if (!isValidStep()) {
            return
        }
        
        totalStepsSinceBoot = currentSteps
        dailySteps = currentSteps - baselineSteps
        
        // Ensure non-negative
        if (dailySteps < 0) {
            // Device rebooted, reset baseline
            baselineSteps = currentSteps
            dailySteps = 0
        }
        
        updateNotification()
        notifyFlutter()
        
        // Save state periodically (every 30 seconds)
        val now = System.currentTimeMillis()
        if (now - lastSaveTime > 30000) {
            saveState()
            lastSaveTime = now
        }
    }
    
    private fun handleAccelerometer(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        
        // Calculate magnitude
        val magnitude = sqrt(x * x + y * y + z * z)
        
        // Detect movement
        val delta = abs(magnitude - lastAccelMagnitude)
        isMoving = delta > MOVEMENT_THRESHOLD
        
        // Detect if in vehicle (high acceleration without walking pattern)
        val isVehicle = magnitude > VEHICLE_ACCEL_THRESHOLD
        
        // Detect stationary
        if (delta < STATIONARY_THRESHOLD) {
            consecutiveStationaryReadings++
            if (consecutiveStationaryReadings > 10) {
                activityType = "stationary"
                isWalking = false
            }
        } else {
            consecutiveStationaryReadings = 0
        }
        
        // Fallback step detection using accelerometer (if no step counter sensor)
        if (stepCounterSensor == null && !isVehicle) {
            detectStepFromAccelerometer(magnitude)
        }
        
        lastAccelMagnitude = magnitude
        lastAccelValues = floatArrayOf(x, y, z)
    }
    
    private fun handleGyroscope(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        
        // Calculate rotation magnitude
        val rotationMagnitude = sqrt(x * x + y * y + z * z)
        
        // Detect walking pattern (moderate rotation)
        isWalking = rotationMagnitude > WALKING_GYRO_THRESHOLD && 
                    rotationMagnitude < 2.0f &&
                    isMoving
        
        // Update activity type
        if (isWalking) {
            activityType = if (rotationMagnitude > 1.0f) "running" else "walking"
        } else if (!isMoving) {
            activityType = "stationary"
        } else {
            activityType = "vehicle"
        }
        
        // Save activity type to SharedPreferences
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString("activity_type", activityType).apply()
        
        // Notify Flutter about activity change
        methodChannel?.invokeMethod("onActivityUpdate", activityType)
        
        lastGyroValues = floatArrayOf(x, y, z)
    }
    
    private fun detectStepFromAccelerometer(magnitude: Float) {
        val now = System.currentTimeMillis()
        
        // Check if enough time has passed since last step
        if (now - lastStepDetectionTime < minStepInterval) {
            return
        }
        
        // Detect step peak
        if (magnitude > stepThreshold && lastAccelMagnitude < stepThreshold) {
            // Step detected
            if (isValidStep()) {
                accelStepCount++
                dailySteps = accelStepCount
                lastStepDetectionTime = now
                lastStepTime = now
                
                updateNotification()
                notifyFlutter()
                
                if (now - lastSaveTime > 30000) {
                    saveState()
                    lastSaveTime = now
                }
            }
        }
    }
    
    private fun isValidStep(): Boolean {
        val now = System.currentTimeMillis()
        
        // Filter out false positives
        if (activityType == "vehicle") {
            return false
        }
        
        if (activityType == "stationary") {
            return false
        }
        
        // Ensure minimum time between steps (prevent double counting)
        if (now - lastStepTime < minStepInterval) {
            return false
        }
        
        // Require both movement and walking pattern
        if (!isMoving) {
            return false
        }
        
        lastStepTime = now
        return true
    }
    
    private fun checkForNewDay() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastDate = prefs.getString(KEY_LAST_DATE, "")
        val today = getCurrentDate()
        
        if (lastDate != today) {
            // New day detected
            baselineSteps = totalStepsSinceBoot
            dailySteps = 0
            accelStepCount = 0
            
            prefs.edit().apply {
                putString(KEY_LAST_DATE, today)
                putInt(KEY_BASELINE, baselineSteps)
                putInt(KEY_DAILY_STEPS, 0)
                apply()
            }
        }
    }
    
    private fun getCurrentDate(): String {
        val calendar = java.util.Calendar.getInstance()
        return "${calendar.get(java.util.Calendar.YEAR)}-" +
               "${calendar.get(java.util.Calendar.MONTH) + 1}-" +
               "${calendar.get(java.util.Calendar.DAY_OF_MONTH)}"
    }
    
    private fun loadState() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        baselineSteps = prefs.getInt(KEY_BASELINE, 0)
        dailySteps = prefs.getInt(KEY_DAILY_STEPS, 0)
        totalStepsSinceBoot = prefs.getInt(KEY_TOTAL_STEPS, 0)
        
        if (stepCounterSensor == null) {
            accelStepCount = dailySteps
        }
    }
    
    private fun saveState() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt(KEY_BASELINE, baselineSteps)
            putInt(KEY_DAILY_STEPS, dailySteps)
            putInt(KEY_TOTAL_STEPS, totalStepsSinceBoot)
            putString(KEY_LAST_DATE, getCurrentDate())
            apply()
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Step Counter",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks your steps in the background"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Step Tracking Active")
            .setContentText("$dailySteps steps today")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun notifyFlutter() {
        methodChannel?.invokeMethod("onStepCountUpdate", dailySteps)
    }
    
    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
    
    fun getCurrentSteps(): Int {
        return dailySteps
    }
    
    fun getActivityType(): String {
        return activityType
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Handle accuracy changes if needed
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        saveState()
        
        sensorManager.unregisterListener(this)
        wakeLock?.release()
        
        // Restart service if killed
        val restartIntent = Intent(this, StepCounterService::class.java)
        restartIntent.action = ACTION_START
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
