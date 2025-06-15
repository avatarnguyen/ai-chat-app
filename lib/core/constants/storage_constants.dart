/// Storage constants for file attachments and Supabase storage configuration
class StorageConstants {
  StorageConstants._();

  // Storage bucket names
  static const String chatAttachmentsBucket = 'chat-attachments';
  static const String avatarsBucket = 'avatars';
  static const String conversationExportsBucket = 'conversation-exports';

  // File size limits (in bytes)
  static const int maxAttachmentSize = 52428800; // 50MB
  static const int maxAvatarSize = 5242880; // 5MB
  static const int maxExportSize = 104857600; // 100MB

  // Allowed MIME types for attachments
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml',
  ];

  static const List<String> allowedDocumentTypes = [
    'text/plain',
    'text/markdown',
    'text/csv',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/json',
    'application/xml',
  ];

  static const List<String> allowedArchiveTypes = [
    'application/zip',
    'application/x-zip-compressed',
  ];

  static const List<String> allowedAudioTypes = [
    'audio/mpeg',
    'audio/wav',
    'audio/ogg',
    'audio/webm',
  ];

  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  static const List<String> allowedAvatarTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedExportTypes = [
    'application/json',
    'text/markdown',
    'application/pdf',
    'text/csv',
    'application/zip',
  ];

  // Combined list of all allowed attachment types
  static List<String> get allAllowedAttachmentTypes => [
    ...allowedImageTypes,
    ...allowedDocumentTypes,
    ...allowedArchiveTypes,
    ...allowedAudioTypes,
    ...allowedVideoTypes,
  ];

  // File extensions mapping
  static const Map<String, String> mimeTypeToExtension = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/svg+xml': '.svg',
    'text/plain': '.txt',
    'text/markdown': '.md',
    'text/csv': '.csv',
    'application/pdf': '.pdf',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        '.docx',
    'application/vnd.ms-excel': '.xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        '.xlsx',
    'application/vnd.ms-powerpoint': '.ppt',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        '.pptx',
    'application/json': '.json',
    'application/xml': '.xml',
    'application/zip': '.zip',
    'application/x-zip-compressed': '.zip',
    'audio/mpeg': '.mp3',
    'audio/wav': '.wav',
    'audio/ogg': '.ogg',
    'audio/webm': '.webm',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
    'video/quicktime': '.mov',
  };

  // Storage path patterns
  static String getChatAttachmentPath(
    String userId,
    String conversationId,
    String messageId,
    String fileName,
  ) => '$chatAttachmentsBucket/$userId/$conversationId/$messageId/$fileName';

  static String getAvatarPath(String userId, String fileName) =>
      '$avatarsBucket/$userId/$fileName';

  static String getConversationExportPath(
    String userId,
    String exportId,
    String fileName,
  ) => '$conversationExportsBucket/$userId/$exportId/$fileName';

  // File type categories
  static const String fileTypeImage = 'image';
  static const String fileTypeDocument = 'document';
  static const String fileTypeArchive = 'archive';
  static const String fileTypeAudio = 'audio';
  static const String fileTypeVideo = 'video';
  static const String fileTypeOther = 'other';

  /// Get file type category based on MIME type
  static String getFileTypeCategory(String mimeType) {
    if (allowedImageTypes.contains(mimeType)) {
      return fileTypeImage;
    } else if (allowedDocumentTypes.contains(mimeType)) {
      return fileTypeDocument;
    } else if (allowedArchiveTypes.contains(mimeType)) {
      return fileTypeArchive;
    } else if (allowedAudioTypes.contains(mimeType)) {
      return fileTypeAudio;
    } else if (allowedVideoTypes.contains(mimeType)) {
      return fileTypeVideo;
    } else {
      return fileTypeOther;
    }
  }

  /// Check if file type is allowed for attachments
  static bool isAllowedAttachmentType(String mimeType) {
    return allAllowedAttachmentTypes.contains(mimeType);
  }

  /// Check if file type is allowed for avatars
  static bool isAllowedAvatarType(String mimeType) {
    return allowedAvatarTypes.contains(mimeType);
  }

  /// Check if file size is within limits for attachments
  static bool isValidAttachmentSize(int sizeInBytes) {
    return sizeInBytes <= maxAttachmentSize;
  }

  /// Check if file size is within limits for avatars
  static bool isValidAvatarSize(int sizeInBytes) {
    return sizeInBytes <= maxAvatarSize;
  }

  /// Format file size to human readable string
  static String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension from MIME type
  static String getFileExtension(String mimeType) {
    return mimeTypeToExtension[mimeType] ?? '';
  }

  /// Generate unique file name with timestamp
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension =
        originalName.contains('.')
            ? originalName.substring(originalName.lastIndexOf('.'))
            : '';
    final nameWithoutExtension =
        originalName.contains('.')
            ? originalName.substring(0, originalName.lastIndexOf('.'))
            : originalName;

    return '${nameWithoutExtension}_$timestamp$extension';
  }

  // Error messages
  static const String errorFileTooLarge = 'File size exceeds the maximum limit';
  static const String errorInvalidFileType = 'File type is not supported';
  static const String errorUploadFailed = 'Failed to upload file';
  static const String errorDownloadFailed = 'Failed to download file';
  static const String errorDeleteFailed = 'Failed to delete file';
  static const String errorFileNotFound = 'File not found';
  static const String errorInvalidPath = 'Invalid file path';
  static const String errorStoragePermission = 'Storage permission denied';
  static const String errorNetworkConnection = 'Network connection error';

  // Success messages
  static const String successFileUploaded = 'File uploaded successfully';
  static const String successFileDeleted = 'File deleted successfully';
  static const String successFileDownloaded = 'File downloaded successfully';
}
