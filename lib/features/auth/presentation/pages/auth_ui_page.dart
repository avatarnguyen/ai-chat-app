import 'package:ai_chat_app/core/utils/context_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../../../home/presentation/pages/home_page.dart';

/// Comprehensive authentication page using Supabase Auth UI components
///
/// This page provides a complete authentication solution with:
/// - Social authentication (Apple, Facebook, Google)
/// - Email authentication
/// - Responsive design with proper error handling
/// - Accessibility support with semantic labels
///
/// The page uses Supabase Auth UI components for consistent styling
/// and automatic handling of authentication flows.
class AuthUIPage extends StatefulWidget {
  const AuthUIPage({super.key});

  static const String routeName = '/auth';

  @override
  State<AuthUIPage> createState() => _AuthUIPageState();
}

class _AuthUIPageState extends State<AuthUIPage> {
  bool _isLoading = false;

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _handleAuthSuccess() {
    if (mounted) {
      // Navigate to home page and remove all previous routes
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
    }
  }

  void _handleAuthError(Object error) {
    if (mounted) {
      String errorMessage = 'Authentication error';

      if (error is AuthException) {
        switch (error.message) {
          case 'Invalid login credentials':
            errorMessage = 'Invalid email or password';
            break;
          case 'Email not confirmed':
            errorMessage = 'Please check your email and confirm your account';
            break;
          case 'User already registered':
            errorMessage = 'An account with this email already exists';
            break;
          case 'Password should be at least 6 characters':
            errorMessage = 'Password must be at least 6 characters long';
            break;
          default:
            errorMessage = error.message;
        }
      } else {
        errorMessage = error.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Welcome title
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 3),

                  // Authentication buttons
                  Column(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              minimumSize: const Size(double.infinity, 56),
                              elevation: 0,
                            ),
                          ),
                        ),
                        child: SupaSocialsAuth(
                          socialProviders: [
                            OAuthProvider.apple,
                            OAuthProvider.google,
                          ],
                          colored: true,
                          redirectUrl:
                              kIsWeb
                                  ? null
                                  : 'io.supabase.flutter://reset-callback/',
                          onSuccess: (Session response) {
                            _handleAuthSuccess();
                          },
                          onError: (error) {
                            _handleAuthError(error);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sign up with Email
                      _buildAuthButton(
                        onPressed: () => _showEmailAuthDialog(),
                        icon: Icons.email,
                        text: 'Sign up with Email',
                        backgroundColor: const Color(0xFF4CAF50),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Authenticating...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailAuthDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: context.screenHeight(0.85)),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Sign up with Email',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address to create an account or sign in',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Email Auth Form
                  SupaEmailAuth(
                    onSignInComplete: (response) {
                      Navigator.pop(context);
                      _setLoading(false);
                      _handleAuthSuccess();
                    },
                    onSignUpComplete: (response) {
                      Navigator.pop(context);
                      _setLoading(false);
                      if (response.user?.emailConfirmedAt != null) {
                        _handleAuthSuccess();
                      } else {
                        context.showPopup(
                          'Please check your email to verify your account',
                          iconData: Icons.mark_email_unread,
                        );
                      }
                    },
                    onError: (error) {
                      Navigator.pop(context);
                      _setLoading(false);
                      _handleAuthError(error);
                    },
                    metadataFields: [
                      MetaDataField(
                        prefixIcon: const Icon(Icons.person),
                        label: 'Display Name',
                        key: 'display_name',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your display name';
                          }
                          if (val.length < 2) {
                            return 'Display name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
                ],
              ),
            ),
          ),
    );
  }
}
