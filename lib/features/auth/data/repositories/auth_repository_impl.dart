import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../../../../core/config/supabase_config.dart';

/// Implementation of [AuthRepository] using Supabase
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseAuthDataSource? authDataSource})
    : _authDataSource = authDataSource ?? SupabaseAuthDataSource();

  final SupabaseAuthDataSource _authDataSource;

  @override
  Stream<User?> get authStateChanges {
    return _authDataSource.authStateChanges;
  }

  @override
  User? get currentUser => _authDataSource.currentUser;

  @override
  bool get isAuthenticated => _authDataSource.isAuthenticated;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // Validate input
    if (!validateEmail(email)) {
      throw const UnknownAuthException('Invalid email format');
    }

    if (!validatePassword(password)) {
      throw const WeakPasswordException();
    }

    return await _authDataSource.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    // Validate input
    if (!validateEmail(email)) {
      throw const UnknownAuthException('Invalid email format');
    }

    if (password.isEmpty) {
      throw const InvalidCredentialsException();
    }

    return await _authDataSource.signIn(email: email, password: password);
  }

  @override
  Future<User> signInWithGoogle() async {
    return await _authDataSource.signInWithGoogle();
  }

  @override
  Future<User> signInWithApple() async {
    return await _authDataSource.signInWithApple();
  }

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    if (!validateEmail(email)) {
      throw const UnknownAuthException('Invalid email format');
    }

    await _authDataSource.resetPassword(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw const InvalidCredentialsException();
    }

    if (!validatePassword(newPassword)) {
      throw const WeakPasswordException();
    }

    await _authDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
  }) async {
    // Validate display name length
    if (displayName != null && displayName.length > 50) {
      throw const UnknownAuthException('Display name too long');
    }

    // Validate bio length
    if (bio != null && bio.length > 500) {
      throw const UnknownAuthException('Bio too long');
    }

    // Validate theme preference
    if (themePreference != null &&
        !['system', 'light', 'dark'].contains(themePreference)) {
      throw const UnknownAuthException('Invalid theme preference');
    }

    // Validate language preference (basic ISO 639-1 codes)
    if (languagePreference != null &&
        ![
          'en',
          'es',
          'fr',
          'de',
          'it',
          'pt',
          'ru',
          'zh',
          'ja',
          'ko',
        ].contains(languagePreference)) {
      throw const UnknownAuthException('Invalid language preference');
    }

    // Validate preferred model
    if (preferredModel != null && !_isValidModel(preferredModel)) {
      throw const UnknownAuthException('Invalid model selection');
    }

    return await _authDataSource.updateProfile(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      preferredModel: preferredModel,
      themePreference: themePreference,
      languagePreference: languagePreference,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _authDataSource.deleteAccount();
  }

  @override
  Future<void> verifyEmail({required String token}) async {
    if (token.isEmpty) {
      throw const InvalidTokenException();
    }

    await _authDataSource.verifyEmail(token: token);
  }

  @override
  Future<void> resendEmailVerification() async {
    await _authDataSource.resendEmailVerification();
  }

  @override
  Future<User> refreshSession() async {
    return await _authDataSource.refreshSession();
  }

  @override
  Future<bool> isEmailRegistered({required String email}) async {
    if (!validateEmail(email)) {
      return false;
    }

    return await _authDataSource.isEmailRegistered(email: email);
  }

  @override
  Future<User?> getUserProfile({required String userId}) async {
    if (userId.isEmpty) {
      return null;
    }

    return await _authDataSource.getUserProfile(userId: userId);
  }

  @override
  Future<void> updateLastActive() async {
    await _authDataSource.updateLastActive();
  }

  @override
  Future<Map<String, dynamic>> getUserUsageStats() async {
    return await _authDataSource.getUserUsageStats();
  }

  @override
  Future<bool> hasReachedMessageLimit() async {
    return await _authDataSource.hasReachedMessageLimit();
  }

  @override
  Future<void> incrementMessageCount() async {
    await _authDataSource.incrementMessageCount();
  }

  @override
  Future<void> addTokenUsage({required int tokens}) async {
    if (tokens < 0) {
      throw const UnknownAuthException('Invalid token count');
    }

    await _authDataSource.addTokenUsage(tokens: tokens);
  }

  @override
  bool validatePassword(String password) {
    // Password requirements:
    // - At least 8 characters
    // - At least one lowercase letter
    // - At least one uppercase letter
    // - At least one digit
    // - At least one special character
    if (password.length < 8) return false;

    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasLowerCase && hasUpperCase && hasDigits && hasSpecialChar;
  }

  @override
  bool validateEmail(String email) {
    return SupabaseConfig.emailPattern.hasMatch(email);
  }

  /// Validate if the provided model name is supported
  bool _isValidModel(String model) {
    const validModels = [
      // OpenAI models
      'gpt-3.5-turbo',
      'gpt-3.5-turbo-16k',
      'gpt-4',
      'gpt-4-turbo',
      'gpt-4-turbo-preview',
      'gpt-4-vision-preview',
      'gpt-4o',
      'gpt-4o-mini',

      // Anthropic models
      'claude-3-haiku-20240307',
      'claude-3-sonnet-20240229',
      'claude-3-opus-20240229',
      'claude-3-5-sonnet-20241022',

      // Google models
      'gemini-pro',
      'gemini-pro-vision',
      'gemini-1.5-pro',
      'gemini-1.5-flash',

      // Other models via OpenRouter
      'meta-llama/llama-2-70b-chat',
      'mistralai/mixtral-8x7b-instruct',
      'microsoft/wizardlm-2-8x22b',
      'cohere/command-r-plus',
      'perplexity/llama-3-sonar-large-32k-online',
    ];

    return validModels.contains(model);
  }
}
