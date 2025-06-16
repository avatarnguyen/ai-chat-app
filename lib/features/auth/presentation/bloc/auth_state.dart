import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Authentication status enum
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial authentication state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Authentication loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated state
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, this.message});

  final User user;
  final String? message;

  @override
  List<Object?> get props => [user, message];

  AuthAuthenticated copyWith({User? user, String? message}) {
    return AuthAuthenticated(
      user: user ?? this.user,
      message: message ?? this.message,
    );
  }
}

/// User is not authenticated state
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Authentication error state
class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Sign up loading state
class AuthSignUpLoading extends AuthState {
  const AuthSignUpLoading();
}

/// Sign up success state
class AuthSignUpSuccess extends AuthState {
  const AuthSignUpSuccess({
    required this.user,
    this.requiresEmailVerification = false,
  });

  final User user;
  final bool requiresEmailVerification;

  @override
  List<Object?> get props => [user, requiresEmailVerification];
}

/// Sign up error state
class AuthSignUpError extends AuthState {
  const AuthSignUpError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Sign in loading state
class AuthSignInLoading extends AuthState {
  const AuthSignInLoading();
}

/// Sign in success state
class AuthSignInSuccess extends AuthState {
  const AuthSignInSuccess({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Sign in error state
class AuthSignInError extends AuthState {
  const AuthSignInError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Google sign in loading state
class AuthGoogleSignInLoading extends AuthState {
  const AuthGoogleSignInLoading();
}

/// Apple sign in loading state
class AuthAppleSignInLoading extends AuthState {
  const AuthAppleSignInLoading();
}

/// Sign out loading state
class AuthSignOutLoading extends AuthState {
  const AuthSignOutLoading();
}

/// Sign out success state
class AuthSignOutSuccess extends AuthState {
  const AuthSignOutSuccess();
}

/// Password reset loading state
class AuthPasswordResetLoading extends AuthState {
  const AuthPasswordResetLoading();
}

/// Password reset success state
class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Password reset error state
class AuthPasswordResetError extends AuthState {
  const AuthPasswordResetError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Password change loading state
class AuthPasswordChangeLoading extends AuthState {
  const AuthPasswordChangeLoading();
}

/// Password change success state
class AuthPasswordChangeSuccess extends AuthState {
  const AuthPasswordChangeSuccess();
}

/// Password change error state
class AuthPasswordChangeError extends AuthState {
  const AuthPasswordChangeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Profile update loading state
class AuthProfileUpdateLoading extends AuthState {
  const AuthProfileUpdateLoading();
}

/// Profile update success state
class AuthProfileUpdateSuccess extends AuthState {
  const AuthProfileUpdateSuccess({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Profile update error state
class AuthProfileUpdateError extends AuthState {
  const AuthProfileUpdateError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Account deletion loading state
class AuthAccountDeletionLoading extends AuthState {
  const AuthAccountDeletionLoading();
}

/// Account deletion success state
class AuthAccountDeletionSuccess extends AuthState {
  const AuthAccountDeletionSuccess();
}

/// Account deletion error state
class AuthAccountDeletionError extends AuthState {
  const AuthAccountDeletionError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Email verification loading state
class AuthEmailVerificationLoading extends AuthState {
  const AuthEmailVerificationLoading();
}

/// Email verification success state
class AuthEmailVerificationSuccess extends AuthState {
  const AuthEmailVerificationSuccess();
}

/// Email verification error state
class AuthEmailVerificationError extends AuthState {
  const AuthEmailVerificationError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Email verification resend loading state
class AuthEmailVerificationResendLoading extends AuthState {
  const AuthEmailVerificationResendLoading();
}

/// Email verification resend success state
class AuthEmailVerificationResendSuccess extends AuthState {
  const AuthEmailVerificationResendSuccess();
}

/// Session refresh loading state
class AuthSessionRefreshLoading extends AuthState {
  const AuthSessionRefreshLoading();
}

/// Session refresh success state
class AuthSessionRefreshSuccess extends AuthState {
  const AuthSessionRefreshSuccess({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Email registration check loading state
class AuthEmailRegistrationCheckLoading extends AuthState {
  const AuthEmailRegistrationCheckLoading();
}

/// Email registration check success state
class AuthEmailRegistrationCheckSuccess extends AuthState {
  const AuthEmailRegistrationCheckSuccess({required this.isRegistered});

  final bool isRegistered;

  @override
  List<Object?> get props => [isRegistered];
}

/// Usage stats loading state
class AuthUsageStatsLoading extends AuthState {
  const AuthUsageStatsLoading();
}

/// Usage stats success state
class AuthUsageStatsSuccess extends AuthState {
  const AuthUsageStatsSuccess({required this.stats});

  final Map<String, dynamic> stats;

  @override
  List<Object?> get props => [stats];
}

/// Message limit check loading state
class AuthMessageLimitCheckLoading extends AuthState {
  const AuthMessageLimitCheckLoading();
}

/// Message limit check success state
class AuthMessageLimitCheckSuccess extends AuthState {
  const AuthMessageLimitCheckSuccess({required this.hasReachedLimit});

  final bool hasReachedLimit;

  @override
  List<Object?> get props => [hasReachedLimit];
}

/// Password validation success state
class AuthPasswordValidationSuccess extends AuthState {
  const AuthPasswordValidationSuccess({required this.isValid});

  final bool isValid;

  @override
  List<Object?> get props => [isValid];
}

/// Email validation success state
class AuthEmailValidationSuccess extends AuthState {
  const AuthEmailValidationSuccess({required this.isValid});

  final bool isValid;

  @override
  List<Object?> get props => [isValid];
}

/// Combined authentication state with status and data
class AuthStateWithStatus extends AuthState {
  const AuthStateWithStatus({
    required this.status,
    this.user,
    this.message,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.successMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? message;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? successMessage;

  @override
  List<Object?> get props => [
    status,
    user,
    message,
    isLoading,
    hasError,
    errorMessage,
    successMessage,
  ];

  /// Check if user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Check if user is unauthenticated
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Check if state is initial
  bool get isInitial => status == AuthStatus.initial;

  /// Check if there's an error
  bool get isError => status == AuthStatus.error || hasError;

  /// Get current user or null
  User? get currentUser => user;

  /// Get error message
  String? get error => errorMessage ?? (hasError ? message : null);

  /// Get success message
  String? get success => successMessage;

  /// Create a copy with updated fields
  AuthStateWithStatus copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthStateWithStatus(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  /// Create loading state
  AuthStateWithStatus toLoading() {
    return copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
      successMessage: null,
    );
  }

  /// Create success state
  AuthStateWithStatus toSuccess({User? user, String? message}) {
    return copyWith(
      status: user != null ? AuthStatus.authenticated : status,
      user: user ?? this.user,
      isLoading: false,
      hasError: false,
      errorMessage: null,
      successMessage: message,
    );
  }

  /// Create error state
  AuthStateWithStatus toError(String message) {
    return copyWith(
      status: AuthStatus.error,
      isLoading: false,
      hasError: true,
      errorMessage: message,
      successMessage: null,
    );
  }

  /// Create authenticated state
  AuthStateWithStatus toAuthenticated(User user, {String? message}) {
    return copyWith(
      status: AuthStatus.authenticated,
      user: user,
      isLoading: false,
      hasError: false,
      errorMessage: null,
      successMessage: message,
    );
  }

  /// Create unauthenticated state
  AuthStateWithStatus toUnauthenticated({String? message}) {
    return copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      isLoading: false,
      hasError: false,
      errorMessage: null,
      successMessage: message,
    );
  }
}
