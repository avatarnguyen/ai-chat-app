import 'dart:async';
import 'package:ai_chat_app/core/config/supabase_config.dart';
import 'package:ai_chat_app/features/auth/data/models/user_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart' as repo;
import '../services/google_oauth_service.dart';
import '../services/apple_oauth_service.dart';

/// Supabase implementation of authentication data source
@singleton
class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this._googleOAuthService, this._appleOAuthService)
    : _supabase = SupabaseConfig.client;

  final SupabaseClient _supabase;
  final GoogleOAuthService _googleOAuthService;
  final AppleOAuthService _appleOAuthService;

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final session = data.session;
      if (session?.user == null) return null;

      return _convertSupabaseUserToModel(session!.user);
    });
  }

  /// Get current authenticated user
  UserModel? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return _convertSupabaseUserToModel(user);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user == null) {
        throw const repo.ServerException();
      }

      // Create user profile in the database
      await _createUserProfile(response.user!, displayName);

      return _convertSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const repo.InvalidCredentialsException();
      }

      // Update last active timestamp
      await _updateLastActive(response.user!.id);

      return _convertSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Sign in with Google OAuth
  Future<UserModel> signInWithGoogle() async {
    try {
      // Use native Google Sign-In for better user experience
      final googleAccount = await _googleOAuthService.signIn();
      if (googleAccount == null) {
        throw const repo.InvalidCredentialsException();
      }

      // Get Google authentication tokens
      final googleAuth = await _googleOAuthService.getAuthentication();
      if (googleAuth == null) {
        throw const repo.ServerException();
      }

      // Sign in to Supabase with Google tokens
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        throw const repo.ServerException();
      }

      // Create or update user profile
      await _createOrUpdateUserProfile(response.user!);

      return _convertSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Sign in with Apple OAuth
  Future<UserModel> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!await _appleOAuthService.isAvailable()) {
        throw const repo.UnknownAuthException(
          'Apple Sign In is not available on this device',
        );
      }

      // Use native Apple Sign-In for better user experience
      final appleCredential = await _appleOAuthService.signIn();

      // Sign in to Supabase with Apple credential
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: appleCredential.identityToken!,
      );

      if (response.user == null) {
        throw const repo.ServerException();
      }

      // Create or update user profile with Apple data
      await _createOrUpdateUserProfileFromApple(
        response.user!,
        appleCredential,
      );

      return _convertSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from OAuth providers first
      if (_googleOAuthService.isSignedIn) {
        await _googleOAuthService.signOut();
      }
      // Apple Sign-In doesn't have a direct sign-out method
      // It's handled through the Supabase session

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: '${SupabaseConfig.siteUrl}/auth/reset-password',
      );
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Change password for authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First, verify current password by attempting to sign in
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw const repo.SessionExpiredException();
      }

      // Re-authenticate with current password
      await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );

      // Update password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const repo.SessionExpiredException();
      }

      // Prepare update data
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (preferredModel != null) {
        updateData['preferred_model'] = preferredModel;
      }
      if (themePreference != null) {
        updateData['theme_preference'] = themePreference;
      }
      if (languagePreference != null) {
        updateData['language_preference'] = languagePreference;
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update user profile in database
      await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', userId);

      // Update auth metadata if display name changed
      if (displayName != null) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'display_name': displayName}),
        );
      }

      // Fetch updated profile
      final profile = await _getUserProfile(userId);
      return UserModel.fromSupabase(
        authUser: _supabase.auth.currentUser!.toJson(),
        profile: profile,
      );
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const repo.SessionExpiredException();
      }

      // Delete user profile (this will cascade delete related data)
      await _supabase.from('user_profiles').delete().eq('user_id', userId);

      // Sign out user
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Verify email with token
  Future<void> verifyEmail({required String token}) async {
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        token: token,
        email: _supabase.auth.currentUser?.email ?? '',
      );
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw const repo.SessionExpiredException();
      }

      await _supabase.auth.resend(type: OtpType.signup, email: user!.email!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Refresh current session
  Future<UserModel> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.user == null) {
        throw const repo.SessionExpiredException();
      }

      return _convertSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Check if email is registered
  Future<bool> isEmailRegistered({required String email}) async {
    try {
      // This is a workaround since Supabase doesn't provide direct email check
      // We attempt to send a password reset email
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUserProfile({required String userId}) async {
    try {
      final profile = await _getUserProfile(userId);
      if (profile == null) return null;

      // We need auth user data too, but we only have profile data
      // This is a limitation - we can only get full user data for current user
      return UserModel.fromSupabase(
        authUser: {'id': userId, 'email': profile['email'] ?? ''},
        profile: profile,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _updateLastActive(userId);
    } catch (e) {
      // Ignore errors for this non-critical operation
    }
  }

  /// Get user usage statistics
  Future<Map<String, dynamic>> getUserUsageStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const repo.SessionExpiredException();
      }

      final profile = await _getUserProfile(userId);
      if (profile == null) {
        throw const repo.UserNotFoundException();
      }

      return {
        'totalMessagesSent': profile['total_messages_sent'] ?? 0,
        'totalTokensUsed': profile['total_tokens_used'] ?? 0,
        'monthlyMessageLimit': profile['monthly_message_limit'] ?? 100,
        'subscriptionTier': profile['subscription_tier'] ?? 'free',
      };
    } catch (e) {
      throw repo.UnknownAuthException(e.toString());
    }
  }

  /// Check if user has reached message limit
  Future<bool> hasReachedMessageLimit() async {
    try {
      final stats = await getUserUsageStats();
      final messagesSent = stats['totalMessagesSent'] as int;
      final messageLimit = stats['monthlyMessageLimit'] as int;

      return messagesSent >= messageLimit;
    } catch (e) {
      return false;
    }
  }

  /// Increment message count
  Future<void> incrementMessageCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc(
        'increment_message_count',
        params: {'user_id': userId},
      );
    } catch (e) {
      // Ignore errors for this non-critical operation
    }
  }

  /// Add token usage
  Future<void> addTokenUsage({required int tokens}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc(
        'add_token_usage',
        params: {'user_id': userId, 'tokens': tokens},
      );
    } catch (e) {
      // Ignore errors for this non-critical operation
    }
  }

  // Private helper methods

  /// Convert Supabase User to UserModel
  UserModel _convertSupabaseUserToModel(User user) {
    return UserModel.fromSupabase(authUser: user.toJson());
  }

  /// Create user profile in database
  Future<void> _createUserProfile(User user, String? displayName) async {
    final profileData = {
      'user_id': user.id,
      'display_name': displayName,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'last_active_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('user_profiles').insert(profileData);
  }

  /// Create or update user profile for OAuth users
  Future<void> _createOrUpdateUserProfile(User user) async {
    final existingProfile = await _getUserProfile(user.id);

    if (existingProfile == null) {
      // Create new profile
      await _createUserProfile(
        user,
        user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String?,
      );
    } else {
      // Update last active
      await _updateLastActive(user.id);
    }
  }

  /// Create or update user profile specifically for Apple OAuth users
  Future<void> _createOrUpdateUserProfileFromApple(
    User user,
    dynamic appleCredential,
  ) async {
    final existingProfile = await _getUserProfile(user.id);

    String? displayName;
    if (appleCredential != null) {
      displayName = _appleOAuthService.getDisplayName(appleCredential);
    }

    displayName ??= user.userMetadata?['display_name'] as String?;
    displayName ??= user.userMetadata?['full_name'] as String?;

    if (existingProfile == null) {
      // Create new profile with Apple-specific data
      await _createUserProfile(user, displayName);
    } else {
      // Update existing profile if we have new display name info
      if (displayName != null && existingProfile['display_name'] == null) {
        await _supabase
            .from('user_profiles')
            .update({
              'display_name': displayName,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      }

      // Update last active
      await _updateLastActive(user.id);
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    final response =
        await _supabase
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    return response;
  }

  /// Update last active timestamp
  Future<void> _updateLastActive(String userId) async {
    await _supabase
        .from('user_profiles')
        .update({'last_active_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId);
  }

  /// Map Supabase AuthException to domain exceptions
  Exception _mapSupabaseAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('Invalid login credentials')) {
          return const repo.InvalidCredentialsException();
        } else if (e.message.contains('Password should be at least')) {
          return const repo.WeakPasswordException();
        }
        break;
      case '401':
        return const repo.InvalidCredentialsException();
      case '422':
        if (e.message.contains('email not confirmed')) {
          return const repo.EmailNotVerifiedException();
        } else if (e.message.contains('User already registered')) {
          return const repo.EmailAlreadyInUseException();
        }
        break;
      case '429':
        return const repo.TooManyRequestsException();
      case '500':
        return const repo.ServerException();
    }

    return repo.UnknownAuthException(e.message);
  }
}
