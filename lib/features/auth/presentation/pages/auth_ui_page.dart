import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Authentication page using Supabase Auth UI components
class AuthUIPage extends StatefulWidget {
  const AuthUIPage({super.key});

  static const String routeName = '/auth';

  @override
  State<AuthUIPage> createState() => _AuthUIPageState();
}

class _AuthUIPageState extends State<AuthUIPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _handleAuthSuccess() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(HomePage.routeName);
    }
  }

  void _handleAuthError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Welcome Text
                    Text(
                      'Welcome to AI Chat',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to start conversations with AI',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Auth Tabs
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Tab Bar
                            TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: const [
                                Tab(text: 'Email'),
                                Tab(text: 'Magic Link'),
                                Tab(text: 'Social'),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Tab Views
                            SizedBox(
                              height: 350,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildEmailAuthTab(),
                                  _buildMagicLinkTab(),
                                  _buildSocialAuthTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailAuthTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SupaEmailAuth(
            redirectTo: kIsWeb ? null : 'io.mydomain.myapp://callback',
            onSignInComplete: (response) {
              _setLoading(false);
              _handleAuthSuccess();
            },
            onSignUpComplete: (response) {
              _setLoading(false);
              if (response.user?.emailConfirmedAt != null) {
                _handleAuthSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please check your email to verify your account',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            onError: (error) {
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
        ],
      ),
    );
  }

  Widget _buildMagicLinkTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Magic Link Sign In',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email to receive a magic link for passwordless authentication',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SupaMagicAuth(
            redirectUrl: kIsWeb ? null : 'io.mydomain.myapp://callback',
            onSuccess: (response) {
              _setLoading(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Magic link sent! Please check your email'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onError: (error) {
              _setLoading(false);
              _handleAuthError(error);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialAuthTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Social Sign In',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your preferred social provider',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SupaSocialsAuth(
            socialProviders: const [
              OAuthProvider.google,
              OAuthProvider.apple,
              OAuthProvider.github,
            ],
            colored: true,
            redirectUrl: kIsWeb ? null : 'io.mydomain.myapp://callback',
            onSuccess: (response) {
              _setLoading(false);
              _handleAuthSuccess();
            },
            onError: (error) {
              _setLoading(false);
              _handleAuthError(error);
            },
          ),
          const SizedBox(height: 24),

          // Custom styled social buttons for better design
          Column(
            children: [
              _buildCustomSocialButton(
                provider: OAuthProvider.google,
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                color: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              _buildCustomSocialButton(
                provider: OAuthProvider.apple,
                label: 'Continue with Apple',
                icon: Icons.apple,
                color: Colors.black,
                textColor: Colors.white,
              ),
              const SizedBox(height: 12),
              _buildCustomSocialButton(
                provider: OAuthProvider.github,
                label: 'Continue with GitHub',
                icon: Icons.code,
                color: const Color(0xFF24292E),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSocialButton({
    required OAuthProvider provider,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          _setLoading(true);
          try {
            await Supabase.instance.client.auth.signInWithOAuth(
              provider,
              redirectTo: kIsWeb ? null : 'io.mydomain.myapp://callback',
            );
          } catch (error) {
            _setLoading(false);
            _handleAuthError(error);
          }
        },
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(color: borderColor ?? color, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
