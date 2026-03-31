import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stack_trace/stack_trace.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();
  
  File? _logFile;
  final List<LogEntry> _memoryLogs = [];
  static const int _maxMemoryLogs = 1000;
  
  enum LogLevel {
    debug,
    info,
    warning,
    error,
    critical,
  }
  
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDir.path}/logs');
    
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    final logFileName = 'app_${DateTime.now().toIso8601String().replaceAll(':', '-')}.log';
    _logFile = File('${logDir.path}/$logFileName');
    
    // Rotate logs if needed
    await _rotateLogs(logDir);
  }
  
  // Log methods
  void debug(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, context: context, stackTrace: stackTrace);
  }
  
  void info(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, context: context, stackTrace: stackTrace);
  }
  
  void warning(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, context: context, stackTrace: stackTrace);
  }
  
  void error(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, context: context, stackTrace: stackTrace);
  }
  
  void critical(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, context: context, stackTrace: stackTrace);
  }
  
  // Core logging method
  void _log(LogLevel level, String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      context: context,
      stackTrace: stackTrace,
      trace: stackTrace != null ? Trace.from(stackTrace).toString() : null,
    );
    
    // Store in memory
    _memoryLogs.add(entry);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }
    
    // Write to file
    _writeToFile(entry);
    
    // Print to console in debug mode
    if (level == LogLevel.error || level == LogLevel.critical) {
      print('[${level.toString().split('.').last.toUpperCase()}] $message');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    
    // Send critical errors to Sentry
    if (level == LogLevel.critical) {
      _sendToSentry(entry);
    }
  }
  
  // Write to log file
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;
    
    final logLine = entry.toJson();
    await _logFile!.writeAsString('$logLine\n', mode: FileMode.append);
  }
  
  // Rotate logs
  Future<void> _rotateLogs(Directory logDir, {int maxFiles = 30}) async {
    final files = await logDir.list().toList();
    if (files.length > maxFiles) {
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });
      
      final toDelete = files.length - maxFiles;
      for (int i = 0; i < toDelete; i++) {
        await files[i].delete();
      }
    }
  }
  
  // Query logs
  Future<List<LogEntry>> queryLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    String? searchText,
    int limit = 100,
  }) async {
    List<LogEntry> results = [];
    
    // Search in memory logs first
    for (var entry in _memoryLogs.reversed) {
      if (results.length >= limit) break;
      
      if (startDate != null && entry.timestamp.isBefore(startDate)) continue;
      if (endDate != null && entry.timestamp.isAfter(endDate)) continue;
      if (level != null && entry.level != level) continue;
      if (searchText != null && !entry.message.contains(searchText)) continue;
      
      results.add(entry);
    }
    
    // If more results needed, read from file
    if (results.length < limit && _logFile != null) {
      final lines = await _logFile!.readAsLines();
      for (var line in lines.reversed) {
        if (results.length >= limit) break;
        
        try {
          final entry = LogEntry.fromJson(line);
          
          if (startDate != null && entry.timestamp.isBefore(startDate)) continue;
          if (endDate != null && entry.timestamp.isAfter(endDate)) continue;
          if (level != null && entry.level != level) continue;
          if (searchText != null && !entry.message.contains(searchText)) continue;
          
          results.add(entry);
        } catch (e) {
          // Skip invalid lines
        }
      }
    }
    
    return results;
  }
  
  // Export logs
  Future<File> exportLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    String format = 'json',
  }) async {
    final logs = await queryLogs(
      startDate: startDate,
      endDate: endDate,
      level: level,
      limit: 10000,
    );
    
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    final filename = 'logs_export_${DateTime.now().millisecondsSinceEpoch}.$format';
    final exportFile = File('${exportDir.path}/$filename');
    
    if (format == 'json') {
      final jsonLogs = logs.map((l) => l.toJson()).toList();
      await exportFile.writeAsString(jsonEncode(jsonLogs));
    } else if (format == 'csv') {
      final csv = StringBuffer();
      csv.writeln('Timestamp,Level,Message,Context');
      for (var log in logs) {
        csv.writeln('${log.timestamp.toIso8601String()},${log.level},${log.message.replaceAll(',', ';')},${jsonEncode(log.context)}');
      }
      await exportFile.writeAsString(csv.toString());
    }
    
    return exportFile;
  }
  
  // Clear logs
  Future<void> clearLogs() async {
    _memoryLogs.clear();
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }
  
  // Send to Sentry
  void _sendToSentry(LogEntry entry) {
    // Sentry integration
  }
  
  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final logs = await queryLogs(limit: 10000);
    
    final stats = <String, dynamic>{
      'total_logs': logs.length,
      'by_level': {},
      'date_range': {
        'oldest': logs.isNotEmpty ? logs.last.timestamp : null,
        'newest': logs.isNotEmpty ? logs.first.timestamp : null,
      },
    };
    
    for (var level in LogLevel.values) {
      stats['by_level'][level.toString()] = logs.where((l) => l.level == level).length;
    }
    
    return stats;
  }
}

class LogEntry {
  final DateTime timestamp;
  final LoggingService.LogLevel level;
  final String message;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  final String? trace;
  
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.stackTrace,
    this.trace,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.toString(),
    'message': message,
    'context': context,
    'trace': trace,
  };
  
  factory LogEntry.fromJson(String json) {
    final data = jsonDecode(json);
    return LogEntry(
      timestamp: DateTime.parse(data['timestamp']),
      level: LoggingService.LogLevel.values.firstWhere(
        (l) => l.toString() == data['level'],
      ),
      message: data['message'],
      context: data['context'],
      trace: data['trace'],
    );
  }
}