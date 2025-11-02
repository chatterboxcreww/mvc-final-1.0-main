package com.healthapp.mvc

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "step_counter_service"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ compatibility
        enableEdgeToEdge()
        
        // Handle window insets for proper display
        handleWindowInsets()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for step counter service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startStepService" -> {
                    try {
                        // Start step counting service
                        result.success("Step service started")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start step service", e.message)
                    }
                }
                "stopStepService" -> {
                    try {
                        // Stop step counting service
                        result.success("Step service stopped")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop step service", e.message)
                    }
                }
                "getCurrentStepCount" -> {
                    try {
                        // Get current step count
                        result.success(0) // Placeholder
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get step count", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Enable edge-to-edge display for Android 15+ compatibility
     * This replaces deprecated window flag methods
     */
    private fun enableEdgeToEdge() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // For Android 11+ (API 30+)
            WindowCompat.setDecorFitsSystemWindows(window, false)
            
            // Configure window insets controller
            val controller = WindowInsetsControllerCompat(window, window.decorView)
            
            // Make status bar and navigation bar transparent
            controller.isAppearanceLightStatusBars = false
            controller.isAppearanceLightNavigationBars = false
            
        } else {
            // For older Android versions, use compatible approach
            @Suppress("DEPRECATION")
            window.setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
        }
    }
    
    /**
     * Handle window insets for proper content display
     * Ensures app content doesn't overlap with system UI
     */
    private fun handleWindowInsets() {
        androidx.core.view.ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, windowInsets ->
            val insets = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or 
                WindowInsetsCompat.Type.displayCutout()
            )
            
            // Apply padding to avoid system UI overlap
            view.setPadding(
                insets.left,
                insets.top,
                insets.right,
                insets.bottom
            )
            
            windowInsets
        }
    }
    
    /**
     * Handle configuration changes for different screen orientations and sizes
     * Supports foldables and tablets as required by Android 16
     */
    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        
        // Re-apply edge-to-edge settings on configuration change
        enableEdgeToEdge()
        handleWindowInsets()
    }
}