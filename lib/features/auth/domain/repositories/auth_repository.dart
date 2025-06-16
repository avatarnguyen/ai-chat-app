import '../entities/user.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Get the current authenticated user stream
  Stream<User?> get authStateChanges;

  /// Get the current authenticated user (if any)
  User? get currentUser;

  /// Check if user is currently authenticated
  bool get isAuthenticated;

  /// Sign up with email and password
  /// Returns the created user or throws an exception
  Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with email and password
  /// Returns the authenticated user or throws an exception
  Future<User> signIn({required String email, required String password});

  /// Sign in with Google OAuth
  /// Returns the authenticated user or throws an exception
  Future<User> signInWithGoogle();

  /// Sign in with Apple OAuth (iOS/macOS only)
  /// Returns the authenticated user or throws an exception
  Future<User> signInWithApple();

  /// Sign out the current user
  /// Throws an exception if sign out fails
  Future<void> signOut();

  /// Send password reset email
  /// Throws an exception if email sending fails
  Future<void> resetPassword({required String email});

  /// Change password for authenticated user
  /// Throws an exception if password change fails
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update user profile information
  /// Returns the updated user or throws an exception
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
  });

  /// Delete user account and all associated data
  /// Throws an exception if deletion fails
  Future<void> deleteAccount();

  /// Verify email address with token
  /// Throws an exception if verification fails
  Future<void> verifyEmail({required String token});

  /// Resend email verification
  /// Throws an exception if email sending fails
  Future<void> resendEmailVerification();

  /// Refresh the current user's session
  /// Returns the refreshed user or throws an exception
  Future<User> refreshSession();

  /// Check if email is already registered
  /// Returns true if email exists, false otherwise
  Future<bool> isEmailRegistered({required String email});

  /// Get user profile by ID
  /// Returns the user or null if not found
  Future<User?> getUserProfile({required String userId});

  /// Update user's last active timestamp
  /// Used for tracking user activity
  Future<void> updateLastActive();

  /// Get user's usage statistics
  /// Returns a map with message count, token usage, etc.
  Future<Map<String, dynamic>> getUserUsageStats();

  /// Check if user has reached their message limit
  /// Returns true if limit is reached
  Future<bool> hasReachedMessageLimit();

  /// Increment user's message count
  /// Used when user sends a message
  Future<void> incrementMessageCount();

  /// Add tokens to user's usage counter
  /// Used when user makes API calls
  Future<void> addTokenUsage({required int tokens});

  /// Validate password strength
  /// Returns true if password meets requirements
  bool validatePassword(String password);

  /// Validate email format
  /// Returns true if email format is valid
  bool validateEmail(String email);
}

/// Exception classes for authentication errors
abstract class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password');
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException() : super('Email not verified');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('User not found');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('Password is too weak');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super('Email already in use');
}

class NetworkException extends AuthException {
  const NetworkException() : super('Network error');
}

class ServerException extends AuthException {
  const ServerException() : super('Server error');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException() : super('Session expired');
}

class InvalidTokenException extends AuthException {
  const InvalidTokenException() : super('Invalid token');
}

class AccountDeletedException extends AuthException {
  const AccountDeletedException() : super('Account has been deleted');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException() : super('Too many requests');
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException(String message) : super(message);
}
