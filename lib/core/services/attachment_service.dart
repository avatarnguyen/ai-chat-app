import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/file_attachment.dart';
import '../utils/file_utils.dart';
import 'storage_service.dart';
import 'file_picker_service.dart';

/// Comprehensive service for handling file attachments in chat messages
class AttachmentService {
  final StorageService _storageService;
  final FilePickerService _filePickerService;

  AttachmentService({
    required StorageService storageService,
    required FilePickerService filePickerService,
  }) : _storageService = storageService,
       _filePickerService = filePickerService;

  /// Pick and upload file attachments for a message
  Future<AttachmentResult> pickAndUploadAttachments({
    required String conversationId,
    required String messageId,
    bool allowMultiple = true,
    AttachmentType type = AttachmentType.any,
    void Function(String fileId, double progress)? onProgress,
  }) async {
    try {
      // Pick files based on type
      FilePickResult pickResult;

      switch (type) {
        case AttachmentType.image:
          pickResult = await _filePickerService.pickImages(
            allowMultiple: allowMultiple,
          );
          break;
        case AttachmentType.document:
          pickResult = await _filePickerService.pickDocuments(
            allowMultiple: allowMultiple,
          );
          break;
        case AttachmentType.audio:
          pickResult = await _filePickerService.pickAudio(
            allowMultiple: allowMultiple,
          );
          break;
        case AttachmentType.video:
          pickResult = await _filePickerService.pickVideos(
            allowMultiple: allowMultiple,
          );
          break;
        case AttachmentType.any:
        default:
          pickResult = await _filePickerService.pickFile(
            allowMultiple: allowMultiple,
          );
          break;
      }

      if (pickResult.cancelled) {
        return AttachmentResult.cancelled();
      }

      if (!pickResult.success) {
        return AttachmentResult.failure(
          pickResult.errorMessage ?? 'Failed to pick files',
        );
      }

      if (pickResult.validFiles.isEmpty) {
        return AttachmentResult.failure('No valid files selected');
      }

      // Upload all valid files
      final List<FileAttachment> uploadedAttachments = [];
      final List<String> errors = [];

      for (final pickedFile in pickResult.validFiles) {
        try {
          final uploadResult = await _storageService.uploadAttachment(
            filePath: pickedFile.path,
            conversationId: conversationId,
            messageId: messageId,
            onProgress:
                onProgress != null
                    ? (progress) => onProgress(pickedFile.name, progress)
                    : null,
          );

          if (uploadResult.success && uploadResult.attachment != null) {
            uploadedAttachments.add(uploadResult.attachment!);
          } else {
            errors.add(
              'Failed to upload ${pickedFile.name}: ${uploadResult.errorMessage}',
            );
          }
        } catch (e) {
          errors.add('Failed to upload ${pickedFile.name}: ${e.toString()}');
        }
      }

      if (uploadedAttachments.isEmpty) {
        return AttachmentResult.failure(
          'Failed to upload any files: ${errors.join(', ')}',
        );
      }

      return AttachmentResult.success(
        attachments: uploadedAttachments,
        warnings: errors.isNotEmpty ? errors : null,
      );
    } catch (e) {
      return AttachmentResult.failure(
        'Failed to pick and upload attachments: ${e.toString()}',
      );
    }
  }

  /// Pick image from camera and upload
  Future<AttachmentResult> pickImageFromCameraAndUpload({
    required String conversationId,
    required String messageId,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final pickResult = await _filePickerService.pickImageFromCamera(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickResult.cancelled) {
        return AttachmentResult.cancelled();
      }

      if (!pickResult.success || pickResult.singleFile == null) {
        return AttachmentResult.failure(
          pickResult.errorMessage ?? 'Failed to capture image',
        );
      }

      final pickedFile = pickResult.singleFile!;
      if (!pickedFile.isValid) {
        return AttachmentResult.failure(
          pickedFile.errorMessage ?? 'Invalid image file',
        );
      }

      final uploadResult = await _storageService.uploadAttachment(
        filePath: pickedFile.path,
        conversationId: conversationId,
        messageId: messageId,
        onProgress: onProgress,
      );

      if (uploadResult.success && uploadResult.attachment != null) {
        return AttachmentResult.success(
          attachments: [uploadResult.attachment!],
        );
      } else {
        return AttachmentResult.failure(
          uploadResult.errorMessage ?? 'Failed to upload image',
        );
      }
    } catch (e) {
      return AttachmentResult.failure(
        'Failed to capture and upload image: ${e.toString()}',
      );
    }
  }

  /// Upload file from bytes (useful for programmatically created files)
  Future<FileUploadResult> uploadFileFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String conversationId,
    required String messageId,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) async {
    return _storageService.uploadAttachmentFromBytes(
      fileBytes: fileBytes,
      fileName: fileName,
      conversationId: conversationId,
      messageId: messageId,
      mimeType: mimeType,
      metadata: metadata,
    );
  }

  /// Get signed URL for private attachment
  Future<String?> getAttachmentUrl(FileAttachment attachment) async {
    if (attachment.publicUrl != null) {
      return attachment.publicUrl;
    }

    return _storageService.getSignedUrl(
      bucketId: attachment.bucketId,
      storagePath: attachment.storagePath,
      expiresIn: 3600, // 1 hour
    );
  }

  /// Download attachment to local storage
  Future<FileDownloadResult> downloadAttachment({
    required FileAttachment attachment,
    String? customLocalPath,
  }) async {
    try {
      final localPath =
          customLocalPath ??
          await FileUtils.getTempFilePath(attachment.fileName);

      return _storageService.downloadAttachment(
        attachment: attachment,
        localPath: localPath,
      );
    } catch (e) {
      return FileDownloadResult.failure(
        'Failed to download attachment: ${e.toString()}',
      );
    }
  }

  /// Delete attachment from storage
  Future<bool> deleteAttachment(FileAttachment attachment) async {
    return _storageService.deleteAttachment(
      bucketId: attachment.bucketId,
      storagePath: attachment.storagePath,
    );
  }

  /// Delete multiple attachments
  Future<Map<String, bool>> deleteMultipleAttachments(
    List<FileAttachment> attachments,
  ) async {
    final results = <String, bool>{};

    for (final attachment in attachments) {
      results[attachment.id] = await deleteAttachment(attachment);
    }

    return results;
  }

  /// Validate file before upload
  ValidationResult validateFileForUpload(
    String filePath, {
    AttachmentType type = AttachmentType.any,
  }) {
    switch (type) {
      case AttachmentType.image:
      case AttachmentType.document:
      case AttachmentType.audio:
      case AttachmentType.video:
      case AttachmentType.any:
        return FileUtils.validateAttachment(filePath);
      case AttachmentType.avatar:
        return FileUtils.validateAvatar(filePath);
    }
  }

  /// Get attachment preview info (for UI display)
  AttachmentPreview getAttachmentPreview(FileAttachment attachment) {
    return AttachmentPreview(
      attachment: attachment,
      displayName: attachment.fileName,
      displaySize: attachment.formattedFileSize,
      icon: _getFileTypeIcon(attachment.fileType),
      canPreview: _canPreviewFile(attachment),
      thumbnailUrl: attachment.thumbnailUrl,
    );
  }

  /// Get multiple attachment previews
  List<AttachmentPreview> getAttachmentPreviews(
    List<FileAttachment> attachments,
  ) {
    return attachments.map(getAttachmentPreview).toList();
  }

  /// Create thumbnail for image/video attachment
  Future<String?> createThumbnail(
    FileAttachment attachment, {
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    return _storageService.createThumbnail(
      attachment: attachment,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Get storage usage statistics
  Future<StorageUsageInfo> getStorageUsage() async {
    final usage = await _storageService.getStorageUsage();

    return StorageUsageInfo(
      totalSize: usage['totalSize'] ?? 0,
      formattedSize: usage['formattedSize'] ?? '0 B',
      attachmentCount: usage['attachmentCount'] ?? 0,
      avatarCount: usage['avatarCount'] ?? 0,
      totalFiles: usage['totalFiles'] ?? 0,
      hasError: usage.containsKey('error'),
      errorMessage: usage['error'],
    );
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    await _storageService.cleanupTempFiles();
    await FileUtils.cleanupOldTempFiles();
  }

  /// Batch upload multiple files
  Future<BatchUploadResult> batchUploadFiles({
    required List<String> filePaths,
    required String conversationId,
    required String messageId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final List<FileAttachment> successfulUploads = [];
    final List<String> failedUploads = [];
    int completed = 0;

    for (final filePath in filePaths) {
      try {
        final uploadResult = await _storageService.uploadAttachment(
          filePath: filePath,
          conversationId: conversationId,
          messageId: messageId,
        );

        if (uploadResult.success && uploadResult.attachment != null) {
          successfulUploads.add(uploadResult.attachment!);
        } else {
          failedUploads.add(
            '${path.basename(filePath)}: ${uploadResult.errorMessage}',
          );
        }
      } catch (e) {
        failedUploads.add('${path.basename(filePath)}: ${e.toString()}');
      }

      completed++;
      onProgress?.call(completed, filePaths.length);
    }

    return BatchUploadResult(
      successfulUploads: successfulUploads,
      failedUploads: failedUploads,
      totalFiles: filePaths.length,
      successCount: successfulUploads.length,
      failureCount: failedUploads.length,
    );
  }

  /// Check if file can be previewed in the app
  bool _canPreviewFile(FileAttachment attachment) {
    switch (attachment.fileType) {
      case 'image':
        return true;
      case 'document':
        return attachment.mimeType == 'text/plain' ||
            attachment.mimeType == 'text/markdown';
      case 'audio':
      case 'video':
        return true;
      default:
        return false;
    }
  }

  /// Get appropriate icon for file type
  String _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return '🖼️';
      case 'document':
        return '📄';
      case 'audio':
        return '🎵';
      case 'video':
        return '🎬';
      case 'archive':
        return '📦';
      default:
        return '📎';
    }
  }

  /// Upload avatar image
  Future<FileUploadResult> uploadAvatar(String filePath) async {
    return _storageService.uploadAvatar(filePath: filePath);
  }

  /// Get file picker service for direct access
  FilePickerService get filePickerService => _filePickerService;

  /// Get storage service for direct access
  StorageService get storageService => _storageService;
}

/// Enum for attachment types
enum AttachmentType { any, image, document, audio, video, avatar }

/// Result of attachment operations
class AttachmentResult {
  final bool success;
  final List<FileAttachment> attachments;
  final String? errorMessage;
  final List<String>? warnings;
  final bool cancelled;

  const AttachmentResult._({
    required this.success,
    required this.attachments,
    this.errorMessage,
    this.warnings,
    required this.cancelled,
  });

  factory AttachmentResult.success({
    required List<FileAttachment> attachments,
    List<String>? warnings,
  }) {
    return AttachmentResult._(
      success: true,
      attachments: attachments,
      warnings: warnings,
      cancelled: false,
    );
  }

  factory AttachmentResult.failure(String errorMessage) {
    return AttachmentResult._(
      success: false,
      attachments: [],
      errorMessage: errorMessage,
      cancelled: false,
    );
  }

  factory AttachmentResult.cancelled() {
    return const AttachmentResult._(
      success: false,
      attachments: [],
      cancelled: true,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasWarnings => warnings != null && warnings!.isNotEmpty;
  int get attachmentCount => attachments.length;

  @override
  String toString() {
    return 'AttachmentResult(success: $success, attachments: ${attachments.length}, '
        'cancelled: $cancelled, errorMessage: $errorMessage)';
  }
}

/// Preview information for an attachment
class AttachmentPreview {
  final FileAttachment attachment;
  final String displayName;
  final String displaySize;
  final String icon;
  final bool canPreview;
  final String? thumbnailUrl;

  const AttachmentPreview({
    required this.attachment,
    required this.displayName,
    required this.displaySize,
    required this.icon,
    required this.canPreview,
    this.thumbnailUrl,
  });

  @override
  String toString() {
    return 'AttachmentPreview(name: $displayName, size: $displaySize, '
        'canPreview: $canPreview)';
  }
}

/// Storage usage information
class StorageUsageInfo {
  final int totalSize;
  final String formattedSize;
  final int attachmentCount;
  final int avatarCount;
  final int totalFiles;
  final bool hasError;
  final String? errorMessage;

  const StorageUsageInfo({
    required this.totalSize,
    required this.formattedSize,
    required this.attachmentCount,
    required this.avatarCount,
    required this.totalFiles,
    required this.hasError,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'StorageUsageInfo(totalSize: $formattedSize, files: $totalFiles, '
        'hasError: $hasError)';
  }
}

/// Result of batch upload operation
class BatchUploadResult {
  final List<FileAttachment> successfulUploads;
  final List<String> failedUploads;
  final int totalFiles;
  final int successCount;
  final int failureCount;

  const BatchUploadResult({
    required this.successfulUploads,
    required this.failedUploads,
    required this.totalFiles,
    required this.successCount,
    required this.failureCount,
  });

  bool get hasFailures => failedUploads.isNotEmpty;
  bool get allSuccessful => failureCount == 0;
  double get successRate => totalFiles > 0 ? successCount / totalFiles : 0.0;

  @override
  String toString() {
    return 'BatchUploadResult(total: $totalFiles, success: $successCount, '
        'failed: $failureCount, rate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}
