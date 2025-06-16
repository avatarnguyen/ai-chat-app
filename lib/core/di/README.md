# Dependency Injection System

This directory contains the dependency injection setup for the AI Chat App using `get_it` and `injectable` packages for clean, maintainable, and testable dependency management.

## Overview

The dependency injection system has been refactored from a manual singleton pattern to use industry-standard packages:

- **get_it**: Service locator for dependency management
- **injectable**: Code generation for automatic dependency registration

## Architecture

### Core Components

1. **injection_container.dart**: Main DI configuration and helper functions
2. **injection_container.config.dart**: Auto-generated registration code
3. **bloc_providers.dart**: Flutter BLoC integration helpers
4. **modules/**: Organized dependency modules

### Directory Structure

```
lib/core/di/
├── injection_container.dart          # Main DI setup
├── injection_container.config.dart   # Generated config (do not edit)
├── bloc_providers.dart               # BLoC integration
├── modules/
│   └── core_module.dart              # Core services module
└── README.md                         # This file
```

## Usage

### Basic Setup

#### 1. Initialize Dependencies

```dart
import 'package:ai_chat_app/core/di/injection_container.dart';

void main() async {
  // Initialize dependency injection
  await configureDependencies();
  
  // Run app
  runApp(MyApp());
}
```

#### 2. Using Dependencies in Widgets

```dart
import 'package:ai_chat_app/core/di/bloc_providers.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: BlocProviders.providers,
      child: MaterialApp(
        // App configuration
      ),
    );
  }
}
```

#### 3. Accessing Dependencies

```dart
// Using get_it directly
final authRepository = getDependency<AuthRepository>();

// Using context extension
final authRepository = context.getDependency<AuthRepository>();

// Using mixin
class MyWidget extends StatelessWidget with DependencyInjectionMixin {
  @override
  Widget build(BuildContext context) {
    final authRepo = authRepository; // From mixin
    return Container();
  }
}
```

## Registration Types

### Singleton
Dependencies registered as singletons (same instance every time):
- `SupabaseClient`
- `StorageService`
- `FilePickerService`
- `AttachmentService`
- `SupabaseAuthDataSource`

### Lazy Singleton
Dependencies created only when first accessed:
- `AuthRepository`

### Factory
New instance created every time:
- `AuthBloc`

## Environment Support

The system supports different configurations for different environments:

### Development Environment
```dart
await configureDevelopmentDependencies();
```

### Test Environment
```dart
await configureTestDependencies();
```

### Production Environment
```dart
await configureProductionDependencies();
```

### Custom Environment
```dart
await configureDependenciesWithEnvironment('staging');
```

## Adding New Dependencies

### 1. Create Injectable Class

```dart
import 'package:injectable/injectable.dart';

@singleton
class MyService {
  const MyService(this._dependency);
  
  final SomeDependency _dependency;
  
  // Service implementation
}
```

### 2. Update Module (if needed)

```dart
// lib/core/di/modules/my_module.dart
@module
abstract class MyModule {
  @singleton
  MyComplexService myComplexService(
    Dependency1 dep1,
    Dependency2 dep2,
  ) => MyComplexService(dep1, dep2);
}
```

### 3. Regenerate Configuration

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Add to BlocProviders (if it's a BLoC)

```dart
// lib/core/di/bloc_providers.dart
static List<BlocProvider> get providers => [
  BlocProvider<AuthBloc>(create: (_) => GetIt.instance<AuthBloc>()),
  BlocProvider<MyBloc>(create: (_) => GetIt.instance<MyBloc>()), // Add here
];
```

## Testing

### Unit Testing with Mocks

```dart
import 'package:get_it/get_it.dart';

void main() {
  late GetIt getIt;
  
  setUp(() {
    getIt = GetIt.instance;
    
    // Register mocks
    getIt.registerSingleton<AuthRepository>(MockAuthRepository());
    getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  });
  
  tearDown(() async {
    await getIt.reset();
  });
  
  // Tests...
}
```

### Integration Testing

```dart
void main() {
  setUp(() async {
    // Use test environment
    await configureTestDependencies();
  });
  
  tearDown(() async {
    await resetDependencies();
  });
  
  // Tests...
}
```

## Helper Functions

### Dependency Access
- `getDependency<T>()`: Get dependency by type
- `getNamedDependency<T>(name)`: Get named dependency
- `isDependencyRegistered<T>()`: Check if dependency is registered

### Lifecycle Management
- `configureDependencies()`: Initialize all dependencies
- `resetDependencies()`: Reset all dependencies
- `unregisterDependency<T>()`: Unregister specific dependency

### Extensions and Mixins
- `DependencyInjectionExtension`: Context extension for easy access
- `DependencyInjectionMixin`: Mixin for widget classes

## Migration from Previous System

The previous manual dependency injection system has been replaced:

### Before
```dart
// Old way
import 'package:ai_chat_app/core/di/injection_container.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authRepo = di.authRepository; // Manual singleton
    return Container();
  }
}
```

### After
```dart
// New way
import 'package:ai_chat_app/core/di/injection_container.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authRepo = getDependency<AuthRepository>(); // Type-safe DI
    return Container();
  }
}
```

## Benefits

### Type Safety
- Compile-time dependency resolution
- No runtime string-based lookups
- Better IDE support and refactoring

### Maintainability
- Centralized dependency configuration
- Automatic registration through code generation
- Clear separation of concerns

### Testability
- Easy mocking and stubbing
- Environment-specific configurations
- Isolated testing support

### Performance
- Lazy initialization where appropriate
- Efficient singleton management
- Minimal runtime overhead

## Best Practices

1. **Use appropriate registration types**: Singleton for stateless services, Factory for stateful components
2. **Organize by modules**: Group related dependencies in separate modules
3. **Prefer constructor injection**: Use constructor parameters for dependencies
4. **Avoid service locator anti-pattern**: Don't call `getDependency` in business logic
5. **Use interfaces**: Register interfaces, implement with concrete classes
6. **Test with mocks**: Always provide mock implementations for testing

## Troubleshooting

### Common Issues

#### 1. Dependency Not Found
```
Error: Object/factory with type X is not registered
```
**Solution**: Ensure the dependency is registered and code generation is run.

#### 2. Circular Dependencies
```
Error: Circular dependency detected
```
**Solution**: Refactor dependencies to break the circular reference.

#### 3. Build Runner Issues
```
Error: Could not find a file named "pubspec.yaml"
```
**Solution**: Run build commands from project root directory.

### Debug Commands

```bash
# Clean and regenerate
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Check analysis
flutter analyze

# Run tests
flutter test
```

## Future Improvements

- [ ] Add environment-specific service implementations
- [ ] Implement dependency validation
- [ ] Add performance monitoring for dependency resolution
- [ ] Create development tools for dependency visualization
- [ ] Add automatic dependency documentation generation