import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Bloc for managing authentication state and events
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    // Register event handlers
    on<AuthInitialized>(_onAuthInitialized);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordChangeRequested>(_onPasswordChangeRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthAccountDeletionRequested>(_onAccountDeletionRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthEmailVerificationResendRequested>(
      _onEmailVerificationResendRequested,
    );
    on<AuthSessionRefreshRequested>(_onSessionRefreshRequested);
    on<AuthEmailRegistrationCheckRequested>(_onEmailRegistrationCheckRequested);
    on<AuthLastActiveUpdateRequested>(_onLastActiveUpdateRequested);
    on<AuthUsageStatsRequested>(_onUsageStatsRequested);
    on<AuthMessageLimitCheckRequested>(_onMessageLimitCheckRequested);
    on<AuthMessageCountIncrementRequested>(_onMessageCountIncrementRequested);
    on<AuthTokenUsageAddRequested>(_onTokenUsageAddRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthPasswordValidationRequested>(_onPasswordValidationRequested);
    on<AuthEmailValidationRequested>(_onEmailValidationRequested);

    // Initialize authentication
    add(const AuthInitialized());
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  /// Initialize authentication and listen to auth state changes
  Future<void> _onAuthInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Start listening to auth state changes
      _authStateSubscription = _authRepository.authStateChanges.listen(
        (user) => add(AuthStateChanged(user)),
      );

      // Check current authentication status
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        emit(AuthAuthenticated(user: currentUser));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(
        AuthError(
          message: 'Failed to initialize authentication: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user as User?;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle sign up request
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignUpLoading());

    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      emit(
        AuthSignUpSuccess(
          user: user,
          requiresEmailVerification: !user.isEmailVerified,
        ),
      );
    } on AuthException catch (e) {
      emit(AuthSignUpError(message: e.message));
    } catch (e) {
      emit(
        AuthSignUpError(
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle sign in request
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignInLoading());

    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      emit(AuthSignInSuccess(user: user));
    } on AuthException catch (e) {
      emit(AuthSignInError(message: e.message));
    } catch (e) {
      emit(
        AuthSignInError(
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle Google sign in request
  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthGoogleSignInLoading());

    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthSignInSuccess(user: user));
    } on AuthException catch (e) {
      emit(AuthSignInError(message: e.message));
    } catch (e) {
      emit(AuthSignInError(message: 'Google sign in failed: ${e.toString()}'));
    }
  }

  /// Handle Apple sign in request
  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAppleSignInLoading());

    try {
      final user = await _authRepository.signInWithApple();
      emit(AuthSignInSuccess(user: user));
    } on AuthException catch (e) {
      emit(AuthSignInError(message: e.message));
    } catch (e) {
      emit(AuthSignInError(message: 'Apple sign in failed: ${e.toString()}'));
    }
  }

  /// Handle sign out request
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignOutLoading());

    try {
      await _authRepository.signOut();
      emit(const AuthSignOutSuccess());
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Sign out failed: ${e.toString()}'));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthPasswordResetLoading());

    try {
      await _authRepository.resetPassword(email: event.email);
      emit(
        const AuthPasswordResetSuccess(
          message: 'Password reset email sent. Please check your inbox.',
        ),
      );
    } on AuthException catch (e) {
      emit(AuthPasswordResetError(message: e.message));
    } catch (e) {
      emit(
        AuthPasswordResetError(
          message: 'Failed to send password reset email: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle password change request
  Future<void> _onPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthPasswordChangeLoading());

    try {
      await _authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const AuthPasswordChangeSuccess());
    } on AuthException catch (e) {
      emit(AuthPasswordChangeError(message: e.message));
    } catch (e) {
      emit(
        AuthPasswordChangeError(
          message: 'Failed to change password: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle profile update request
  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthProfileUpdateLoading());

    try {
      final user = await _authRepository.updateProfile(
        displayName: event.displayName,
        bio: event.bio,
        avatarUrl: event.avatarUrl,
        preferredModel: event.preferredModel,
        themePreference: event.themePreference,
        languagePreference: event.languagePreference,
      );
      emit(AuthProfileUpdateSuccess(user: user));
    } on AuthException catch (e) {
      emit(AuthProfileUpdateError(message: e.message));
    } catch (e) {
      emit(
        AuthProfileUpdateError(
          message: 'Failed to update profile: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle account deletion request
  Future<void> _onAccountDeletionRequested(
    AuthAccountDeletionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAccountDeletionLoading());

    try {
      await _authRepository.deleteAccount();
      emit(const AuthAccountDeletionSuccess());
    } on AuthException catch (e) {
      emit(AuthAccountDeletionError(message: e.message));
    } catch (e) {
      emit(
        AuthAccountDeletionError(
          message: 'Failed to delete account: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle email verification request
  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthEmailVerificationLoading());

    try {
      await _authRepository.verifyEmail(token: event.token);
      emit(const AuthEmailVerificationSuccess());
    } on AuthException catch (e) {
      emit(AuthEmailVerificationError(message: e.message));
    } catch (e) {
      emit(
        AuthEmailVerificationError(
          message: 'Email verification failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle email verification resend request
  Future<void> _onEmailVerificationResendRequested(
    AuthEmailVerificationResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthEmailVerificationResendLoading());

    try {
      await _authRepository.resendEmailVerification();
      emit(const AuthEmailVerificationResendSuccess());
    } on AuthException catch (e) {
      emit(AuthEmailVerificationError(message: e.message));
    } catch (e) {
      emit(
        AuthEmailVerificationError(
          message: 'Failed to resend verification email: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle session refresh request
  Future<void> _onSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSessionRefreshLoading());

    try {
      final user = await _authRepository.refreshSession();
      emit(AuthSessionRefreshSuccess(user: user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Session refresh failed: ${e.toString()}'));
    }
  }

  /// Handle email registration check request
  Future<void> _onEmailRegistrationCheckRequested(
    AuthEmailRegistrationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthEmailRegistrationCheckLoading());

    try {
      final isRegistered = await _authRepository.isEmailRegistered(
        email: event.email,
      );
      emit(AuthEmailRegistrationCheckSuccess(isRegistered: isRegistered));
    } catch (e) {
      emit(
        AuthError(
          message: 'Failed to check email registration: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle last active update request
  Future<void> _onLastActiveUpdateRequested(
    AuthLastActiveUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.updateLastActive();
      // Don't emit a state change for this background operation
    } catch (e) {
      // Silently fail for this non-critical operation
    }
  }

  /// Handle usage stats request
  Future<void> _onUsageStatsRequested(
    AuthUsageStatsRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUsageStatsLoading());

    try {
      final stats = await _authRepository.getUserUsageStats();
      emit(AuthUsageStatsSuccess(stats: stats));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Failed to get usage stats: ${e.toString()}'));
    }
  }

  /// Handle message limit check request
  Future<void> _onMessageLimitCheckRequested(
    AuthMessageLimitCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthMessageLimitCheckLoading());

    try {
      final hasReachedLimit = await _authRepository.hasReachedMessageLimit();
      emit(AuthMessageLimitCheckSuccess(hasReachedLimit: hasReachedLimit));
    } catch (e) {
      emit(
        AuthError(message: 'Failed to check message limit: ${e.toString()}'),
      );
    }
  }

  /// Handle message count increment request
  Future<void> _onMessageCountIncrementRequested(
    AuthMessageCountIncrementRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.incrementMessageCount();
      // Don't emit a state change for this background operation
    } catch (e) {
      // Silently fail for this non-critical operation
    }
  }

  /// Handle token usage add request
  Future<void> _onTokenUsageAddRequested(
    AuthTokenUsageAddRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.addTokenUsage(tokens: event.tokens);
      // Don't emit a state change for this background operation
    } catch (e) {
      // Silently fail for this non-critical operation
    }
  }

  /// Handle error cleared request
  Future<void> _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) async {
    // Return to appropriate state based on current authentication status
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      emit(AuthAuthenticated(user: currentUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle password validation request
  Future<void> _onPasswordValidationRequested(
    AuthPasswordValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isValid = _authRepository.validatePassword(event.password);
    emit(AuthPasswordValidationSuccess(isValid: isValid));
  }

  /// Handle email validation request
  Future<void> _onEmailValidationRequested(
    AuthEmailValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isValid = _authRepository.validateEmail(event.email);
    emit(AuthEmailValidationSuccess(isValid: isValid));
  }

  /// Get current authenticated user
  User? get currentUser => _authRepository.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _authRepository.isAuthenticated;

  /// Convenience method to sign in with email and password
  void signIn({required String email, required String password}) {
    add(AuthSignInRequested(email: email, password: password));
  }

  /// Convenience method to sign up with email and password
  void signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    add(
      AuthSignUpRequested(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  /// Convenience method to sign in with Google
  void signInWithGoogle() {
    add(const AuthGoogleSignInRequested());
  }

  /// Convenience method to sign in with Apple
  void signInWithApple() {
    add(const AuthAppleSignInRequested());
  }

  /// Convenience method to sign out
  void signOut() {
    add(const AuthSignOutRequested());
  }

  /// Convenience method to reset password
  void resetPassword({required String email}) {
    add(AuthPasswordResetRequested(email: email));
  }

  /// Convenience method to update profile
  void updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
  }) {
    add(
      AuthProfileUpdateRequested(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        preferredModel: preferredModel,
        themePreference: themePreference,
        languagePreference: languagePreference,
      ),
    );
  }

  /// Convenience method to clear errors
  void clearError() {
    add(const AuthErrorCleared());
  }

  /// Convenience method to validate email
  void validateEmail({required String email}) {
    add(AuthEmailValidationRequested(email: email));
  }

  /// Convenience method to validate password
  void validatePassword({required String password}) {
    add(AuthPasswordValidationRequested(password: password));
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
