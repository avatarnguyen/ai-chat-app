import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Data model for User with JSON serialization
@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.avatarUrl,
    super.bio,
    super.preferredModel,
    super.themePreference,
    super.languagePreference,
    super.subscriptionTier,
    super.totalMessagesSent,
    super.totalTokensUsed,
    super.monthlyMessageLimit,
    super.isEmailVerified,
    super.isOnboardingCompleted,
    super.createdAt,
    super.updatedAt,
    super.lastActiveAt,
  });

  /// Create UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert UserModel to JSON map
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Create UserModel from Supabase User and Profile data
  factory UserModel.fromSupabase({
    required Map<String, dynamic> authUser,
    Map<String, dynamic>? profile,
  }) {
    final profileData = profile ?? <String, dynamic>{};

    return UserModel(
      id: authUser['id'] as String,
      email: authUser['email'] as String,
      displayName: profileData['display_name'] as String?,
      avatarUrl: profileData['avatar_url'] as String?,
      bio: profileData['bio'] as String?,
      preferredModel:
          profileData['preferred_model'] as String? ?? 'gpt-3.5-turbo',
      themePreference: profileData['theme_preference'] as String? ?? 'system',
      languagePreference: profileData['language_preference'] as String? ?? 'en',
      subscriptionTier: _parseSubscriptionTier(
        profileData['subscription_tier'] as String?,
      ),
      totalMessagesSent: profileData['total_messages_sent'] as int? ?? 0,
      totalTokensUsed: profileData['total_tokens_used'] as int? ?? 0,
      monthlyMessageLimit: profileData['monthly_message_limit'] as int? ?? 100,
      isEmailVerified: authUser['email_confirmed_at'] != null,
      isOnboardingCompleted:
          profileData['is_onboarding_completed'] as bool? ?? false,
      createdAt:
          profileData['created_at'] != null
              ? DateTime.parse(profileData['created_at'] as String)
              : null,
      updatedAt:
          profileData['updated_at'] != null
              ? DateTime.parse(profileData['updated_at'] as String)
              : null,
      lastActiveAt:
          profileData['last_active_at'] != null
              ? DateTime.parse(profileData['last_active_at'] as String)
              : null,
    );
  }

  /// Convert UserModel to Supabase profile format
  Map<String, dynamic> toSupabaseProfile() {
    return {
      'user_id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'preferred_model': preferredModel,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'subscription_tier': subscriptionTier.name,
      'total_messages_sent': totalMessagesSent,
      'total_tokens_used': totalTokensUsed,
      'monthly_message_limit': monthlyMessageLimit,
      'is_onboarding_completed': isOnboardingCompleted,
      'updated_at': DateTime.now().toIso8601String(),
      'last_active_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy of this UserModel with updated fields
  @override
  UserModel copyWith({
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
    return UserModel(
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

  /// Parse subscription tier from string
  static SubscriptionTier _parseSubscriptionTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'enterprise':
        return SubscriptionTier.enterprise;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Create an empty UserModel for testing or defaults
  factory UserModel.empty() {
    return const UserModel(
      id: '',
      email: '',
      displayName: null,
      avatarUrl: null,
      bio: null,
      preferredModel: 'gpt-3.5-turbo',
      themePreference: 'system',
      languagePreference: 'en',
      subscriptionTier: SubscriptionTier.free,
      totalMessagesSent: 0,
      totalTokensUsed: 0,
      monthlyMessageLimit: 100,
      isEmailVerified: false,
      isOnboardingCompleted: false,
      createdAt: null,
      updatedAt: null,
      lastActiveAt: null,
    );
  }

  /// Create a test UserModel with sample data
  factory UserModel.sample() {
    final now = DateTime.now();
    return UserModel(
      id: 'sample-user-id',
      email: 'user@example.com',
      displayName: 'John Doe',
      avatarUrl: 'https://example.com/avatar.jpg',
      bio: 'AI enthusiast and developer',
      preferredModel: 'gpt-4',
      themePreference: 'dark',
      languagePreference: 'en',
      subscriptionTier: SubscriptionTier.pro,
      totalMessagesSent: 50,
      totalTokensUsed: 12500,
      monthlyMessageLimit: 1000,
      isEmailVerified: true,
      isOnboardingCompleted: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 1)),
      lastActiveAt: now.subtract(const Duration(hours: 2)),
    );
  }
}
