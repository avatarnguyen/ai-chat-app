import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/auth_repository.dart';

/// Service for handling Google OAuth authentication
@injectable
class GoogleOAuthService {
  GoogleOAuthService()
    : _googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  /// Sign in with Google
  /// Returns the Google user account or throws an exception
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Check if already signed in
      GoogleSignInAccount? account =
          _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently() ??
          await _googleSignIn.signIn();

      return account;
    } catch (e) {
      throw UnknownAuthException('Google sign in failed: ${e.toString()}');
    }
  }

  /// Get Google authentication tokens
  /// Returns the authentication object with access token and ID token
  Future<GoogleSignInAuthentication?> getAuthentication() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw const SessionExpiredException();
      }

      return await account.authentication;
    } catch (e) {
      throw UnknownAuthException(
        'Failed to get Google authentication: ${e.toString()}',
      );
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw UnknownAuthException('Google sign out failed: ${e.toString()}');
    }
  }

  /// Disconnect from Google (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      throw UnknownAuthException('Google disconnect failed: ${e.toString()}');
    }
  }

  /// Check if user is currently signed in with Google
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Get current Google user account
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Configure Google Sign-In with custom client ID (optional)
  /// This is useful when you need to set different client IDs for different environments
  void configure({
    String? clientId,
    List<String>? scopes,
    String? hostedDomain,
  }) {
    // Note: GoogleSignIn configuration is typically done at initialization
    // This method is for reference - actual configuration should be done
    // in the constructor or through platform-specific configuration files
  }

  /// Check if Google Play Services are available (Android only)
  Future<bool> isGooglePlayServicesAvailable() async {
    if (!Platform.isAndroid) {
      return true; // Not applicable on other platforms
    }

    try {
      // This is a simplified check - in a real implementation,
      // you might want to use a more robust method
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      // If silent sign-in fails due to Play Services issues,
      // we can assume they're not available or not configured properly
      return false;
    }
  }

  /// Get user profile information from Google account
  Map<String, dynamic>? getUserProfile() {
    final user = _googleSignIn.currentUser;
    if (user == null) return null;

    return {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    };
  }

  /// Validate Google Sign-In configuration
  /// Returns true if properly configured, false otherwise
  Future<bool> validateConfiguration() async {
    try {
      // Try to initialize and check if configuration is valid
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      // If we get specific configuration errors, return false
      if (e.toString().contains('configuration') ||
          e.toString().contains('client ID') ||
          e.toString().contains('GoogleService-Info.plist') ||
          e.toString().contains('google-services.json')) {
        return false;
      }
      // Other errors don't necessarily mean configuration is invalid
      return true;
    }
  }
}
