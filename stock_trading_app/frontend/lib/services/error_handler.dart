import 'package:flutter/material.dart';
import 'package:stock_trading_app/utils/logger.dart';

class ErrorHandler {
  static void handleError(BuildContext context, dynamic error, {StackTrace? stackTrace}) {
    AppLogger.error('Error occurred: $error', error, stackTrace);
    
    String message = _getUserFriendlyMessage(error);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
  
  static String _getUserFriendlyMessage(dynamic error) {
    if (error is NetworkError) {
      return 'Network error. Please check your connection.';
    }
    if (error is TimeoutError) {
      return 'Request timed out. Please try again.';
    }
    if (error is AuthError) {
      return 'Authentication failed. Please log in again.';
    }
    if (error is ValidationError) {
      return error.message ?? 'Invalid input. Please check your entries.';
    }
    if (error is ApiError) {
      return error.message ?? 'Server error. Please try again later.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}

class NetworkError implements Exception {
  final String message;
  NetworkError(this.message);
}

class TimeoutError implements Exception {}

class AuthError implements Exception {
  final String? message;
  AuthError([this.message]);
}

class ValidationError implements Exception {
  final String? message;
  ValidationError([this.message]);
}

class ApiError implements Exception {
  final String? message;
  final int? statusCode;
  
  ApiError({this.message, this.statusCode});
}

extension ErrorHandlerExtension on Widget {
  Widget withErrorHandler() {
    return Builder(
      builder: (context) {
        return this;
      },
    );
  }
}