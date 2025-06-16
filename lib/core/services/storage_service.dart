import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:crypto/crypto.dart';
import '../constants/storage_constants.dart';
import '../models/file_attachment.dart';

/// Service for handling file uploads and downloads with Supabase Storage
class StorageService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  StorageService(this._supabase);

  /// Upload a file attachment to Supabase Storage
  Future<FileUploadResult> uploadAttachment({
    required String filePath,
    required String conversationId,
    required String messageId,
    String? customFileName,
    Map<String, dynamic>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        return FileUploadResult.failure(StorageConstants.errorFileNotFound);
      }

      // Get file info
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      final originalFileName = customFileName ?? path.basename(filePath);
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      // Validate file type
      if (!StorageConstants.isAllowedAttachmentType(mimeType)) {
        return FileUploadResult.failure(StorageConstants.errorInvalidFileType);
      }

      // Validate file size
      if (!StorageConstants.isValidAttachmentSize(fileSize)) {
        return FileUploadResult.failure(StorageConstants.errorFileTooLarge);
      }

      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return FileUploadResult.failure('User not authenticated');
      }

      // Generate unique file name
      final fileId = _uuid.v4();
      final fileName = StorageConstants.generateUniqueFileName(
        originalFileName,
      );
      final storagePath = StorageConstants.getChatAttachmentPath(
        userId,
        conversationId,
        messageId,
        fileName,
      );

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(StorageConstants.chatAttachmentsBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      // Create file attachment object
      final attachment = FileAttachment(
        id: fileId,
        fileName: originalFileName,
        fileSize: fileSize,
        mimeType: mimeType,
        bucketId: StorageConstants.chatAttachmentsBucket,
        storagePath: storagePath,
        fileType: StorageConstants.getFileTypeCategory(mimeType),
        uploadedAt: DateTime.now(),
        metadata: {
          'originalPath': filePath,
          'hash': sha256.convert(fileBytes).toString(),
          ...?metadata,
        },
        isUploaded: true,
        uploadProgress: 1.0,
      );

      stopwatch.stop();
      return FileUploadResult.success(
        attachment,
        uploadDuration: stopwatch.elapsed,
      );
    } catch (e) {
      return FileUploadResult.failure(
        '${StorageConstants.errorUploadFailed}: ${e.toString()}',
      );
    }
  }

  /// Upload file from bytes (useful for in-memory files)
  Future<FileUploadResult> uploadAttachmentFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String conversationId,
    required String messageId,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final fileSize = fileBytes.length;
      final detectedMimeType =
          mimeType ?? lookupMimeType(fileName) ?? 'application/octet-stream';

      // Validate file type
      if (!StorageConstants.isAllowedAttachmentType(detectedMimeType)) {
        return FileUploadResult.failure(StorageConstants.errorInvalidFileType);
      }

      // Validate file size
      if (!StorageConstants.isValidAttachmentSize(fileSize)) {
        return FileUploadResult.failure(StorageConstants.errorFileTooLarge);
      }

      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return FileUploadResult.failure('User not authenticated');
      }

      // Generate unique file name
      final fileId = _uuid.v4();
      final uniqueFileName = StorageConstants.generateUniqueFileName(fileName);
      final storagePath = StorageConstants.getChatAttachmentPath(
        userId,
        conversationId,
        messageId,
        uniqueFileName,
      );

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(StorageConstants.chatAttachmentsBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: detectedMimeType,
            ),
          );

      // Create file attachment object
      final attachment = FileAttachment(
        id: fileId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: detectedMimeType,
        bucketId: StorageConstants.chatAttachmentsBucket,
        storagePath: storagePath,
        fileType: StorageConstants.getFileTypeCategory(detectedMimeType),
        uploadedAt: DateTime.now(),
        metadata: {'hash': sha256.convert(fileBytes).toString(), ...?metadata},
        isUploaded: true,
        uploadProgress: 1.0,
      );

      stopwatch.stop();
      return FileUploadResult.success(
        attachment,
        uploadDuration: stopwatch.elapsed,
      );
    } catch (e) {
      return FileUploadResult.failure(
        '${StorageConstants.errorUploadFailed}: ${e.toString()}',
      );
    }
  }

  /// Upload avatar image
  Future<FileUploadResult> uploadAvatar({
    required String filePath,
    String? customFileName,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        return FileUploadResult.failure(StorageConstants.errorFileNotFound);
      }

      // Get file info
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      final originalFileName = customFileName ?? path.basename(filePath);
      final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';

      // Validate file type
      if (!StorageConstants.isAllowedAvatarType(mimeType)) {
        return FileUploadResult.failure(StorageConstants.errorInvalidFileType);
      }

      // Validate file size
      if (!StorageConstants.isValidAvatarSize(fileSize)) {
        return FileUploadResult.failure(StorageConstants.errorFileTooLarge);
      }

      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return FileUploadResult.failure('User not authenticated');
      }

      // Generate unique file name
      final fileId = _uuid.v4();
      final fileName = StorageConstants.generateUniqueFileName(
        originalFileName,
      );
      final storagePath = StorageConstants.getAvatarPath(userId, fileName);

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(StorageConstants.avatarsBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: mimeType,
            ),
          );

      // Get public URL for avatar
      final publicUrl = _supabase.storage
          .from(StorageConstants.avatarsBucket)
          .getPublicUrl(storagePath);

      // Create file attachment object
      final attachment = FileAttachment(
        id: fileId,
        fileName: originalFileName,
        fileSize: fileSize,
        mimeType: mimeType,
        bucketId: StorageConstants.avatarsBucket,
        storagePath: storagePath,
        publicUrl: publicUrl,
        fileType: StorageConstants.getFileTypeCategory(mimeType),
        uploadedAt: DateTime.now(),
        metadata: {
          'originalPath': filePath,
          'hash': sha256.convert(fileBytes).toString(),
        },
        isUploaded: true,
        uploadProgress: 1.0,
      );

      stopwatch.stop();
      return FileUploadResult.success(
        attachment,
        uploadDuration: stopwatch.elapsed,
      );
    } catch (e) {
      return FileUploadResult.failure(
        '${StorageConstants.errorUploadFailed}: ${e.toString()}',
      );
    }
  }

  /// Download file attachment
  Future<FileDownloadResult> downloadAttachment({
    required FileAttachment attachment,
    required String localPath,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Download file from Supabase Storage
      final fileBytes = await _supabase.storage
          .from(attachment.bucketId)
          .download(attachment.storagePath);

      // Save file to local path
      final file = File(localPath);
      await file.create(recursive: true);
      await file.writeAsBytes(fileBytes);

      stopwatch.stop();
      return FileDownloadResult.success(
        localPath,
        downloadDuration: stopwatch.elapsed,
        fileSize: fileBytes.length,
      );
    } catch (e) {
      return FileDownloadResult.failure(
        '${StorageConstants.errorDownloadFailed}: ${e.toString()}',
      );
    }
  }

  /// Get signed URL for private file
  Future<String?> getSignedUrl({
    required String bucketId,
    required String storagePath,
    int expiresIn = 3600, // 1 hour default
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucketId)
          .createSignedUrl(storagePath, expiresIn);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  /// Get public URL for public file
  String getPublicUrl({required String bucketId, required String storagePath}) {
    return _supabase.storage.from(bucketId).getPublicUrl(storagePath);
  }

  /// Delete file attachment
  Future<bool> deleteAttachment({
    required String bucketId,
    required String storagePath,
  }) async {
    try {
      await _supabase.storage.from(bucketId).remove([storagePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List files in a folder
  Future<List<FileObject>> listFiles({
    required String bucketId,
    String? folderPath,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final files = await _supabase.storage
          .from(bucketId)
          .list(
            path: folderPath,
            searchOptions: const SearchOptions(limit: 100, offset: 0),
          );
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata({
    required String bucketId,
    required String storagePath,
  }) async {
    try {
      final files = await _supabase.storage
          .from(bucketId)
          .list(path: path.dirname(storagePath));

      final fileName = path.basename(storagePath);
      final file = files.firstWhere(
        (f) => f.name == fileName,
        orElse: () => throw Exception('File not found'),
      );

      return {
        'name': file.name,
        'size': file.metadata?['size'],
        'mimetype': file.metadata?['mimetype'],
        'lastModified': file.updatedAt,
        'created': file.createdAt,
      };
    } catch (e) {
      return null;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    // This method can be implemented to clean up temporary local files
    // that may have been created during upload/download operations
  }

  /// Get storage usage statistics for current user
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'error': 'User not authenticated'};
      }

      // Get files from chat attachments bucket
      final attachments = await listFiles(
        bucketId: StorageConstants.chatAttachmentsBucket,
        folderPath: userId,
      );

      // Get files from avatars bucket
      final avatars = await listFiles(
        bucketId: StorageConstants.avatarsBucket,
        folderPath: userId,
      );

      // Calculate total size
      int totalSize = 0;
      int attachmentCount = 0;
      int avatarCount = 0;

      for (final file in attachments) {
        final size = file.metadata?['size'] as int? ?? 0;
        totalSize += size;
        attachmentCount++;
      }

      for (final file in avatars) {
        final size = file.metadata?['size'] as int? ?? 0;
        totalSize += size;
        avatarCount++;
      }

      return {
        'totalSize': totalSize,
        'formattedSize': StorageConstants.formatFileSize(totalSize),
        'attachmentCount': attachmentCount,
        'avatarCount': avatarCount,
        'totalFiles': attachmentCount + avatarCount,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Validate file before upload
  bool validateFile({
    required String filePath,
    required String fileType, // 'attachment' or 'avatar'
  }) {
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      return false;
    }

    // Get file info
    final fileSize = file.lengthSync();
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    // Validate based on file type
    if (fileType == 'attachment') {
      return StorageConstants.isAllowedAttachmentType(mimeType) &&
          StorageConstants.isValidAttachmentSize(fileSize);
    } else if (fileType == 'avatar') {
      return StorageConstants.isAllowedAvatarType(mimeType) &&
          StorageConstants.isValidAvatarSize(fileSize);
    }

    return false;
  }

  /// Create thumbnail for image/video files
  Future<String?> createThumbnail({
    required FileAttachment attachment,
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    // This method would implement thumbnail generation
    // For now, return null - can be implemented later with image processing
    return null;
  }
}
