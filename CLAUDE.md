# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Project Requirements are stored in `.taskmaster/docs/`

Use task-master to manage tasks. Tasks are stored in `.taskmaster/tasks`

## Architecture

This is a Flutter app using **Clean Architecture** with feature-driven development. The codebase is organized into:

- `lib/core/` - Shared infrastructure (DI, services, models, config)
- `lib/features/` - Feature modules with data/domain/presentation layers
- Uses **BLoC pattern** for state management with `flutter_bloc`
- **Dependency Injection** via `get_it` + `injectable`
- **Supabase** backend with PostgreSQL database and storage

## Development Commands

### Running the App
```bash
# Development environment
flutter run --flavor dev -t lib/main_dev.dart

# Production environment
flutter run --flavor prod -t lib/main_prod.dart
```

### Code Generation
```bash
# Generate dependency injection and JSON serialization
dart run build_runner build

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### Supabase Local Development
```bash
# Start local Supabase
supabase start

# Reset database with migrations
supabase db reset

# Generate TypeScript types
supabase gen types typescript --local
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for linting issues
flutter analyze

# Format code
dart format .

# Fix auto-fixable lint issues
dart fix --apply
```

## Key Dependencies

- **State Management**: `flutter_bloc` with BLoC pattern
- **DI**: `get_it` + `injectable` (use `@injectable` annotations)
- **Backend**: `supabase_flutter` with auth, database, storage
- **Navigation**: `go_router` for declarative routing
- **Local Storage**: `hive_ce` for caching and offline data

## Authentication System

The app has comprehensive auth with:
- Email/password, Google OAuth, Apple Sign-In
- `AuthBloc` handles 15+ auth events (sign up/in/out, profile updates)
- User profiles with preferences, subscription tiers, usage tracking
- All auth logic in `lib/features/auth/`

## Database Schema

Supabase PostgreSQL with:
- `user_profiles`, `conversations`, `messages`, `folders`, `api_keys`
- Row Level Security (RLS) enabled on all tables
- Full-text search on messages
- Encrypted API key storage with pgcrypto

## File Storage

Three Supabase storage buckets:
- `chat-attachments` (private) - Message file attachments
- `user-avatars` (public) - Profile pictures
- `conversation-exports` (private) - Exported conversations

File handling services in `lib/core/services/`:
- `AttachmentService` - Upload/download attachments
- `FilePickerService` - File selection interface
- `StorageService` - Direct Supabase storage operations

## Flavors

App supports dev/prod environments:
- Entry points: `main_dev.dart`, `main_prod.dart`
- Flavor config in `flavorizr.yaml`
- Environment-specific Supabase configs in `lib/core/config/`

## Code Patterns

### Adding New Features
1. Create feature directory: `lib/features/feature_name/`
2. Follow Clean Architecture: `data/`, `domain/`, `presentation/`
3. Register dependencies in `lib/core/di/modules/`
4. Use BLoC for state management
5. Add route in navigation configuration

### Dependency Injection
```dart
@injectable
class MyService {
  // Implementation
}

// Register in module
@module
abstract class MyModule {
  @lazySingleton
  MyService get myService => MyService();
}
```

### BLoC Pattern
```dart
@injectable
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyInitialState()) {
    on<MyEvent>(_onMyEvent);
  }
}
```

## Important Files

- `lib/app.dart` - App initialization and routing
- `lib/core/di/injection_container.dart` - DI configuration
- `supabase/migrations/` - Database schema migrations
- `lib/core/config/supabase_config.dart` - Backend configuration
