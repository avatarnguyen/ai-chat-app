import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Bloc providers helper for get_it integration
/// Provides easy access to BlocProvider widgets using dependency injection
class BlocProviders {
  /// Get list of all bloc providers for MultiBlocProvider
  static List<BlocProvider> get providers => [
    // Auth bloc provider
    BlocProvider<AuthBloc>(create: (_) => GetIt.instance<AuthBloc>()),
  ];

  /// Get list of repository providers for MultiRepositoryProvider
  static List<RepositoryProvider> get repositoryProviders => [
    // Auth repository provider
    RepositoryProvider<AuthRepository>(
      create: (_) => GetIt.instance<AuthRepository>(),
    ),
  ];

  /// Create a specific bloc provider
  static BlocProvider<T> create<T extends BlocBase<Object?>>() {
    return BlocProvider<T>(create: (_) => GetIt.instance<T>());
  }

  /// Create a specific repository provider
  static RepositoryProvider<T> createRepository<T extends Object>() {
    return RepositoryProvider<T>(create: (_) => GetIt.instance<T>());
  }

  /// Create auth bloc provider
  static BlocProvider<AuthBloc> authBlocProvider() {
    return BlocProvider<AuthBloc>(create: (_) => GetIt.instance<AuthBloc>());
  }

  /// Create auth repository provider
  static RepositoryProvider<AuthRepository> authRepositoryProvider() {
    return RepositoryProvider<AuthRepository>(
      create: (_) => GetIt.instance<AuthRepository>(),
    );
  }
}

/// Extension to easily access dependencies from BuildContext
extension DependencyInjectionExtension on BuildContext {
  /// Get dependency from get_it
  T getDependency<T extends Object>() => GetIt.instance<T>();

  /// Get dependency from get_it with optional instance name
  T getNamedDependency<T extends Object>(String instanceName) =>
      GetIt.instance<T>(instanceName: instanceName);

  /// Check if dependency is registered
  bool isDependencyRegistered<T extends Object>() =>
      GetIt.instance.isRegistered<T>();
}

/// Mixin for widgets that need easy access to dependencies
mixin DependencyInjectionMixin {
  /// Get dependency from get_it
  T getDependency<T extends Object>() => GetIt.instance<T>();

  /// Get dependency from get_it with optional instance name
  T getNamedDependency<T extends Object>(String instanceName) =>
      GetIt.instance<T>(instanceName: instanceName);

  /// Get auth repository
  AuthRepository get authRepository => getDependency<AuthRepository>();

  /// Create new auth bloc instance
  AuthBloc createAuthBloc() => getDependency<AuthBloc>();
}
