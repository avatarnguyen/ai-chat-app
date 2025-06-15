import 'package:flutter/material.dart';

import '../../../core/models/file_attachment.dart';
import '../../../core/services/attachment_service.dart';

/// Widget for picking and uploading file attachments
class AttachmentPickerWidget extends StatefulWidget {
  final String conversationId;
  final String messageId;
  final AttachmentService attachmentService;
  final void Function(List<FileAttachment> attachments)? onAttachmentsSelected;
  final void Function(String error)? onError;
  final bool allowMultiple;
  final AttachmentType allowedType;

  const AttachmentPickerWidget({
    super.key,
    required this.conversationId,
    required this.messageId,
    required this.attachmentService,
    this.onAttachmentsSelected,
    this.onError,
    this.allowMultiple = true,
    this.allowedType = AttachmentType.any,
  });

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  final Map<String, double> _uploadProgress = {};
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAttachmentOptions(),
          if (_isUploading) ...[
            const SizedBox(height: 16),
            _buildUploadProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Add Attachments',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (widget.allowedType != AttachmentType.any)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTypeLabel(widget.allowedType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentOptions() {
    if (widget.allowedType != AttachmentType.any) {
      return _buildSingleTypeOptions();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildOptionButton(
          icon: Icons.photo,
          label: 'Photos',
          onTap: () => _pickAttachments(AttachmentType.image),
          color: Colors.green,
        ),
        _buildOptionButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: _pickFromCamera,
          color: Colors.blue,
        ),
        _buildOptionButton(
          icon: Icons.description,
          label: 'Documents',
          onTap: () => _pickAttachments(AttachmentType.document),
          color: Colors.orange,
        ),
        _buildOptionButton(
          icon: Icons.audiotrack,
          label: 'Audio',
          onTap: () => _pickAttachments(AttachmentType.audio),
          color: Colors.purple,
        ),
        _buildOptionButton(
          icon: Icons.videocam,
          label: 'Video',
          onTap: () => _pickAttachments(AttachmentType.video),
          color: Colors.red,
        ),
        _buildOptionButton(
          icon: Icons.folder,
          label: 'Any File',
          onTap: () => _pickAttachments(AttachmentType.any),
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSingleTypeOptions() {
    switch (widget.allowedType) {
      case AttachmentType.image:
        return Row(
          children: [
            Expanded(
              child: _buildOptionButton(
                icon: Icons.photo_library,
                label: 'From Gallery',
                onTap: () => _pickAttachments(AttachmentType.image),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionButton(
                icon: Icons.camera_alt,
                label: 'From Camera',
                onTap: _pickFromCamera,
                color: Colors.blue,
              ),
            ),
          ],
        );
      default:
        return _buildOptionButton(
          icon: _getTypeIcon(widget.allowedType),
          label: 'Select ${_getTypeLabel(widget.allowedType)}',
          onTap: () => _pickAttachments(widget.allowedType),
          color: _getTypeColor(widget.allowedType),
        );
    }
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Uploading files...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._uploadProgress.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(entry.value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAttachments(AttachmentType type) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress.clear();
    });

    try {
      final result = await widget.attachmentService.pickAndUploadAttachments(
        conversationId: widget.conversationId,
        messageId: widget.messageId,
        allowMultiple: widget.allowMultiple,
        type: type,
        onProgress: (fileId, progress) {
          setState(() {
            _uploadProgress[fileId] = progress;
          });
        },
      );

      if (result.success) {
        widget.onAttachmentsSelected?.call(result.attachments);
        if (result.hasWarnings) {
          _showWarnings(result.warnings!);
        }
      } else if (result.cancelled) {
        // User cancelled, do nothing
      } else {
        widget.onError?.call(
          result.errorMessage ?? 'Failed to upload attachments',
        );
      }
    } catch (e) {
      widget.onError?.call('Error picking attachments: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress.clear();
      });
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress.clear();
    });

    try {
      final result = await widget.attachmentService
          .pickImageFromCameraAndUpload(
            conversationId: widget.conversationId,
            messageId: widget.messageId,
            onProgress: (progress) {
              setState(() {
                _uploadProgress['Camera Image'] = progress;
              });
            },
          );

      if (result.success) {
        widget.onAttachmentsSelected?.call(result.attachments);
      } else if (result.cancelled) {
        // User cancelled, do nothing
      } else {
        widget.onError?.call(
          result.errorMessage ?? 'Failed to capture and upload image',
        );
      }
    } catch (e) {
      widget.onError?.call('Error capturing image: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress.clear();
      });
    }
  }

  void _showWarnings(List<String> warnings) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Upload Warnings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  warnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(warning)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getTypeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'Images';
      case AttachmentType.document:
        return 'Documents';
      case AttachmentType.audio:
        return 'Audio';
      case AttachmentType.video:
        return 'Videos';
      case AttachmentType.avatar:
        return 'Avatar';
      case AttachmentType.any:
        return 'Files';
    }
  }

  IconData _getTypeIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.audio:
        return Icons.audiotrack;
      case AttachmentType.video:
        return Icons.videocam;
      case AttachmentType.avatar:
        return Icons.account_circle;
      case AttachmentType.any:
        return Icons.attach_file;
    }
  }

  Color _getTypeColor(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Colors.green;
      case AttachmentType.document:
        return Colors.orange;
      case AttachmentType.audio:
        return Colors.purple;
      case AttachmentType.video:
        return Colors.red;
      case AttachmentType.avatar:
        return Colors.blue;
      case AttachmentType.any:
        return Colors.grey;
    }
  }
}

/// Widget to display uploaded attachments
class AttachmentListWidget extends StatelessWidget {
  final List<FileAttachment> attachments;
  final AttachmentService attachmentService;
  final void Function(FileAttachment attachment)? onRemove;
  final void Function(FileAttachment attachment)? onTap;
  final bool showRemoveButton;

  const AttachmentListWidget({
    super.key,
    required this.attachments,
    required this.attachmentService,
    this.onRemove,
    this.onTap,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${attachments.length})',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...attachments.map(
          (attachment) => _buildAttachmentItem(context, attachment),
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(BuildContext context, FileAttachment attachment) {
    final preview = attachmentService.getAttachmentPreview(attachment);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // File type icon or thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(attachment.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                preview.thumbnailUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        preview.thumbnailUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildFileIcon(attachment),
                      ),
                    )
                    : _buildFileIcon(attachment),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  preview.displaySize,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preview.canPreview)
                IconButton(
                  icon: const Icon(Icons.visibility),
                  iconSize: 20,
                  onPressed: () => onTap?.call(attachment),
                  tooltip: 'Preview',
                ),
              if (showRemoveButton)
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  onPressed: () => onRemove?.call(attachment),
                  tooltip: 'Remove',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(FileAttachment attachment) {
    return Icon(
      _getFileTypeIconData(attachment.fileType),
      color: _getFileTypeColor(attachment.fileType),
      size: 24,
    );
  }

  IconData _getFileTypeIconData(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType) {
      case 'image':
        return Colors.green;
      case 'document':
        return Colors.orange;
      case 'audio':
        return Colors.purple;
      case 'video':
        return Colors.red;
      case 'archive':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
