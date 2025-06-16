import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'injection_container.config.dart';

/// Dependency injection container for the application
/// Using get_it and injectable for clean dependency management
final GetIt getIt = GetIt.instance;

/// Configure dependency injection
@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Check if dependencies are configured
bool get isDependenciesConfigured => getIt.isRegistered<AuthRepository>();

/// Configure dependencies for test environment
Future<void> configureTestDependencies() async {
  getIt.init(environment: Environment.test);
}

/// Configure dependencies for development environment
Future<void> configureDevelopmentDependencies() async {
  getIt.init(environment: Environment.dev);
}

/// Configure dependencies for production environment
Future<void> configureProductionDependencies() async {
  getIt.init(environment: Environment.prod);
}

/// Configure dependencies with custom environment
Future<void> configureDependenciesWithEnvironment(String environment) async {
  getIt.init(environment: environment);
}

/// Helper to get dependency with type safety
T getDependency<T extends Object>() => getIt<T>();

/// Helper to get dependency with instance name
T getNamedDependency<T extends Object>(String instanceName) =>
    getIt<T>(instanceName: instanceName);

/// Check if a specific dependency is registered
bool isDependencyRegistered<T extends Object>() => getIt.isRegistered<T>();

/// Unregister a specific dependency
Future<void> unregisterDependency<T extends Object>() async {
  if (getIt.isRegistered<T>()) {
    await getIt.unregister<T>();
  }
}

/// Get all registered dependencies (for debugging)
List<String> get registeredDependencies {
  return [
    'AuthRepository',
    'StorageService',
    'FilePickerService',
    'AttachmentService',
    'SupabaseAuthDataSource',
    'AuthBloc',
    'SupabaseClient',
  ];
}
