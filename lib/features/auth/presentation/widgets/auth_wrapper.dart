import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../pages/login_page.dart';
import '../../domain/entities/user.dart';

/// Authentication wrapper that handles routing based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.authenticatedBuilder,
    this.unauthenticatedBuilder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Builder for authenticated state
  final Widget Function(BuildContext context, User user) authenticatedBuilder;

  /// Builder for unauthenticated state (defaults to LoginPage)
  final Widget Function(BuildContext context)? unauthenticatedBuilder;

  /// Builder for loading state (defaults to loading indicator)
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state (defaults to error screen)
  final Widget Function(BuildContext context, String error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Handle authenticated state
        if (state is AuthAuthenticated) {
          return authenticatedBuilder(context, state.user);
        }

        // Handle loading states
        if (state is AuthLoading ||
            state is AuthSignInLoading ||
            state is AuthSignUpLoading ||
            state is AuthGoogleSignInLoading ||
            state is AuthAppleSignInLoading) {
          return loadingBuilder?.call(context) ?? _buildDefaultLoading();
        }

        // Handle error state
        if (state is AuthError) {
          return errorBuilder?.call(context, state.message) ??
              _buildDefaultError(context, state.message);
        }

        // Handle unauthenticated state (default)
        return unauthenticatedBuilder?.call(context) ?? const LoginPage();
      },
    );
  }

  /// Default loading widget
  Widget _buildDefaultLoading() {
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

  /// Default error widget
  Widget _buildDefaultError(BuildContext context, String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().clearError();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple authenticated check widget
class AuthenticatedOnly extends StatelessWidget {
  const AuthenticatedOnly({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Simple unauthenticated check widget
class UnauthenticatedOnly extends StatelessWidget {
  const UnauthenticatedOnly({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthUnauthenticated) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that provides user data when authenticated
class AuthUserBuilder extends StatelessWidget {
  const AuthUserBuilder({super.key, required this.builder, this.fallback});

  final Widget Function(BuildContext context, User user) builder;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return builder(context, state.user);
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Mixin for pages that require authentication
mixin AuthRequiredMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authBloc = context.read<AuthBloc>();
    if (!authBloc.isAuthenticated) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
    }
  }
}

/// Helper extension for authentication checks
extension AuthenticationHelper on BuildContext {
  /// Check if user is authenticated
  bool get isAuthenticated {
    final state = read<AuthBloc>().state;
    return state is AuthAuthenticated;
  }

  /// Get current user (null if not authenticated)
  User? get currentUser {
    final state = read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user;
    }
    return null;
  }

  /// Sign out current user
  void signOut() {
    read<AuthBloc>().signOut();
  }

  /// Navigate to login page
  void navigateToLogin() {
    Navigator.of(
      this,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
  }
}
