import 'package:equatable/equatable.dart';

/// Domain entity representing a user in the application
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.preferredModel = 'gpt-3.5-turbo',
    this.themePreference = 'system',
    this.languagePreference = 'en',
    this.subscriptionTier = SubscriptionTier.free,
    this.totalMessagesSent = 0,
    this.totalTokensUsed = 0,
    this.monthlyMessageLimit = 100,
    this.isEmailVerified = false,
    this.isOnboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
  });

  /// Unique identifier for the user
  final String id;

  /// User's email address
  final String email;

  /// Display name for the user
  final String? displayName;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// User's bio/description
  final String? bio;

  /// User's preferred AI model
  final String preferredModel;

  /// User's theme preference
  final String themePreference;

  /// User's language preference
  final String languagePreference;

  /// User's subscription tier
  final SubscriptionTier subscriptionTier;

  /// Total number of messages sent by user
  final int totalMessagesSent;

  /// Total tokens used by user
  final int totalTokensUsed;

  /// Monthly message limit for user
  final int monthlyMessageLimit;

  /// Whether user's email is verified
  final bool isEmailVerified;

  /// Whether user has completed onboarding
  final bool isOnboardingCompleted;

  /// When the user was created
  final DateTime? createdAt;

  /// When the user was last updated
  final DateTime? updatedAt;

  /// When the user was last active
  final DateTime? lastActiveAt;

  /// Create a copy of this user with some fields changed
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
    SubscriptionTier? subscriptionTier,
    int? totalMessagesSent,
    int? totalTokensUsed,
    int? monthlyMessageLimit,
    bool? isEmailVerified,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      preferredModel: preferredModel ?? this.preferredModel,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      totalMessagesSent: totalMessagesSent ?? this.totalMessagesSent,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      monthlyMessageLimit: monthlyMessageLimit ?? this.monthlyMessageLimit,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Check if user has reached their monthly message limit
  bool get hasReachedMessageLimit => totalMessagesSent >= monthlyMessageLimit;

  /// Get remaining messages for the month
  int get remainingMessages => monthlyMessageLimit - totalMessagesSent;

  /// Check if user is a premium subscriber
  bool get isPremium => subscriptionTier != SubscriptionTier.free;

  /// Get display name or fallback to email
  String get displayNameOrEmail => displayName ?? email;

  /// Get initials from display name or email
  String get initials {
    final name = displayNameOrEmail;
    if (name.isEmpty) return '';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    bio,
    preferredModel,
    themePreference,
    languagePreference,
    subscriptionTier,
    totalMessagesSent,
    totalTokensUsed,
    monthlyMessageLimit,
    isEmailVerified,
    isOnboardingCompleted,
    createdAt,
    updatedAt,
    lastActiveAt,
  ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, '
        'subscriptionTier: $subscriptionTier, isEmailVerified: $isEmailVerified)';
  }
}

/// Enum representing different subscription tiers
enum SubscriptionTier {
  free,
  pro,
  enterprise;

  /// Get display name for subscription tier
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  /// Get message limit for subscription tier
  int get messageLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 100;
      case SubscriptionTier.pro:
        return 1000;
      case SubscriptionTier.enterprise:
        return -1; // Unlimited
    }
  }

  /// Check if tier has unlimited messages
  bool get isUnlimited => this == SubscriptionTier.enterprise;
}
