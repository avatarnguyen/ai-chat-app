import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Extension methods for easier navigation throughout the app
extension NavigationExtensions on BuildContext {
  // Basic navigation
  void goHome() => go(AppRoutes.home);
  void goToAuth() => go(AppRoutes.auth);
  void goToChats() => go(AppRoutes.chatList);
  void goToFolders() => go(AppRoutes.folders);
  void goToSettings() => go(AppRoutes.settings);

  // Chat navigation
  void goToChat(String chatId) => pushNamed(
        AppRoutes.chatDetailName,
        pathParameters: {'chatId': chatId},
      );

  void goToNewChat() => pushNamed(AppRoutes.newChatName);

  // Folder navigation
  void goToFolder(String folderId) => pushNamed(
        AppRoutes.folderDetailName,
        pathParameters: {'folderId': folderId},
      );

  // Settings navigation
  void goToProfile() => pushNamed(AppRoutes.profileName);
  void goToApiKeys() => pushNamed(AppRoutes.apiKeysName);
  void goToUsage() => pushNamed(AppRoutes.usageName);
  void goToModelSettings() => pushNamed(AppRoutes.modelSettingsName);
  void goToThemeSettings() => pushNamed(AppRoutes.themeName);

  // Utility methods
  bool get canPop => GoRouter.of(this).canPop();
  
  void popUntilHome() {
    while (canPop) {
      pop();
    }
    goHome();
  }

  String get currentLocation => GoRouterState.of(this).matchedLocation;
  
  bool get isOnHomePage => currentLocation == AppRoutes.home;
  bool get isOnAuthPage => currentLocation == AppRoutes.auth;
  bool get isOnChatsPage => currentLocation.startsWith(AppRoutes.chatList);
  bool get isOnFoldersPage => currentLocation.startsWith(AppRoutes.folders);
  bool get isOnSettingsPage => currentLocation.startsWith(AppRoutes.settings);
}