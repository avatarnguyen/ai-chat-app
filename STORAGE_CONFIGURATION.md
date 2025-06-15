# File Attachment Storage Configuration

This document provides comprehensive documentation for the file attachment storage system implemented in the AI Chat App using Supabase Storage.

## Overview

The storage system supports:
- File attachments in chat messages (images, documents, audio, video)
- User avatar uploads
- Conversation exports
- Secure file access with Row Level Security (RLS)
- File validation and type restrictions
- Progress tracking for uploads/downloads

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Application                          │
├─────────────────────────────────────────────────────────────────┤
│ AttachmentPickerWidget │ AttachmentListWidget │ FilePreview     │
├─────────────────────────────────────────────────────────────────┤
│                   AttachmentService                             │
├─────────────────────────────────────────────────────────────────┤
│  FilePickerService    │    StorageService    │   FileUtils      │
├─────────────────────────────────────────────────────────────────┤
│                   Supabase Storage                              │
├─────────────────────────────────────────────────────────────────┤
│ chat-attachments │ avatars │ conversation-exports │ buckets     │
└─────────────────────────────────────────────────────────────────┘
```

## Storage Buckets

### 1. chat-attachments (Private)
- **Purpose**: Store file attachments for chat messages
- **Access**: Private with RLS policies
- **Size Limit**: 50MB per file
- **Path Structure**: `{user_id}/{conversation_id}/{message_id}/{filename}`

### 2. avatars (Public)
- **Purpose**: Store user profile pictures
- **Access**: Public read, authenticated write
- **Size Limit**: 5MB per file
- **Path Structure**: `{user_id}/{filename}`

### 3. conversation-exports (Private)
- **Purpose**: Store exported conversation files
- **Access**: Private with RLS policies
- **Size Limit**: 100MB per file
- **Path Structure**: `{user_id}/{export_id}/{filename}`

## Supported File Types

### Images
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- WebP (`.webp`)
- SVG (`.svg`)

### Documents
- PDF (`.pdf`)
- Microsoft Word (`.doc`, `.docx`)
- Microsoft Excel (`.xls`, `.xlsx`)
- Microsoft PowerPoint (`.ppt`, `.pptx`)
- Plain Text (`.txt`)
- Markdown (`.md`)
- CSV (`.csv`)
- JSON (`.json`)
- XML (`.xml`)

### Audio
- MP3 (`.mp3`)
- WAV (`.wav`)
- OGG (`.ogg`)
- WebM Audio (`.webm`)

### Video
- MP4 (`.mp4`)
- WebM Video (`.webm`)
- QuickTime (`.mov`)

### Archives
- ZIP (`.zip`)

## File Size Limits

| File Type | Maximum Size | Bucket |
|-----------|-------------|---------|
| Attachments | 50MB | chat-attachments |
| Avatars | 5MB | avatars |
| Exports | 100MB | conversation-exports |

## Security Policies

### Row Level Security (RLS)
All storage buckets use RLS to ensure users can only access their own files:

```sql
-- Users can only upload to their own folder
CREATE POLICY "Users can upload attachments to their own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only view their own files
CREATE POLICY "Users can view their own attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);
```

## Implementation

### Core Services

#### 1. AttachmentService
Main service combining file picking, validation, and storage operations.

```dart
final attachmentService = AttachmentService(
  supabaseClient: Supabase.instance.client,
);

// Pick and upload files
final result = await attachmentService.pickAndUploadAttachments(
  conversationId: conversationId,
  messageId: messageId,
  allowMultiple: true,
  type: AttachmentType.any,
);
```

#### 2. StorageService
Low-level service for direct Supabase Storage operations.

```dart
final uploadResult = await storageService.uploadAttachment(
  filePath: '/path/to/file.pdf',
  conversationId: conversationId,
  messageId: messageId,
);
```

#### 3. FilePickerService
Service for selecting files from device storage or camera.

```dart
final pickResult = await filePickerService.pickFile(
  allowMultiple: true,
  fileType: FileType.any,
);
```

### Data Models

#### FileAttachment
```dart
class FileAttachment {
  final String id;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String bucketId;
  final String storagePath;
  final String? publicUrl;
  final String? signedUrl;
  final String fileType;
  final DateTime uploadedAt;
  final List<FileAttachment> attachments;
  // ... other properties
}
```

#### Message (with attachments)
```dart
class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final List<FileAttachment> attachments;
  // ... other properties
}
```

### Widget Usage

#### AttachmentPickerWidget
```dart
AttachmentPickerWidget(
  conversationId: conversationId,
  messageId: messageId,
  attachmentService: attachmentService,
  allowMultiple: true,
  allowedType: AttachmentType.any,
  onAttachmentsSelected: (attachments) {
    // Handle selected attachments
  },
  onError: (error) {
    // Handle errors
  },
)
```

#### AttachmentListWidget
```dart
AttachmentListWidget(
  attachments: message.attachments,
  attachmentService: attachmentService,
  onRemove: (attachment) {
    // Handle attachment removal
  },
  onTap: (attachment) {
    // Handle attachment preview
  },
)
```

## Database Integration

### Message Metadata
File attachments are stored in the `metadata` JSONB column of the `messages` table:

```json
{
  "attachments": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "fileName": "document.pdf",
      "fileSize": 1024000,
      "mimeType": "application/pdf",
      "bucketId": "chat-attachments",
      "storagePath": "user_id/conversation_id/message_id/document.pdf",
      "fileType": "document",
      "uploadedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Automatic Metadata Updates
A trigger automatically updates message metadata when files are uploaded:

```sql
CREATE TRIGGER on_attachment_upload
    AFTER INSERT ON storage.objects
    FOR EACH ROW
    WHEN (NEW.bucket_id = 'chat-attachments')
    EXECUTE FUNCTION update_message_attachment_metadata();
```

## File Validation

### Client-Side Validation
```dart
// Validate file before upload
final validation = FileUtils.validateAttachment(filePath);
if (!validation.isValid) {
  print('Validation error: ${validation.errorMessage}');
  return;
}
```

### Server-Side Validation
- File type validation via MIME type checking
- File size limits enforced by bucket configuration
- Path validation to prevent directory traversal

## Error Handling

### Common Error Scenarios
1. **File too large**: Exceeds bucket size limits
2. **Invalid file type**: Not in allowed MIME types list
3. **Network errors**: Upload/download failures
4. **Permission denied**: RLS policy violations
5. **Storage quota exceeded**: User storage limits reached

### Error Response Format
```dart
class FileUploadResult {
  final bool success;
  final FileAttachment? attachment;
  final String? errorMessage;
  final Duration? uploadDuration;
}
```

## Performance Considerations

### Upload Optimization
- Progress tracking for large files
- Chunked uploads for better reliability
- Compression for images (configurable quality)
- Background upload support

### Download Optimization
- Signed URL caching (1 hour default)
- Thumbnail generation for images/videos
- Progressive loading for large files

### Storage Optimization
- Automatic cleanup of expired exports (7 days)
- File deduplication via hash checking
- Lazy loading of attachment metadata

## Development Setup

### 1. Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.8.0
  file_picker: ^8.1.2
  image_picker: ^1.1.2
  path_provider: ^2.1.4
  mime: ^1.0.6
  uuid: ^4.5.1
  crypto: ^3.0.5
```

### 2. Supabase Configuration
Update `supabase/config.toml`:
```toml
[storage]
enabled = true
file_size_limit = "50MiB"
```

### 3. Database Migration
Run the storage bucket configuration migration:
```bash
supabase db reset
```

### 4. Initialize Services
```dart
void main() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}
```

## Testing

### Unit Tests
```dart
group('AttachmentService', () {
  test('should upload file successfully', () async {
    final result = await attachmentService.uploadFileFromBytes(
      fileBytes: testFileBytes,
      fileName: 'test.pdf',
      conversationId: 'test-conversation',
      messageId: 'test-message',
    );
    
    expect(result.success, isTrue);
    expect(result.attachment, isNotNull);
  });
});
```

### Integration Tests
```dart
group('File Upload Flow', () {
  testWidgets('should pick and upload file', (tester) async {
    // Test attachment picker widget
    await tester.pumpWidget(MaterialApp(
      home: AttachmentPickerWidget(
        conversationId: 'test',
        messageId: 'test',
        attachmentService: mockAttachmentService,
      ),
    ));
    
    // Simulate file selection
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    
    // Verify upload completion
    expect(find.text('Upload completed'), findsOneWidget);
  });
});
```

## Monitoring and Analytics

### Storage Usage Tracking
```dart
final usageInfo = await attachmentService.getStorageUsage();
print('Total storage used: ${usageInfo.formattedSize}');
print('Files uploaded: ${usageInfo.totalFiles}');
```

### Upload Metrics
- Upload success/failure rates
- Average upload times
- File type distribution
- Storage usage by user

## Security Best Practices

1. **Always validate files on both client and server**
2. **Use signed URLs for private file access**
3. **Implement proper RLS policies**
4. **Sanitize file names to prevent path traversal**
5. **Limit file sizes to prevent abuse**
6. **Scan files for malware (if applicable)**
7. **Use HTTPS for all file transfers**
8. **Implement rate limiting for uploads**

## Troubleshooting

### Common Issues

#### Upload Fails with "Permission Denied"
- Check RLS policies are correctly configured
- Verify user is authenticated
- Ensure file path follows correct structure

#### File Not Found After Upload
- Check bucket name in storage path
- Verify RLS policies allow read access
- Check if file was uploaded to correct path

#### Large File Upload Timeout
- Increase timeout configuration
- Implement chunked upload for large files
- Check network connectivity

### Debug Tools
```dart
// Enable debug logging
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  debug: true, // Enable debug logs
);

// Check storage bucket contents
final files = await storageService.listFiles(
  bucketId: 'chat-attachments',
  folderPath: userId,
);
```

## Future Enhancements

### Planned Features
1. **Image compression and resizing**
2. **Video thumbnail generation**
3. **File preview in chat**
4. **Drag-and-drop upload**
5. **Batch file operations**
6. **Cloud storage sync**
7. **Offline file caching**
8. **File sharing between users**

### Performance Improvements
1. **CDN integration for faster downloads**
2. **Background upload queue**
3. **Smart caching strategies**
4. **Progressive file loading**

## Support

For issues related to file attachment storage:

1. Check this documentation first
2. Review Supabase Storage documentation
3. Check the GitHub issues
4. Contact the development team

## Changelog

### v1.0.0 (Current)
- Initial storage bucket configuration
- File upload/download functionality
- RLS security policies
- Flutter widget components
- Comprehensive validation system

---

*Last updated: December 2024*