import 'dart:convert';
import 'dart:math';
import 'package:pointycastle/pointycastle.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final String _encryptionKeyKey = 'encryption_key';
  
  // Generate or retrieve encryption key
  static Future<Uint8List> _getEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (keyString == null) {
      // Generate new key
      final key = _generateKey();
      await _secureStorage.write(key: _encryptionKeyKey, value: base64Encode(key));
      return key;
    }
    
    return base64Decode(keyString);
  }
  
  static Uint8List _generateKey() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(
        Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)),
        ),
      ));
    
    return secureRandom.nextBytes(32);
  }
  
  // Encrypt sensitive data
  static Future<String> encrypt(String plainText) async {
    final key = await _getEncryptionKey();
    final iv = _generateIV();
    
    final cipher = CBCBlockCipher(AESEngine());
    final params = ParametersWithIV(KeyParameter(key), iv);
    
    cipher.init(true, params);
    
    final plainBytes = utf8.encode(plainText);
    final encryptedBytes = _padAndEncrypt(cipher, plainBytes);
    
    // Combine IV + encrypted data
    final combined = Uint8List(iv.length + encryptedBytes.length)
      ..setAll(0, iv)
      ..setAll(iv.length, encryptedBytes);
    
    return base64Encode(combined);
  }
  
  // Decrypt sensitive data
  static Future<String> decrypt(String encryptedText) async {
    final key = await _getEncryptionKey();
    final combined = base64Decode(encryptedText);
    
    // Extract IV (first 16 bytes)
    final iv = combined.sublist(0, 16);
    final encryptedBytes = combined.sublist(16);
    
    final cipher = CBCBlockCipher(AESEngine());
    final params = ParametersWithIV(KeyParameter(key), iv);
    
    cipher.init(false, params);
    
    final decryptedBytes = _decryptAndUnpad(cipher, encryptedBytes);
    return utf8.decode(decryptedBytes);
  }
  
  static Uint8List _generateIV() {
    return Uint8List.fromList(
      List.generate(16, (_) => Random.secure().nextInt(256)),
    );
  }
  
  static Uint8List _padAndEncrypt(BlockCipher cipher, Uint8List input) {
    final blockSize = cipher.blockSize;
    final paddingLength = blockSize - (input.length % blockSize);
    final padded = Uint8List(input.length + paddingLength)
      ..setAll(0, input)
      ..fillRange(input.length, input.length + paddingLength, paddingLength);
    
    final output = Uint8List(padded.length);
    for (int i = 0; i < padded.length; i += blockSize) {
      cipher.processBlock(padded, i, output, i);
    }
    
    return output;
  }
  
  static Uint8List _decryptAndUnpad(BlockCipher cipher, Uint8List input) {
    final blockSize = cipher.blockSize;
    final output = Uint8List(input.length);
    
    for (int i = 0; i < input.length; i += blockSize) {
      cipher.processBlock(input, i, output, i);
    }
    
    final paddingLength = output[output.length - 1];
    return output.sublist(0, output.length - paddingLength);
  }
  
  // Secure storage for API keys
  static Future<void> storeBrokerCredentials(
    String brokerId,
    String apiKey,
    String apiSecret,
  ) async {
    final encryptedKey = await encrypt(apiKey);
    final encryptedSecret = await encrypt(apiSecret);
    
    await _secureStorage.write(key: '${brokerId}_api_key', value: encryptedKey);
    await _secureStorage.write(key: '${brokerId}_api_secret', value: encryptedSecret);
  }
  
  static Future<Map<String, String>> getBrokerCredentials(String brokerId) async {
    final encryptedKey = await _secureStorage.read(key: '${brokerId}_api_key');
    final encryptedSecret = await _secureStorage.read(key: '${brokerId}_api_secret');
    
    if (encryptedKey == null || encryptedSecret == null) {
      throw Exception('Broker credentials not found');
    }
    
    final apiKey = await decrypt(encryptedKey);
    final apiSecret = await decrypt(encryptedSecret);
    
    return {
      'apiKey': apiKey,
      'apiSecret': apiSecret,
    };
  }
  
  static Future<void> clearBrokerCredentials(String brokerId) async {
    await _secureStorage.delete(key: '${brokerId}_api_key');
    await _secureStorage.delete(key: '${brokerId}_api_secret');
  }
}