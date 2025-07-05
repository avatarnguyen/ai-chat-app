import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/auth_ui_page.dart';
import 'app_routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticating = state.matchedLocation == AppRoutes.auth;
      
      // If user is not authenticated and not on auth page, redirect to auth
      if (authState is! AuthAuthenticated && !isAuthenticating) {
        return AppRoutes.auth;
      }
      
      // If user is authenticated and on auth page, redirect to home
      if (authState is AuthAuthenticated && isAuthenticating) {
        return AppRoutes.home;
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Auth route (outside shell)
      GoRoute(
        path: AppRoutes.auth,
        name: AppRoutes.authName,
        builder: (context, state) => const AuthUIPage(),
      ),
      
      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.homeName,
            builder: (context, state) => const HomeTabScreen(),
          ),
          
          // Chat routes
          GoRoute(
            path: AppRoutes.chatList,
            name: AppRoutes.chatListName,
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: 'chat/:chatId',
                name: AppRoutes.chatDetailName,
                builder: (context, state) {
                  final chatId = state.pathParameters['chatId']!;
                  return ChatDetailScreen(chatId: chatId);
                },
              ),
              GoRoute(
                path: 'new',
                name: AppRoutes.newChatName,
                builder: (context, state) => const NewChatScreen(),
              ),
            ],
          ),
          
          // Folders tab
          GoRoute(
            path: AppRoutes.folders,
            name: AppRoutes.foldersName,
            builder: (context, state) => const FoldersScreen(),
            routes: [
              GoRoute(
                path: 'folder/:folderId',
                name: AppRoutes.folderDetailName,
                builder: (context, state) {
                  final folderId = state.pathParameters['folderId']!;
                  return FolderDetailScreen(folderId: folderId);
                },
              ),
            ],
          ),
          
          // Settings tab
          GoRoute(
            path: AppRoutes.settings,
            name: AppRoutes.settingsName,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'api-keys',
                name: AppRoutes.apiKeysName,
                builder: (context, state) => const ApiKeysScreen(),
              ),
              GoRoute(
                path: 'usage',
                name: AppRoutes.usageName,
                builder: (context, state) => const UsageScreen(),
              ),
              GoRoute(
                path: 'model-settings',
                name: AppRoutes.modelSettingsName,
                builder: (context, state) => const ModelSettingsScreen(),
              ),
              GoRoute(
                path: 'theme',
                name: AppRoutes.themeName,
                builder: (context, state) => const ThemeSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Main scaffold with bottom navigation
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Folders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.chatList)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.folders)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 3;
    }
    return 0; // Default to Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.chatList);
        break;
      case 2:
        context.go(AppRoutes.folders);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }
}

// Placeholder screens - will be replaced with actual implementations
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Tab - Coming Soon'),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: const Center(
        child: Text('Chat List - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.newChatName),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat $chatId')),
      body: Center(
        child: Text('Chat Detail Screen for ID: $chatId'),
      ),
    );
  }
}

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: const Center(
        child: Text('New Chat Screen - Coming Soon'),
      ),
    );
  }
}

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: const Center(
        child: Text('Folders Screen - Coming Soon'),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final String folderId;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folder $folderId')),
      body: Center(
        child: Text('Folder Detail Screen for ID: $folderId'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings Screen - Coming Soon'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('Profile Screen - Coming Soon'),
      ),
    );
  }
}

class ApiKeysScreen extends StatelessWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Keys')),
      body: const Center(
        child: Text('API Keys Screen - Coming Soon'),
      ),
    );
  }
}

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usage & Billing')),
      body: const Center(
        child: Text('Usage Screen - Coming Soon'),
      ),
    );
  }
}

class ModelSettingsScreen extends StatelessWidget {
  const ModelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Settings')),
      body: const Center(
        child: Text('Model Settings Screen - Coming Soon'),
      ),
    );
  }
}

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: const Center(
        child: Text('Theme Settings Screen - Coming Soon'),
      ),
    );
  }
}