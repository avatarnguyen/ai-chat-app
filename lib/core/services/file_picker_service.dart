import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../utils/file_utils.dart';

/// Service for picking files and images from device storage
class FilePickerService {
  final FilePicker _filePicker = FilePicker.platform;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick single file for attachment
  Future<FilePickResult> pickFile({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    FileType fileType = FileType.any,
  }) async {
    try {
      final result = await _filePicker.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return FilePickResult.cancelled();
      }

      final List<PickedFileInfo> pickedFiles = [];

      for (final platformFile in result.files) {
        if (platformFile.path == null) {
          continue;
        }

        final filePath = platformFile.path!;
        final validation = FileUtils.validateAttachment(filePath);

        final pickedFile = PickedFileInfo(
          path: filePath,
          name: platformFile.name,
          size: platformFile.size,
          extension: platformFile.extension,
          isValid: validation.isValid,
          errorMessage: validation.errorMessage,
        );

        pickedFiles.add(pickedFile);
      }

      return FilePickResult.success(pickedFiles);
    } catch (e) {
      return FilePickResult.error('Failed to pick file: ${e.toString()}');
    }
  }

  /// Pick multiple files for attachments
  Future<FilePickResult> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType fileType = FileType.any,
    int? maxFiles,
  }) async {
    return pickFile(
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
      fileType: fileType,
    );
  }

  /// Pick image from gallery
  Future<FilePickResult> pickImageFromGallery({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = false,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata,
      );

      if (image == null) {
        return FilePickResult.cancelled();
      }

      final filePath = image.path;
      final fileSize = await image.length();
      final fileName = path.basename(filePath);

      final validation = FileUtils.validateAttachment(filePath);

      final pickedFile = PickedFileInfo(
        path: filePath,
        name: fileName,
        size: fileSize,
        extension: path.extension(fileName),
        isValid: validation.isValid,
        errorMessage: validation.errorMessage,
      );

      return FilePickResult.success([pickedFile]);
    } catch (e) {
      return FilePickResult.error('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick image from camera
  Future<FilePickResult> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return pickImageFromGallery(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick video from gallery
  Future<FilePickResult> pickVideoFromGallery({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (video == null) {
        return FilePickResult.cancelled();
      }

      final filePath = video.path;
      final fileSize = await video.length();
      final fileName = path.basename(filePath);

      final validation = FileUtils.validateAttachment(filePath);

      final pickedFile = PickedFileInfo(
        path: filePath,
        name: fileName,
        size: fileSize,
        extension: path.extension(fileName),
        isValid: validation.isValid,
        errorMessage: validation.errorMessage,
      );

      return FilePickResult.success([pickedFile]);
    } catch (e) {
      return FilePickResult.error('Failed to pick video: ${e.toString()}');
    }
  }

  /// Pick video from camera
  Future<FilePickResult> pickVideoFromCamera({
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return pickVideoFromGallery(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );
  }

  /// Pick avatar image with specific constraints
  Future<FilePickResult> pickAvatar({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double maxWidth = 512,
    double maxHeight = 512,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (image == null) {
        return FilePickResult.cancelled();
      }

      final filePath = image.path;
      final fileSize = await image.length();
      final fileName = path.basename(filePath);

      final validation = FileUtils.validateAvatar(filePath);

      final pickedFile = PickedFileInfo(
        path: filePath,
        name: fileName,
        size: fileSize,
        extension: path.extension(fileName),
        isValid: validation.isValid,
        errorMessage: validation.errorMessage,
      );

      return FilePickResult.success([pickedFile]);
    } catch (e) {
      return FilePickResult.error('Failed to pick avatar: ${e.toString()}');
    }
  }

  /// Pick documents (PDF, DOC, etc.)
  Future<FilePickResult> pickDocuments({bool allowMultiple = false}) async {
    return pickFile(
      fileType: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'md',
        'csv',
      ],
      allowMultiple: allowMultiple,
    );
  }

  /// Pick images only
  Future<FilePickResult> pickImages({bool allowMultiple = false}) async {
    return pickFile(fileType: FileType.image, allowMultiple: allowMultiple);
  }

  /// Pick audio files
  Future<FilePickResult> pickAudio({bool allowMultiple = false}) async {
    return pickFile(fileType: FileType.audio, allowMultiple: allowMultiple);
  }

  /// Pick video files
  Future<FilePickResult> pickVideos({bool allowMultiple = false}) async {
    return pickFile(fileType: FileType.video, allowMultiple: allowMultiple);
  }

  /// Show file picker options dialog
  Future<FilePickResult> showFilePickerOptions({
    required bool allowImages,
    required bool allowDocuments,
    required bool allowAudio,
    required bool allowVideo,
    required bool allowCamera,
    bool allowMultiple = false,
  }) async {
    // This method would show a custom dialog with different file picking options
    // For now, default to any file type
    return pickFile(allowMultiple: allowMultiple);
  }

  /// Get file type from extension
  static FileType getFileTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return FileType.image;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.webm':
        return FileType.video;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.ogg':
      case '.m4a':
        return FileType.audio;
      default:
        return FileType.any;
    }
  }

  /// Check if multiple file selection is supported
  bool get supportsMultipleSelection => true;

  /// Check if camera is available
  Future<bool> get isCameraAvailable async {
    try {
      // Try to get available cameras
      // ImagePicker doesn't have getAvailableCameras method
      // Instead, we'll try to pick an image to test camera availability
      final XFile? testImage = await _imagePicker
          .pickImage(
            source: ImageSource.camera,
            maxWidth: 1,
            maxHeight: 1,
            imageQuality: 1,
          )
          .catchError((_) => null);
      final cameras = testImage != null ? ['camera'] : <String>[];
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Information about a picked file
class PickedFileInfo {
  final String path;
  final String name;
  final int size;
  final String? extension;
  final bool isValid;
  final String? errorMessage;

  const PickedFileInfo({
    required this.path,
    required this.name,
    required this.size,
    this.extension,
    required this.isValid,
    this.errorMessage,
  });

  /// Get formatted file size
  String get formattedSize => FileUtils.formatFileSize(size);

  /// Get file type category
  String get fileType {
    final mimeType = FileUtils.getMimeType(path);
    return mimeType != null ? FileUtils.getFileTypeCategory(mimeType) : 'other';
  }

  /// Check if file is an image
  bool get isImage => fileType == 'image';

  /// Check if file is a document
  bool get isDocument => fileType == 'document';

  /// Check if file is audio
  bool get isAudio => fileType == 'audio';

  /// Check if file is video
  bool get isVideo => fileType == 'video';

  @override
  String toString() {
    return 'PickedFileInfo(name: $name, size: $size, isValid: $isValid)';
  }
}

/// Result of file picking operation
class FilePickResult {
  final bool success;
  final List<PickedFileInfo> files;
  final String? errorMessage;
  final bool cancelled;

  const FilePickResult._({
    required this.success,
    required this.files,
    this.errorMessage,
    required this.cancelled,
  });

  /// Create successful result
  factory FilePickResult.success(List<PickedFileInfo> files) {
    return FilePickResult._(success: true, files: files, cancelled: false);
  }

  /// Create error result
  factory FilePickResult.error(String errorMessage) {
    return FilePickResult._(
      success: false,
      files: [],
      errorMessage: errorMessage,
      cancelled: false,
    );
  }

  /// Create cancelled result
  factory FilePickResult.cancelled() {
    return const FilePickResult._(success: false, files: [], cancelled: true);
  }

  /// Get the first picked file (for single file picking)
  PickedFileInfo? get singleFile => files.isNotEmpty ? files.first : null;

  /// Get all valid files
  List<PickedFileInfo> get validFiles =>
      files.where((file) => file.isValid).toList();

  /// Get all invalid files
  List<PickedFileInfo> get invalidFiles =>
      files.where((file) => !file.isValid).toList();

  /// Check if any files were picked
  bool get hasFiles => files.isNotEmpty;

  /// Check if all picked files are valid
  bool get allFilesValid => files.isNotEmpty && files.every((f) => f.isValid);

  @override
  String toString() {
    return 'FilePickResult(success: $success, filesCount: ${files.length}, '
        'cancelled: $cancelled, errorMessage: $errorMessage)';
  }
}
