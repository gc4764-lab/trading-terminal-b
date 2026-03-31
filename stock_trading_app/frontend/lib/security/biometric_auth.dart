import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  static Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> authenticateWithBiometrics({
    required String reason,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> enableBiometricAuth(String userId) async {
    if (await isAvailable()) {
      final authenticated = await authenticate(
        reason: 'Enable biometric authentication',
      );
      
      if (authenticated) {
        // Store preference in secure storage
        await _storeBiometricPreference(userId, true);
      }
    }
  }
  
  static Future<bool> isBiometricEnabled(String userId) async {
    // Check if user has enabled biometric auth
    return false;
  }
  
  static Future<void> _storeBiometricPreference(String userId, bool enabled) async {
    // Store in secure storage
  }
}