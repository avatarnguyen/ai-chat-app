import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'file_attachment.g.dart';

/// Model representing a file attachment in chat messages
@JsonSerializable()
class FileAttachment extends Equatable {
  /// Unique identifier for the attachment
  final String id;

  /// Original file name
  final String fileName;

  /// File size in bytes
  final int fileSize;

  /// MIME type of the file
  final String mimeType;

  /// Storage bucket where the file is stored
  final String bucketId;

  /// Full storage path to the file
  final String storagePath;

  /// Public URL for the file (if applicable)
  final String? publicUrl;

  /// Temporary signed URL for private files
  final String? signedUrl;

  /// File type category (image, document, audio, video, etc.)
  final String fileType;

  /// Thumbnail URL for images/videos
  final String? thumbnailUrl;

  /// File upload timestamp
  final DateTime uploadedAt;

  /// File metadata (width, height for images, duration for videos, etc.)
  final Map<String, dynamic>? metadata;

  /// Whether the file upload is complete
  final bool isUploaded;

  /// Upload progress (0.0 to 1.0)
  final double uploadProgress;

  /// Error message if upload failed
  final String? errorMessage;

  const FileAttachment({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.bucketId,
    required this.storagePath,
    this.publicUrl,
    this.signedUrl,
    required this.fileType,
    this.thumbnailUrl,
    required this.uploadedAt,
    this.metadata,
    this.isUploaded = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  /// Factory constructor from JSON
  factory FileAttachment.fromJson(Map<String, dynamic> json) =>
      _$FileAttachmentFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$FileAttachmentToJson(this);

  /// Create a copy with updated properties
  FileAttachment copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? bucketId,
    String? storagePath,
    String? publicUrl,
    String? signedUrl,
    String? fileType,
    String? thumbnailUrl,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
    bool? isUploaded,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      bucketId: bucketId ?? this.bucketId,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      signedUrl: signedUrl ?? this.signedUrl,
      fileType: fileType ?? this.fileType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      metadata: metadata ?? this.metadata,
      isUploaded: isUploaded ?? this.isUploaded,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get human-readable file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension from file name
  String get fileExtension {
    final index = fileName.lastIndexOf('.');
    return index != -1 ? fileName.substring(index) : '';
  }

  /// Check if file is an image
  bool get isImage => fileType == 'image';

  /// Check if file is a document
  bool get isDocument => fileType == 'document';

  /// Check if file is audio
  bool get isAudio => fileType == 'audio';

  /// Check if file is video
  bool get isVideo => fileType == 'video';

  /// Check if file is an archive
  bool get isArchive => fileType == 'archive';

  /// Check if file has a thumbnail
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  /// Check if upload is in progress
  bool get isUploading => !isUploaded && errorMessage == null;

  /// Check if upload failed
  bool get hasUploadError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Get the URL to use for displaying/downloading the file
  String? get displayUrl => publicUrl ?? signedUrl;

  @override
  List<Object?> get props => [
    id,
    fileName,
    fileSize,
    mimeType,
    bucketId,
    storagePath,
    publicUrl,
    signedUrl,
    fileType,
    thumbnailUrl,
    uploadedAt,
    metadata,
    isUploaded,
    uploadProgress,
    errorMessage,
  ];

  @override
  String toString() {
    return 'FileAttachment(id: $id, fileName: $fileName, fileSize: $fileSize, '
        'mimeType: $mimeType, fileType: $fileType, isUploaded: $isUploaded, '
        'uploadProgress: $uploadProgress)';
  }
}

/// Model for file upload result
@JsonSerializable()
class FileUploadResult extends Equatable {
  /// Whether the upload was successful
  final bool success;

  /// The uploaded file attachment (if successful)
  final FileAttachment? attachment;

  /// Error message (if failed)
  final String? errorMessage;

  /// Upload duration
  final Duration? uploadDuration;

  const FileUploadResult({
    required this.success,
    this.attachment,
    this.errorMessage,
    this.uploadDuration,
  });

  /// Factory constructor from JSON
  factory FileUploadResult.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResultFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$FileUploadResultToJson(this);

  /// Create successful result
  factory FileUploadResult.success(
    FileAttachment attachment, {
    Duration? uploadDuration,
  }) {
    return FileUploadResult(
      success: true,
      attachment: attachment,
      uploadDuration: uploadDuration,
    );
  }

  /// Create failed result
  factory FileUploadResult.failure(String errorMessage) {
    return FileUploadResult(success: false, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [
    success,
    attachment,
    errorMessage,
    uploadDuration,
  ];

  @override
  String toString() {
    return 'FileUploadResult(success: $success, errorMessage: $errorMessage)';
  }
}

/// Model for file download result
@JsonSerializable()
class FileDownloadResult extends Equatable {
  /// Whether the download was successful
  final bool success;

  /// Local file path (if successful)
  final String? localPath;

  /// Error message (if failed)
  final String? errorMessage;

  /// Download duration
  final Duration? downloadDuration;

  /// Downloaded file size
  final int? fileSize;

  const FileDownloadResult({
    required this.success,
    this.localPath,
    this.errorMessage,
    this.downloadDuration,
    this.fileSize,
  });

  /// Factory constructor from JSON
  factory FileDownloadResult.fromJson(Map<String, dynamic> json) =>
      _$FileDownloadResultFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$FileDownloadResultToJson(this);

  /// Create successful result
  factory FileDownloadResult.success(
    String localPath, {
    Duration? downloadDuration,
    int? fileSize,
  }) {
    return FileDownloadResult(
      success: true,
      localPath: localPath,
      downloadDuration: downloadDuration,
      fileSize: fileSize,
    );
  }

  /// Create failed result
  factory FileDownloadResult.failure(String errorMessage) {
    return FileDownloadResult(success: false, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [
    success,
    localPath,
    errorMessage,
    downloadDuration,
    fileSize,
  ];

  @override
  String toString() {
    return 'FileDownloadResult(success: $success, localPath: $localPath, '
        'errorMessage: $errorMessage)';
  }
}
