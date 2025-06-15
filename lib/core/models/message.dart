import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'file_attachment.dart';

part 'message.g.dart';

/// Enum for message roles
enum MessageRole {
  @JsonValue('user')
  user('user'),
  @JsonValue('assistant')
  assistant('assistant'),
  @JsonValue('system')
  system('system');

  const MessageRole(this.value);
  final String value;

  @override
  String toString() => value;
}

/// Enum for message content types
enum MessageContentType {
  @JsonValue('text')
  text('text'),
  @JsonValue('code')
  code('code'),
  @JsonValue('image')
  image('image'),
  @JsonValue('file')
  file('file'),
  @JsonValue('mixed')
  mixed('mixed');

  const MessageContentType(this.value);
  final String value;

  @override
  String toString() => value;
}

/// Model representing a chat message
@JsonSerializable()
class Message extends Equatable {
  /// Unique identifier for the message
  final String id;

  /// ID of the conversation this message belongs to
  final String conversationId;

  /// Message role (user, assistant, system)
  final MessageRole role;

  /// Message content (text)
  final String content;

  /// Content type (text, code, image, file, mixed)
  final MessageContentType contentType;

  /// Model name used for assistant messages
  final String? modelName;

  /// Model provider for assistant messages
  final String? modelProvider;

  /// Number of prompt tokens used
  final int? promptTokens;

  /// Number of completion tokens generated
  final int? completionTokens;

  /// Total tokens used (prompt + completion)
  final int? totalTokens;

  /// Estimated cost for this message
  final double? estimatedCost;

  /// File attachments associated with this message
  final List<FileAttachment> attachments;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Parent message ID (for threading)
  final String? parentMessageId;

  /// Whether the message has been edited
  final bool isEdited;

  /// Whether the message is deleted (soft delete)
  final bool isDeleted;

  /// Error message if the message failed to send/process
  final String? errorMessage;

  /// Message creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  /// Whether the message is currently being sent/processed
  final bool isLoading;

  /// Progress of message processing (0.0 to 1.0)
  final double progress;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.contentType = MessageContentType.text,
    this.modelName,
    this.modelProvider,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.estimatedCost,
    this.attachments = const [],
    this.metadata,
    this.parentMessageId,
    this.isEdited = false,
    this.isDeleted = false,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isLoading = false,
    this.progress = 0.0,
  });

  /// Factory constructor from JSON
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  /// Create a copy with updated properties
  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    MessageContentType? contentType,
    String? modelName,
    String? modelProvider,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    double? estimatedCost,
    List<FileAttachment>? attachments,
    Map<String, dynamic>? metadata,
    String? parentMessageId,
    bool? isEdited,
    bool? isDeleted,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLoading,
    double? progress,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      modelName: modelName ?? this.modelName,
      modelProvider: modelProvider ?? this.modelProvider,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }

  /// Create a user message
  factory Message.user({
    required String content,
    required String conversationId,
    List<FileAttachment> attachments = const [],
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Message(
      id: '', // Will be set by the repository
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      contentType:
          attachments.isNotEmpty
              ? (content.isNotEmpty
                  ? MessageContentType.mixed
                  : MessageContentType.file)
              : MessageContentType.text,
      attachments: attachments,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create an assistant message
  factory Message.assistant({
    required String content,
    required String conversationId,
    String? modelName,
    String? modelProvider,
    int? promptTokens,
    int? completionTokens,
    double? estimatedCost,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Message(
      id: '', // Will be set by the repository
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: content,
      contentType: MessageContentType.text,
      modelName: modelName,
      modelProvider: modelProvider,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: (promptTokens ?? 0) + (completionTokens ?? 0),
      estimatedCost: estimatedCost,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a system message
  factory Message.system({
    required String content,
    required String conversationId,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Message(
      id: '', // Will be set by the repository
      conversationId: conversationId,
      role: MessageRole.system,
      content: content,
      contentType: MessageContentType.text,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a loading message (for showing typing indicator)
  factory Message.loading({
    required String conversationId,
    String content = '',
    double progress = 0.0,
  }) {
    final now = DateTime.now();
    return Message(
      id: 'loading_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: content,
      isLoading: true,
      progress: progress,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if message is from user
  bool get isUser => role == MessageRole.user;

  /// Check if message is from assistant
  bool get isAssistant => role == MessageRole.assistant;

  /// Check if message is system message
  bool get isSystem => role == MessageRole.system;

  /// Check if message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if message has only images
  bool get hasOnlyImages =>
      hasAttachments && attachments.every((attachment) => attachment.isImage);

  /// Check if message has text content
  bool get hasTextContent => content.isNotEmpty;

  /// Check if message has error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Check if message is empty (no content and no attachments)
  bool get isEmpty => content.isEmpty && attachments.isEmpty;

  /// Get all image attachments
  List<FileAttachment> get imageAttachments =>
      attachments.where((attachment) => attachment.isImage).toList();

  /// Get all document attachments
  List<FileAttachment> get documentAttachments =>
      attachments.where((attachment) => attachment.isDocument).toList();

  /// Get all audio attachments
  List<FileAttachment> get audioAttachments =>
      attachments.where((attachment) => attachment.isAudio).toList();

  /// Get all video attachments
  List<FileAttachment> get videoAttachments =>
      attachments.where((attachment) => attachment.isVideo).toList();

  /// Get content preview (truncated if too long)
  String getContentPreview({int maxLength = 100}) {
    if (content.isEmpty) {
      if (hasAttachments) {
        final attachmentCount = attachments.length;
        if (attachmentCount == 1) {
          return '📎 ${attachments.first.fileName}';
        } else {
          return '📎 $attachmentCount attachments';
        }
      }
      return '';
    }

    if (content.length <= maxLength) {
      return content;
    }

    return '${content.substring(0, maxLength)}...';
  }

  /// Get display text for the message
  String get displayText {
    if (hasError) {
      return 'Error: $errorMessage';
    }

    if (isLoading) {
      if (content.isNotEmpty) {
        return content;
      }
      return progress > 0
          ? 'Processing... ${(progress * 100).toInt()}%'
          : 'Typing...';
    }

    if (content.isEmpty && hasAttachments) {
      return getContentPreview();
    }

    return content;
  }

  /// Get total attachment size
  int get totalAttachmentSize =>
      attachments.fold(0, (sum, attachment) => sum + attachment.fileSize);

  /// Get formatted total attachment size
  String get formattedAttachmentSize {
    final size = totalAttachmentSize;
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if message can be edited
  bool get canEdit => !isDeleted && !isLoading;

  /// Check if message can be deleted
  bool get canDelete => !isDeleted;

  /// Check if message can be resent (for failed messages)
  bool get canResend => hasError && !isDeleted;

  /// Get time since message was created
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  /// Check if message was created recently (within last 5 minutes)
  bool get isRecent => timeSinceCreated.inMinutes < 5;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    role,
    content,
    contentType,
    modelName,
    modelProvider,
    promptTokens,
    completionTokens,
    totalTokens,
    estimatedCost,
    attachments,
    metadata,
    parentMessageId,
    isEdited,
    isDeleted,
    errorMessage,
    createdAt,
    updatedAt,
    isLoading,
    progress,
  ];

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, '
        'attachments: ${attachments.length}, isLoading: $isLoading, hasError: $hasError)';
  }
}

/// Extension for message list operations
extension MessageListExtensions on List<Message> {
  /// Get all user messages
  List<Message> get userMessages => where((m) => m.isUser).toList();

  /// Get all assistant messages
  List<Message> get assistantMessages => where((m) => m.isAssistant).toList();

  /// Get all system messages
  List<Message> get systemMessages => where((m) => m.isSystem).toList();

  /// Get messages with attachments
  List<Message> get messagesWithAttachments =>
      where((m) => m.hasAttachments).toList();

  /// Get total token count
  int get totalTokens =>
      fold(0, (sum, message) => sum + (message.totalTokens ?? 0));

  /// Get total estimated cost
  double get totalEstimatedCost =>
      fold(0.0, (sum, message) => sum + (message.estimatedCost ?? 0.0));

  /// Get messages sorted by creation time (newest first)
  List<Message> get sortedByNewest =>
      [...this]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Get messages sorted by creation time (oldest first)
  List<Message> get sortedByOldest =>
      [...this]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Get non-deleted messages
  List<Message> get activeMessages => where((m) => !m.isDeleted).toList();

  /// Get messages with errors
  List<Message> get errorMessages => where((m) => m.hasError).toList();

  /// Get loading messages
  List<Message> get loadingMessages => where((m) => m.isLoading).toList();
}
