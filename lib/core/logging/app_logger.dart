// lib/core/logging/app_logger.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Comprehensive logging system for production debugging and analytics
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const String _logFilePrefix = 'health_trkd_log';
  static const int _maxLogFiles = 7; // Keep logs for 7 days
  static const int _maxLogSizeBytes = 5 * 1024 * 1024; // 5MB per log file
  static const String _logLevelKey = 'app_log_level';
  
  LogLevel _currentLogLevel = LogLevel.info;
  File? _currentLogFile;
  bool _isInitialized = false;
  final List<LogEntry> _memoryBuffer = [];
  static const int _maxMemoryBufferSize = 100;

  /// Initialize the logging system
  Future<void> initialize({LogLevel logLevel = LogLevel.info}) async {
    if (_isInitialized) return;
    
    try {
      _currentLogLevel = logLevel;
      await _loadLogLevel();
      await _initializeLogFile();
      _isInitialized = true;
      
      // Log initialization
      info('AppLogger initialized with level: ${_currentLogLevel.name}');
    } catch (e) {
      debugPrint('Failed to initialize AppLogger: $e');
    }
  }

  /// Load log level from preferences
  Future<void> _loadLogLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelName = prefs.getString(_logLevelKey);
      if (levelName != null) {
        _currentLogLevel = LogLevel.values.firstWhere(
          (level) => level.name == levelName,
          orElse: () => LogLevel.info,
        );
      }
    } catch (e) {
      debugPrint('Failed to load log level: $e');
    }
  }

  /// Save log level to preferences
  Future<void> _saveLogLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_logLevelKey, _currentLogLevel.name);
    } catch (e) {
      debugPrint('Failed to save log level: $e');
    }
  }

  /// Initialize log file
  Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Clean up old log files
      await _cleanupOldLogs(logDir);
      
      // Create new log file for today
      final today = DateTime.now();
      final fileName = '${_logFilePrefix}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}.log';
      _currentLogFile = File('${logDir.path}/$fileName');
      
      // Write header if new file
      if (!await _currentLogFile!.exists()) {
        await _writeToFile('=== Health-TRKD Log Started at ${DateTime.now().toIso8601String()} ===\n');
      }
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  /// Clean up old log files
  Future<void> _cleanupOldLogs(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((file) => file.path.contains(_logFilePrefix))
          .toList();
      
      // Sort by modification date
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Remove files beyond the limit
      if (logFiles.length > _maxLogFiles) {
        for (int i = _maxLogFiles; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old logs: $e');
    }
  }

  /// Set log level
  Future<void> setLogLevel(LogLevel level) async {
    _currentLogLevel = level;
    await _saveLogLevel();
    info('Log level changed to: ${level.name}');
  }

  /// Log verbose message
  void verbose(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.verbose, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Log debug message
  void debug(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(String message, {String? tag, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag: tag, data: data, stackTrace: stackTrace);
  }

  /// Core logging method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.index < _currentLogLevel.index) return;

    final logEntry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      data: data,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Add to memory buffer
    _addToMemoryBuffer(logEntry);

    // Print to console in debug mode
    if (kDebugMode) {
      _printToConsole(logEntry);
    }

    // Write to file
    _writeLogEntry(logEntry);
  }

  /// Add log entry to memory buffer
  void _addToMemoryBuffer(LogEntry entry) {
    _memoryBuffer.add(entry);
    
    // Maintain buffer size
    if (_memoryBuffer.length > _maxMemoryBufferSize) {
      _memoryBuffer.removeAt(0);
    }
  }

  /// Print log entry to console
  void _printToConsole(LogEntry entry) {
    final prefix = '[${entry.level.name.toUpperCase()}]';
    final timestamp = entry.timestamp.toIso8601String();
    final tag = entry.tag != null ? '[${entry.tag}]' : '';
    
    String output = '$timestamp $prefix $tag ${entry.message}';
    
    if (entry.data != null) {
      output += '\nData: ${jsonEncode(entry.data)}';
    }
    
    if (entry.stackTrace != null) {
      output += '\nStack Trace:\n${entry.stackTrace}';
    }
    
    // Use appropriate print method based on level
    switch (entry.level) {
      case LogLevel.verbose:
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(output);
        break;
      case LogLevel.warning:
      case LogLevel.error:
      case LogLevel.fatal:
        debugPrint(output);
        break;
    }
  }

  /// Write log entry to file
  Future<void> _writeLogEntry(LogEntry entry) async {
    if (!_isInitialized || _currentLogFile == null) return;
    
    try {
      // Check file size and rotate if necessary
      await _checkAndRotateLogFile();
      
      final logLine = _formatLogEntry(entry);
      await _writeToFile(logLine);
    } catch (e) {
      debugPrint('Failed to write log entry: $e');
    }
  }

  /// Format log entry for file output
  String _formatLogEntry(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.name.toUpperCase().padRight(7);
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';
    
    String line = '$timestamp $level $tag${entry.message}\n';
    
    if (entry.data != null) {
      line += '  Data: ${jsonEncode(entry.data)}\n';
    }
    
    if (entry.stackTrace != null) {
      final stackLines = entry.stackTrace.toString().split('\n');
      for (final stackLine in stackLines) {
        if (stackLine.trim().isNotEmpty) {
          line += '  $stackLine\n';
        }
      }
    }
    
    return line;
  }

  /// Write text to log file
  Future<void> _writeToFile(String text) async {
    try {
      await _currentLogFile!.writeAsString(text, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  /// Check and rotate log file if necessary
  Future<void> _checkAndRotateLogFile() async {
    try {
      if (_currentLogFile == null || !await _currentLogFile!.exists()) {
        await _initializeLogFile();
        return;
      }
      
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxLogSizeBytes) {
        // Rotate log file
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${_currentLogFile!.path}.$timestamp';
        await _currentLogFile!.rename(newPath);
        await _initializeLogFile();
      }
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Get recent log entries from memory buffer
  List<LogEntry> getRecentLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.from(_memoryBuffer);
    
    return _memoryBuffer
        .where((entry) => entry.level.index >= minLevel.index)
        .toList();
  }

  /// Get log files
  Future<List<File>> getLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) return [];
      
      final files = await logDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.contains(_logFilePrefix))
          .toList();
    } catch (e) {
      error('Failed to get log files', data: {'error': e.toString()});
      return [];
    }
  }

  /// Export logs as string
  Future<String> exportLogs({DateTime? since}) async {
    try {
      final logFiles = await getLogFiles();
      final buffer = StringBuffer();
      
      for (final file in logFiles) {
        if (since != null) {
          final fileDate = file.lastModifiedSync();
          if (fileDate.isBefore(since)) continue;
        }
        
        final content = await file.readAsString();
        buffer.writeln('=== ${file.path} ===');
        buffer.writeln(content);
        buffer.writeln();
      }
      
      return buffer.toString();
    } catch (e) {
      error('Failed to export logs', data: {'error': e.toString()});
      return 'Failed to export logs: $e';
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    try {
      final logFiles = await getLogFiles();
      for (final file in logFiles) {
        await file.delete();
      }
      
      _memoryBuffer.clear();
      await _initializeLogFile();
      info('All logs cleared');
    } catch (e) {
      error('Failed to clear logs', data: {'error': e.toString()});
    }
  }

  /// Get log statistics
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      final logFiles = await getLogFiles();
      int totalSize = 0;
      int totalEntries = 0;
      
      for (final file in logFiles) {
        totalSize += await file.length();
        final content = await file.readAsString();
        totalEntries += content.split('\n').length;
      }
      
      final levelCounts = <String, int>{};
      for (final entry in _memoryBuffer) {
        final levelName = entry.level.name;
        levelCounts[levelName] = (levelCounts[levelName] ?? 0) + 1;
      }
      
      return {
        'totalFiles': logFiles.length,
        'totalSizeBytes': totalSize,
        'totalEntries': totalEntries,
        'memoryBufferSize': _memoryBuffer.length,
        'currentLogLevel': _currentLogLevel.name,
        'levelCounts': levelCounts,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      error('Failed to get log stats', data: {'error': e.toString()});
      return {};
    }
  }

  /// Log performance metrics
  void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    final data = {
      'operation': operation,
      'durationMs': duration.inMilliseconds,
      ...?metrics,
    };
    
    info('Performance: $operation completed in ${duration.inMilliseconds}ms', 
         tag: 'PERFORMANCE', data: data);
  }

  /// Log user action
  void logUserAction(String action, {Map<String, dynamic>? context}) {
    info('User action: $action', tag: 'USER_ACTION', data: context);
  }

  /// Log API call
  void logApiCall(String endpoint, String method, int statusCode, Duration duration, {Map<String, dynamic>? data}) {
    final logData = {
      'endpoint': endpoint,
      'method': method,
      'statusCode': statusCode,
      'durationMs': duration.inMilliseconds,
      ...?data,
    };
    
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;
    _log(level, 'API: $method $endpoint -> $statusCode (${duration.inMilliseconds}ms)', 
         tag: 'API', data: logData);
  }

  /// Log database operation
  void logDatabaseOperation(String operation, String table, Duration duration, {Map<String, dynamic>? data}) {
    final logData = {
      'operation': operation,
      'table': table,
      'durationMs': duration.inMilliseconds,
      ...?data,
    };
    
    debug('DB: $operation on $table (${duration.inMilliseconds}ms)', 
          tag: 'DATABASE', data: logData);
  }

  /// Dispose resources
  void dispose() {
    _memoryBuffer.clear();
    _currentLogFile = null;
    _isInitialized = false;
  }
}

/// Log levels
enum LogLevel {
  verbose(0),
  debug(1),
  info(2),
  warning(3),
  error(4),
  fatal(5);

  const LogLevel(this.index);
  final int index;
}

/// Log entry class
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? data;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.data,
    this.stackTrace,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'data': data,
      'stackTrace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static LogEntry fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      data: json['data'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Global logger instance
final logger = AppLogger();