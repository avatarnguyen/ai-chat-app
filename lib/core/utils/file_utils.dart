import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:crypto/crypto.dart';

import '../constants/storage_constants.dart';

/// Utility class for file operations and validations
class FileUtils {
  FileUtils._();

  /// Get MIME type from file path
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Get MIME type from file bytes using content sniffing
  static String? getMimeTypeFromBytes(Uint8List bytes, String? fileName) {
    // Try to get MIME type from file name first
    if (fileName != null) {
      final mimeType = lookupMimeType(fileName);
      if (mimeType != null) return mimeType;
    }

    // Basic content sniffing for common file types
    if (bytes.length >= 4) {
      // PNG signature
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG signature
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      // GIF signature
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
      // PDF signature
      if (bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return 'application/pdf';
      }
      // ZIP signature
      if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
        return 'application/zip';
      }
    }

    // WebP signature (12 bytes needed)
    if (bytes.length >= 12) {
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }

    return 'application/octet-stream';
  }

  /// Get file extension from file path
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Calculate file hash (SHA-256)
  static Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Calculate hash from bytes
  static String calculateBytesHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Validate file for attachments
  static ValidationResult validateAttachment(String filePath) {
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult.failure(StorageConstants.errorFileNotFound);
    }

    // Get file info
    final fileSize = file.lengthSync();
    final mimeType = getMimeType(filePath) ?? 'application/octet-stream';

    // Validate file type
    if (!StorageConstants.isAllowedAttachmentType(mimeType)) {
      return ValidationResult.failure(StorageConstants.errorInvalidFileType);
    }

    // Validate file size
    if (!StorageConstants.isValidAttachmentSize(fileSize)) {
      return ValidationResult.failure(StorageConstants.errorFileTooLarge);
    }

    return ValidationResult.success();
  }

  /// Validate file for avatar upload
  static ValidationResult validateAvatar(String filePath) {
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult.failure(StorageConstants.errorFileNotFound);
    }

    // Get file info
    final fileSize = file.lengthSync();
    final mimeType = getMimeType(filePath) ?? 'application/octet-stream';

    // Validate file type
    if (!StorageConstants.isAllowedAvatarType(mimeType)) {
      return ValidationResult.failure(StorageConstants.errorInvalidFileType);
    }

    // Validate file size
    if (!StorageConstants.isValidAvatarSize(fileSize)) {
      return ValidationResult.failure(StorageConstants.errorFileTooLarge);
    }

    return ValidationResult.success();
  }

  /// Validate bytes for upload
  static ValidationResult validateBytes({
    required Uint8List bytes,
    required String fileName,
    required String uploadType, // 'attachment' or 'avatar'
  }) {
    final fileSize = bytes.length;
    final mimeType = getMimeTypeFromBytes(bytes, fileName);

    if (uploadType == 'attachment') {
      // Validate file type
      if (mimeType != null &&
          !StorageConstants.isAllowedAttachmentType(mimeType)) {
        return ValidationResult.failure(StorageConstants.errorInvalidFileType);
      }

      // Validate file size
      if (!StorageConstants.isValidAttachmentSize(fileSize)) {
        return ValidationResult.failure(StorageConstants.errorFileTooLarge);
      }
    } else if (uploadType == 'avatar') {
      // Validate file type
      if (mimeType != null && !StorageConstants.isAllowedAvatarType(mimeType)) {
        return ValidationResult.failure(StorageConstants.errorInvalidFileType);
      }

      // Validate file size
      if (!StorageConstants.isValidAvatarSize(fileSize)) {
        return ValidationResult.failure(StorageConstants.errorFileTooLarge);
      }
    }

    return ValidationResult.success();
  }

  /// Generate safe file name (remove special characters)
  static String sanitizeFileName(String fileName) {
    // Remove or replace unsafe characters
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    // Ensure it doesn't start or end with dots or spaces
    sanitized = sanitized.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');

    // Ensure minimum length
    if (sanitized.isEmpty) {
      sanitized = 'file';
    }

    // Limit length to 255 characters (common file system limit)
    if (sanitized.length > 255) {
      final extension = getFileExtension(sanitized);
      final nameWithoutExt = sanitized.substring(0, 255 - extension.length);
      sanitized = nameWithoutExt + extension;
    }

    return sanitized;
  }

  /// Get human readable file size
  static String formatFileSize(int bytes) {
    return StorageConstants.formatFileSize(bytes);
  }

  /// Get file type category
  static String getFileTypeCategory(String mimeType) {
    return StorageConstants.getFileTypeCategory(mimeType);
  }

  /// Check if file is an image
  static bool isImage(String mimeType) {
    return StorageConstants.allowedImageTypes.contains(mimeType);
  }

  /// Check if file is a document
  static bool isDocument(String mimeType) {
    return StorageConstants.allowedDocumentTypes.contains(mimeType);
  }

  /// Check if file is audio
  static bool isAudio(String mimeType) {
    return StorageConstants.allowedAudioTypes.contains(mimeType);
  }

  /// Check if file is video
  static bool isVideo(String mimeType) {
    return StorageConstants.allowedVideoTypes.contains(mimeType);
  }

  /// Check if file is an archive
  static bool isArchive(String mimeType) {
    return StorageConstants.allowedArchiveTypes.contains(mimeType);
  }

  /// Create directory if it doesn't exist
  static Future<void> ensureDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Delete file if it exists
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Copy file to new location
  static Future<bool> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return false;
      }

      // Ensure destination directory exists
      await ensureDirectoryExists(path.dirname(destinationPath));

      await sourceFile.copy(destinationPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Move file to new location
  static Future<bool> moveFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return false;
      }

      // Ensure destination directory exists
      await ensureDirectoryExists(path.dirname(destinationPath));

      await sourceFile.rename(destinationPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get temporary file path
  static Future<String> getTempFilePath(String fileName) async {
    final tempDir = Directory.systemTemp;
    final sanitizedName = sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(tempDir.path, '${timestamp}_$sanitizedName');
  }

  /// Read file as bytes
  static Future<Uint8List?> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Write bytes to file
  static Future<bool> writeBytesToFile(Uint8List bytes, String filePath) async {
    try {
      // Ensure directory exists
      await ensureDirectoryExists(path.dirname(filePath));

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file creation time
  static Future<DateTime?> getFileCreationTime(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.changed;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get file modification time
  static Future<DateTime?> getFileModificationTime(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get available disk space
  static Future<int?> getAvailableDiskSpace(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        // This is platform-specific and would need platform channels
        // For now, return null - can be implemented with platform-specific code
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clean up old temporary files
  static Future<void> cleanupOldTempFiles({int maxAgeHours = 24}) async {
    try {
      final tempDir = Directory.systemTemp;
      final cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeHours));

      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.changed.isBefore(cutoffTime)) {
            try {
              await entity.delete();
            } catch (e) {
              // Ignore errors when deleting temp files
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}

/// Result class for file validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.success() => const ValidationResult._(true, null);

  factory ValidationResult.failure(String errorMessage) =>
      ValidationResult._(false, errorMessage);

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errorMessage: $errorMessage)';
  }
}
