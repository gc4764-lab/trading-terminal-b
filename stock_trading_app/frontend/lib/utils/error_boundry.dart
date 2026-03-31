import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final Function(Object error, StackTrace stack)? onError;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };
  }
  
  void _handleError(Object error, StackTrace? stack) {
    setState(() {
      _error = error;
      _stackTrace = stack;
    });
    
    widget.onError?.call(error, stack ?? StackTrace.current);
    
    // Report to Sentry
    Sentry.captureException(
      error,
      stackTrace: stack,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }
    
    return widget.child;
  }
  
  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _stackTrace = null;
                  });
                },
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Show detailed error
                  _showErrorDetails();
                },
                child: const Text('Show Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showErrorDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error: ${_error?.toString()}'),
              const SizedBox(height: 8),
              Text('Stack Trace:'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(
                  _stackTrace?.toString() ?? 'No stack trace',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// Global error handler
void setupErrorHandling() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: details.context != null ? {'context': details.context.toString()} : null,
    );
  };
  
  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };
  
  // Catch zone errors
  runZonedGuarded(() {
    // App initialization
  }, (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
  });
}

class RetryWrapper extends StatelessWidget {
  final Future<void> Function() operation;
  final Widget child;
  final int maxRetries;
  
  const RetryWrapper({
    super.key,
    required this.operation,
    required this.child,
    this.maxRetries = 3,
  });
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
  
  Future<T> withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }
}