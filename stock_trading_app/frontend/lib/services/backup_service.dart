import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static const String _backupFolder = 'backups';
  static const int _maxBackups = 30;
  
  // Create backup
  static Future<File> createBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$_backupFolder');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File('${backupDir.path}/backup_$timestamp.zip');
    
    // Collect files to backup
    final files = <File>[];
    
    // Database files
    final databases = await getDatabasesPath();
    final dbFiles = Directory(databases).listSync();
    for (var file in dbFiles) {
      if (file is File && file.path.endsWith('.db')) {
        files.add(file);
      }
    }
    
    // Settings
    final settingsFile = File('${appDir.path}/settings.json');
    if (await settingsFile.exists()) {
      files.add(settingsFile);
    }
    
    // User preferences
    final prefsFile = File('${appDir.path}/preferences.json');
    if (await prefsFile.exists()) {
      files.add(prefsFile);
    }
    
    // Create archive
    final encoder = ZipFileEncoder();
    encoder.create(backupFile.path);
    
    for (var file in files) {
      await encoder.addFile(file);
    }
    
    await encoder.close();
    
    // Clean old backups
    await _cleanOldBackups(backupDir);
    
    return backupFile;
  }
  
  // Restore from backup
  static Future<bool> restoreBackup(File backupFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Extract backup
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (var file in archive) {
        if (file.isFile) {
          final filename = file.name;
          final filePath = '${appDir.path}/$filename';
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }
  
  // Schedule automatic backups
  static void scheduleBackups() {
    // Check if backup is needed every hour
    Timer.periodic(const Duration(hours: 1), (timer) async {
      final lastBackup = await _getLastBackupTime();
      final now = DateTime.now();
      
      if (lastBackup == null || now.difference(lastBackup) > const Duration(hours: 24)) {
        await createBackup();
      }
    });
  }
  
  // Export data to cloud
  static Future<void> exportToCloud() async {
    final backup = await createBackup();
    
    // Upload to cloud storage (implementation depends on provider)
    // Example: Upload to AWS S3, Google Cloud Storage, etc.
    
    await backup.delete(); // Clean up local file after upload
  }
  
  // Share backup file
  static Future<void> shareBackup() async {
    final backup = await createBackup();
    await Share.shareXFiles(
      [XFile(backup.path)],
      text: 'Stock Trading App Backup - ${DateTime.now()}',
    );
  }
  
  // Clean old backups
  static Future<void> _cleanOldBackups(Directory backupDir) async {
    final backups = await backupDir.list().toList();
    
    if (backups.length > _maxBackups) {
      backups.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });
      
      final toDelete = backups.length - _maxBackups;
      for (int i = 0; i < toDelete; i++) {
        if (backups[i] is File) {
          await (backups[i] as File).delete();
        }
      }
    }
  }
  
  // Get last backup time
  static Future<DateTime?> _getLastBackupTime() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$_backupFolder');
    
    if (!await backupDir.exists()) {
      return null;
    }
    
    final backups = await backupDir.list().toList();
    if (backups.isEmpty) {
      return null;
    }
    
    backups.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });
    
    return backups.first.statSync().modified;
  }
}