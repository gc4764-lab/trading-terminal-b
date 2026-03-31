import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:stock_trading_app/security/encryption_service.dart';

class UserManagementService {
  static Database? _database;
  
  static Future<void> initialize() async {
    _database = await openDatabase(
      'users.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE,
            password_hash TEXT,
            name TEXT,
            role TEXT,
            status TEXT,
            created_at DATETIME,
            last_login DATETIME,
            preferences TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE user_sessions(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            token TEXT,
            device_info TEXT,
            ip_address TEXT,
            created_at DATETIME,
            expires_at DATETIME
          )
        ''');
        
        await db.execute('''
          CREATE TABLE user_permissions(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            permission TEXT,
            granted_by TEXT,
            granted_at DATETIME
          )
        ''');
      },
    );
  }
  
  // Create new user
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    // Check if user exists
    final existing = await _database?.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (existing != null && existing.isNotEmpty) {
      throw Exception('User already exists');
    }
    
    // Hash password
    final passwordHash = await _hashPassword(password);
    
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    await _database?.insert('users', {
      'id': userId,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'role': role,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'preferences': jsonEncode({}),
    });
    
    return {
      'id': userId,
      'email': email,
      'name': name,
      'role': role,
    };
  }
  
  // Authenticate user
  static Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    Map<String, dynamic> deviceInfo,
    String ipAddress,
  ) async {
    final users = await _database?.query(
      'users',
      where: 'email = ? AND status = ?',
      whereArgs: [email, 'active'],
    );
    
    if (users == null || users.isEmpty) {
      throw Exception('Invalid credentials');
    }
    
    final user = users.first;
    final isValid = await _verifyPassword(password, user['password_hash']);
    
    if (!isValid) {
      throw Exception('Invalid credentials');
    }
    
    // Update last login
    await _database?.update(
      'users',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user['id']],
    );
    
    // Create session
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final token = await _generateToken(user['id']);
    
    await _database?.insert('user_sessions', {
      'id': sessionId,
      'user_id': user['id'],
      'token': await EncryptionService.encrypt(token),
      'device_info': jsonEncode(deviceInfo),
      'ip_address': ipAddress,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
    
    return {
      'user': {
        'id': user['id'],
        'email': user['email'],
        'name': user['name'],
        'role': user['role'],
      },
      'token': token,
      'sessionId': sessionId,
    };
  }
  
  // Validate session
  static Future<bool> validateSession(String token) async {
    final sessions = await _database?.query(
      'user_sessions',
      where: 'token = ? AND expires_at > ?',
      whereArgs: [await EncryptionService.encrypt(token), DateTime.now().toIso8601String()],
    );
    
    return sessions != null && sessions.isNotEmpty;
  }
  
  // Get user permissions
  static Future<List<String>> getUserPermissions(String userId) async {
    final permissions = await _database?.query(
      'user_permissions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    return permissions?.map((p) => p['permission'] as String).toList() ?? [];
  }
  
  // Grant permission
  static Future<void> grantPermission(
    String userId,
    String permission,
    String grantedBy,
  ) async {
    await _database?.insert('user_permissions', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': userId,
      'permission': permission,
      'granted_by': grantedBy,
      'granted_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Revoke permission
  static Future<void> revokePermission(String userId, String permission) async {
    await _database?.delete(
      'user_permissions',
      where: 'user_id = ? AND permission = ?',
      whereArgs: [userId, permission],
    );
  }
  
  // Update user preferences
  static Future<void> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    await _database?.update(
      'users',
      {'preferences': jsonEncode(preferences)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  // Get user preferences
  static Future<Map<String, dynamic>> getPreferences(String userId) async {
    final users = await _database?.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (users == null || users.isEmpty) {
      return {};
    }
    
    return jsonDecode(users.first['preferences']);
  }
  
  // Deactivate user
  static Future<void> deactivateUser(String userId, String reason) async {
    await _database?.update(
      'users',
      {'status': 'deactivated'},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    // Log deactivation
    await ComplianceService.logAuditEvent(
      userId: userId,
      action: 'user_deactivated',
      details: {'reason': reason},
      ipAddress: 'system',
    );
  }
  
  // Helper methods
  static Future<String> _hashPassword(String password) async {
    // Implement secure password hashing
    return password; // Placeholder
  }
  
  static Future<bool> _verifyPassword(String password, String hash) async {
    // Implement password verification
    return true; // Placeholder
  }
  
  static Future<String> _generateToken(String userId) async {
    // Generate JWT token
    return 'token_${DateTime.now().millisecondsSinceEpoch}_$userId';
  }
}