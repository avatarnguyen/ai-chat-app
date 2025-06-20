import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/auth_repository.dart';

/// Service for handling Apple OAuth authentication
@injectable
class AppleOAuthService {
  AppleOAuthService();

  /// Sign in with Apple
  /// Returns the Apple ID credential or throws an exception
  Future<AuthorizationCredentialAppleID> signIn() async {
    try {
      // Check if Apple Sign In is available
      if (!await isAvailable()) {
        throw const UnknownAuthException(
          'Apple Sign In is not available on this device',
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // Configure for web if needed
          clientId: 'your-service-id', // Replace with your actual service ID
          redirectUri: Uri.parse('https://your-domain.com/auth/callback'),
        ),
      );

      return credential;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException) {
        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            throw const UnknownAuthException('Apple Sign In was canceled');
          case AuthorizationErrorCode.failed:
            throw const UnknownAuthException('Apple Sign In failed');
          case AuthorizationErrorCode.invalidResponse:
            throw const UnknownAuthException('Invalid Apple Sign In response');
          case AuthorizationErrorCode.notHandled:
            throw const UnknownAuthException('Apple Sign In not handled');
          case AuthorizationErrorCode.notInteractive:
            throw const UnknownAuthException('Apple Sign In not interactive');
          case AuthorizationErrorCode.unknown:
            throw const UnknownAuthException('Unknown Apple Sign In error');
        }
      }
      throw UnknownAuthException('Apple Sign In failed: ${e.toString()}');
    }
  }

  /// Check if Apple Sign In is available on this device
  Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Get credential state for a given user ID
  /// This is useful for checking if a user is still signed in
  Future<CredentialState> getCredentialState(String userIdentifier) async {
    try {
      return await SignInWithApple.getCredentialState(userIdentifier);
    } catch (e) {
      throw UnknownAuthException(
        'Failed to get Apple credential state: ${e.toString()}',
      );
    }
  }

  /// Check if Apple Sign In is supported on the current platform
  bool get isSupported {
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Parse Apple ID credential to user profile data
  Map<String, dynamic> parseCredential(
    AuthorizationCredentialAppleID credential,
  ) {
    return {
      'userIdentifier': credential.userIdentifier,
      'email': credential.email,
      'givenName': credential.givenName,
      'familyName': credential.familyName,
      'identityToken': credential.identityToken,
      'authorizationCode': credential.authorizationCode,
      'state': credential.state,
    };
  }

  /// Extract display name from Apple credential
  String? getDisplayName(AuthorizationCredentialAppleID credential) {
    final givenName = credential.givenName;
    final familyName = credential.familyName;

    if (givenName != null && familyName != null) {
      return '$givenName $familyName';
    } else if (givenName != null) {
      return givenName;
    } else if (familyName != null) {
      return familyName;
    }

    return null;
  }

  /// Validate Apple Sign In configuration
  /// Returns true if properly configured for the current platform
  Future<bool> validateConfiguration() async {
    if (!isSupported) {
      return false;
    }

    try {
      // Check if Apple Sign In is available
      return await isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Sign out from Apple
  /// Note: Apple doesn't provide a direct sign out method
  /// You should handle this in your app's authentication state
  Future<void> signOut() async {
    // Apple doesn't provide a direct sign out method
    // The sign out should be handled by clearing the user's session
    // in your app's authentication system
  }

  /// Get the current credential state for a user
  /// This is useful for checking if the user's Apple ID is still valid
  Future<bool> isUserSignedIn(String userIdentifier) async {
    try {
      final state = await getCredentialState(userIdentifier);
      return state == CredentialState.authorized;
    } catch (e) {
      return false;
    }
  }

  /// Revoke Apple ID authorization
  /// Note: This is typically handled by the user in their Apple ID settings
  /// Your app should handle the revocation by monitoring credential state
  Future<void> revokeAuthorization() async {
    // Apple doesn't provide a direct revoke method
    // Users must revoke access through their Apple ID settings
    // Your app should monitor credential state changes
    throw const UnknownAuthException(
      'Apple ID authorization must be revoked through Apple ID settings',
    );
  }
}
