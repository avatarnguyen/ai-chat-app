import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        print('✅ Environment variables loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ No .env file found or error loading: $e');
        print('Using default development configuration');
      }
    }
  }

  // Default local development configuration
  static const String _defaultLocalUrl = 'http://127.0.0.1:54321';
  static const String _defaultLocalAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// Get environment variable with fallback
  static String _getEnvVar(String key, {String? fallback}) {
    return dotenv.env[key] ?? fallback ?? '';
  }

  /// Get boolean environment variable
  static bool _getBoolEnvVar(String key, {bool fallback = false}) {
    final value = dotenv.env[key]?.toLowerCase();
    return value == 'true' || value == '1' ? true : fallback;
  }

  /// Get the appropriate Supabase URL based on environment
  static String get supabaseUrl {
    if (kDebugMode || _getEnvVar('APP_ENV') == 'development') {
      return _getEnvVar('LOCAL_SUPABASE_URL', fallback: _defaultLocalUrl);
    }
    return _getEnvVar('SUPABASE_URL');
  }

  /// Get the appropriate Supabase anonymous key based on environment
  static String get supabaseAnonKey {
    if (kDebugMode || _getEnvVar('APP_ENV') == 'development') {
      return _getEnvVar(
        'LOCAL_SUPABASE_ANON_KEY',
        fallback: _defaultLocalAnonKey,
      );
    }
    return _getEnvVar('SUPABASE_ANON_KEY');
  }

  /// Get Supabase service role key (for server-side operations)
  static String get supabaseServiceRoleKey {
    return _getEnvVar('SUPABASE_SERVICE_ROLE_KEY');
  }

  /// Initialize Supabase with configuration
  static Future<void> initialize() async {
    try {
      await loadEnv();

      // Validate required environment variables
      final url = supabaseUrl;
      final anonKey = supabaseAnonKey;

      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception(
          'Missing required Supabase configuration. '
          'Please check your .env file or environment variables.',
        );
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
          timeout: Duration(seconds: 60),
        ),
        storageOptions: const StorageClientOptions(retryAttempts: 3),
      );

      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
        print('📍 URL: $supabaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the auth client
  static GoTrueClient get auth => client.auth;

  /// Get the storage client
  static SupabaseStorageClient get storage => client.storage;

  /// Get the realtime client
  static RealtimeClient get realtime => client.realtime;

  /// Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => auth.currentUser?.id;

  /// Authentication configuration for different providers
  static const Map<String, dynamic> authConfig = {
    'email': {
      'enabled': true,
      'confirmEmail': false, // Set to true in production
      'autoSignIn': true,
    },
    'google': {
      'enabled': true,
      'scopes': ['email', 'profile'],
    },
    'apple': {
      'enabled': true,
      'scopes': ['email', 'name'],
    },
  };

  /// Site URL configuration for auth redirects
  static String get siteUrl {
    if (kDebugMode) {
      return 'http://localhost:3000';
    }
    return 'https://your-production-domain.com';
  }

  /// Redirect URLs for OAuth providers
  static List<String> get redirectUrls => [
    siteUrl,
    '$siteUrl/auth/callback',
    // Add deep link URLs for mobile
    'com.example.aichatapp://auth/callback',
  ];

  /// Authentication session configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration refreshTokenThreshold = Duration(minutes: 5);

  /// Rate limiting configuration
  static const Map<String, int> rateLimits = {
    'signUp': 5, // per hour
    'signIn': 10, // per hour
    'passwordReset': 3, // per hour
    'emailVerification': 5, // per hour
  };

  /// JWT configuration
  static const Map<String, dynamic> jwtConfig = {
    'secret': 'your-jwt-secret', // Should be loaded from environment
    'expiresIn': '1h',
    'issuer': 'supabase',
    'audience': 'authenticated',
  };

  /// Database configuration
  static const Map<String, dynamic> databaseConfig = {
    'maxConnections': 100,
    'idleTimeout': '10m',
    'maxLifetime': '1h',
    'schemas': ['public', 'auth'],
  };

  /// Storage configuration
  static const Map<String, dynamic> storageConfig = {
    'maxFileSize': 50 * 1024 * 1024, // 50MB
    'allowedMimeTypes': [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'text/plain',
      'application/json',
    ],
    'buckets': {
      'chat-attachments': {
        'public': false,
        'fileSizeLimit': 50 * 1024 * 1024, // 50MB
        'allowedMimeTypes': [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
          'application/pdf',
          'text/plain',
        ],
      },
      'user-avatars': {
        'public': true,
        'fileSizeLimit': 5 * 1024 * 1024, // 5MB
        'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/webp'],
      },
      'conversation-exports': {
        'public': false,
        'fileSizeLimit': 100 * 1024 * 1024, // 100MB
        'allowedMimeTypes': [
          'application/json',
          'text/plain',
          'application/pdf',
        ],
      },
    },
  };

  /// Realtime configuration
  static const Map<String, dynamic> realtimeConfig = {
    'enabled': true,
    'heartbeatInterval': 30000, // 30 seconds
    'reconnectAfterMs': [1000, 2000, 5000, 10000], // Exponential backoff
    'logger': kDebugMode,
  };

  /// Error handling configuration
  static const Map<String, String> errorMessages = {
    'invalid_credentials': 'Invalid email or password',
    'email_not_confirmed': 'Please check your email and confirm your account',
    'user_not_found': 'No account found with this email',
    'weak_password': 'Password should be at least 6 characters',
    'email_already_registered': 'An account with this email already exists',
    'network_error': 'Network error. Please check your connection',
    'server_error': 'Server error. Please try again later',
    'session_expired': 'Your session has expired. Please sign in again',
  };

  /// Validation patterns
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
  );

  /// Security headers for API requests
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };

  /// CORS configuration
  static const Map<String, dynamic> corsConfig = {
    'allowedOrigins': [
      'http://localhost:3000',
      'https://your-production-domain.com',
    ],
    'allowedMethods': ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    'allowedHeaders': [
      'Authorization',
      'Content-Type',
      'X-Client-Info',
      'X-Supabase-Auth',
    ],
    'exposedHeaders': ['X-Total-Count'],
    'maxAge': 86400, // 24 hours
  };
}
