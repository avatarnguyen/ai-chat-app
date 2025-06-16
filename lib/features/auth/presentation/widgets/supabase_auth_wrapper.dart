import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/auth_ui_page.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Simplified authentication wrapper using Supabase auth state
class SupabaseAuthWrapper extends StatelessWidget {
  const SupabaseAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Check if user is authenticated
        final session = Supabase.instance.client.auth.currentSession;
        final user = session?.user;

        if (user != null) {
          // User is authenticated, show home page
          return const HomePage();
        } else {
          // User is not authenticated, show auth page
          return const AuthUIPage();
        }
      },
    );
  }
}

/// Helper widget for pages that require authentication
class AuthenticatedGuard extends StatelessWidget {
  const AuthenticatedGuard({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return child;
    }

    return fallback ?? const AuthUIPage();
  }
}

/// Helper widget for unauthenticated-only pages
class UnauthenticatedGuard extends StatelessWidget {
  const UnauthenticatedGuard({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return child;
    }

    return fallback ?? const HomePage();
  }
}

/// Extension for easy authentication checks
extension AuthenticationHelper on BuildContext {
  /// Check if user is authenticated
  bool get isAuthenticated {
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Get current user (null if not authenticated)
  User? get currentUser {
    return Supabase.instance.client.auth.currentUser;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  /// Navigate to login page
  void navigateToAuth() {
    Navigator.of(
      this,
    ).pushNamedAndRemoveUntil(AuthUIPage.routeName, (route) => false);
  }

  /// Navigate to home page
  void navigateToHome() {
    Navigator.of(
      this,
    ).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
  }
}
