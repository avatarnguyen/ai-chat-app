import 'package:equatable/equatable.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize authentication state
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

/// Event triggered when authentication state changes
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.user);

  final dynamic user; // Can be User or null

  @override
  List<Object?> get props => [user];
}

/// Event to sign up with email and password
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Event to sign in with email and password
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign in with Google OAuth
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Event to sign in with Apple OAuth
class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

/// Event to sign out current user
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to send password reset email
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event to change user password
class AuthPasswordChangeRequested extends AuthEvent {
  const AuthPasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Event to update user profile
class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.preferredModel,
    this.themePreference,
    this.languagePreference,
  });

  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? preferredModel;
  final String? themePreference;
  final String? languagePreference;

  @override
  List<Object?> get props => [
    displayName,
    bio,
    avatarUrl,
    preferredModel,
    themePreference,
    languagePreference,
  ];
}

/// Event to delete user account
class AuthAccountDeletionRequested extends AuthEvent {
  const AuthAccountDeletionRequested();
}

/// Event to verify email with token
class AuthEmailVerificationRequested extends AuthEvent {
  const AuthEmailVerificationRequested({required this.token});

  final String token;

  @override
  List<Object?> get props => [token];
}

/// Event to resend email verification
class AuthEmailVerificationResendRequested extends AuthEvent {
  const AuthEmailVerificationResendRequested();
}

/// Event to refresh current session
class AuthSessionRefreshRequested extends AuthEvent {
  const AuthSessionRefreshRequested();
}

/// Event to check if email is already registered
class AuthEmailRegistrationCheckRequested extends AuthEvent {
  const AuthEmailRegistrationCheckRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event to update user's last active timestamp
class AuthLastActiveUpdateRequested extends AuthEvent {
  const AuthLastActiveUpdateRequested();
}

/// Event to get user usage statistics
class AuthUsageStatsRequested extends AuthEvent {
  const AuthUsageStatsRequested();
}

/// Event to check if user has reached message limit
class AuthMessageLimitCheckRequested extends AuthEvent {
  const AuthMessageLimitCheckRequested();
}

/// Event to increment user's message count
class AuthMessageCountIncrementRequested extends AuthEvent {
  const AuthMessageCountIncrementRequested();
}

/// Event to add token usage to user's counter
class AuthTokenUsageAddRequested extends AuthEvent {
  const AuthTokenUsageAddRequested({required this.tokens});

  final int tokens;

  @override
  List<Object?> get props => [tokens];
}

/// Event to clear authentication errors
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

/// Event to validate password strength
class AuthPasswordValidationRequested extends AuthEvent {
  const AuthPasswordValidationRequested({required this.password});

  final String password;

  @override
  List<Object?> get props => [password];
}

/// Event to validate email format
class AuthEmailValidationRequested extends AuthEvent {
  const AuthEmailValidationRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}
