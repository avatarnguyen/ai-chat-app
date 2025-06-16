import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ai_chat_app/core/di/injection_container.dart';
import 'package:ai_chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ai_chat_app/features/auth/domain/entities/user.dart'
    as app_user;
import 'package:ai_chat_app/features/auth/presentation/bloc/auth_bloc.dart';

/// Mock Supabase client for testing
class MockSupabaseClient extends SupabaseClient {
  MockSupabaseClient() : super('test', 'test', httpClient: null);
}

/// Mock AuthRepository for testing
class MockAuthRepository implements AuthRepository {
  @override
  Stream<app_user.User?> get authStateChanges => Stream.empty();

  @override
  app_user.User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  Future<app_user.User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async => throw UnimplementedError();

  @override
  Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<app_user.User> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<app_user.User> signInWithApple() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<app_user.User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? preferredModel,
    String? themePreference,
    String? languagePreference,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> verifyEmail({required String token}) async {}

  @override
  Future<void> resendEmailVerification() async {}

  @override
  Future<app_user.User> refreshSession() async => throw UnimplementedError();

  @override
  Future<bool> isEmailRegistered({required String email}) async => false;

  @override
  Future<app_user.User?> getUserProfile({required String userId}) async => null;

  @override
  Future<void> updateLastActive() async {}

  @override
  Future<Map<String, dynamic>> getUserUsageStats() async => {};

  @override
  Future<bool> hasReachedMessageLimit() async => false;

  @override
  Future<void> incrementMessageCount() async {}

  @override
  Future<void> addTokenUsage({required int tokens}) async {}

  @override
  bool validatePassword(String password) => true;

  @override
  bool validateEmail(String email) => true;
}

void main() {
  group('Dependency Injection Container Tests', () {
    late GetIt getIt;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      getIt = GetIt.instance;
      mockAuthRepository = MockAuthRepository();

      // Register test dependencies manually
      getIt.registerSingleton<SupabaseClient>(MockSupabaseClient());
      getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('should register and retrieve dependencies successfully', () {
      // Assert - Check that basic dependencies are registered
      expect(getIt.isRegistered<SupabaseClient>(), isTrue);
      expect(getIt.isRegistered<AuthRepository>(), isTrue);

      // Act & Assert - Should be able to retrieve dependencies
      final supabaseClient = getIt<SupabaseClient>();
      final authRepository = getIt<AuthRepository>();

      expect(supabaseClient, isNotNull);
      expect(authRepository, isNotNull);
      expect(authRepository, isA<MockAuthRepository>());
    });

    test('should return same instance for singleton dependencies', () {
      // Act
      final authRepo1 = getIt<AuthRepository>();
      final authRepo2 = getIt<AuthRepository>();
      final supabase1 = getIt<SupabaseClient>();
      final supabase2 = getIt<SupabaseClient>();

      // Assert - Singletons should return same instance
      expect(identical(authRepo1, authRepo2), isTrue);
      expect(identical(supabase1, supabase2), isTrue);
    });

    test('should return new instances for factory dependencies', () {
      // Arrange - Register auth bloc as factory
      getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));

      // Act
      final authBloc1 = getIt<AuthBloc>();
      final authBloc2 = getIt<AuthBloc>();

      // Assert - Factory should return new instances
      expect(identical(authBloc1, authBloc2), isFalse);
      expect(authBloc1.runtimeType, equals(authBloc2.runtimeType));
    });

    test('should properly inject dependencies', () {
      // Arrange
      getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));

      // Act
      final authBloc = getIt<AuthBloc>();

      // Assert - AuthBloc should be properly instantiated with dependencies
      expect(authBloc, isNotNull);
      expect(authBloc, isA<AuthBloc>());
    });

    test('should reset dependencies successfully', () async {
      // Arrange
      expect(getIt.isRegistered<AuthRepository>(), isTrue);

      // Act
      await resetDependencies();

      // Assert
      expect(getIt.isRegistered<AuthRepository>(), isFalse);
      expect(getIt.isRegistered<SupabaseClient>(), isFalse);
    });

    test('should check if dependencies are configured', () {
      // Assert - Should detect configuration since we set up in setUp
      expect(isDependenciesConfigured, isTrue);
      expect(getIt.isRegistered<AuthRepository>(), isTrue);
    });

    group('Error Handling', () {
      test('should handle accessing registered dependency gracefully', () {
        // Act & Assert - Should not throw when dependencies are registered
        expect(() => getIt<AuthRepository>(), returnsNormally);
        expect(() => getIt<SupabaseClient>(), returnsNormally);
      });

      test('should throw when accessing unregistered dependency', () {
        // Act & Assert
        expect(() => getIt<String>(), throwsA(isA<StateError>()));
      });

      test('should handle dependency registration twice', () {
        // Act & Assert - Should throw when trying to register same type twice
        expect(
          () => getIt.registerSingleton<AuthRepository>(MockAuthRepository()),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Dependency Registration Types', () {
      test('should register core dependencies with correct types', () {
        // Act & Assert - Check registration types
        expect(getIt.isRegistered<SupabaseClient>(), isTrue);
        expect(getIt.isRegistered<AuthRepository>(), isTrue);

        // Verify types
        expect(getIt<SupabaseClient>(), isA<MockSupabaseClient>());
        expect(getIt<AuthRepository>(), isA<MockAuthRepository>());
      });
    });

    group('Helper Functions', () {
      test('should provide helper functions for dependency access', () {
        // Act & Assert - Test helper functions
        expect(getDependency<AuthRepository>(), isA<AuthRepository>());
        expect(isDependencyRegistered<AuthRepository>(), isTrue);
        expect(isDependencyRegistered<String>(), isFalse);
      });

      test('should unregister specific dependency', () async {
        // Arrange
        expect(getIt.isRegistered<AuthRepository>(), isTrue);

        // Act
        await unregisterDependency<AuthRepository>();

        // Assert
        expect(getIt.isRegistered<AuthRepository>(), isFalse);
      });

      test(
        'should handle unregistering non-existent dependency gracefully',
        () async {
          // Act & Assert - Should not throw when unregistering non-existent dependency
          expect(
            () async => await unregisterDependency<String>(),
            returnsNormally,
          );
        },
      );
    });

    group('Configuration Functions', () {
      test('should have configuration methods available', () {
        // Act & Assert - Test configuration functions exist
        expect(configureDependenciesWithEnvironment, isA<Function>());
        expect(configureTestDependencies, isA<Function>());
        expect(configureDevelopmentDependencies, isA<Function>());
        expect(configureProductionDependencies, isA<Function>());
      });
    });
  });
}
