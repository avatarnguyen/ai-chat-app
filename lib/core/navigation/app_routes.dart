/// Centralized route definitions for the app
class AppRoutes {
  AppRoutes._();

  // Route paths
  static const String home = '/';
  static const String auth = '/auth';
  static const String chatList = '/chats';
  static const String folders = '/folders';
  static const String settings = '/settings';

  // Route names for programmatic navigation
  static const String homeName = 'home';
  static const String authName = 'auth';
  static const String chatListName = 'chat-list';
  static const String chatDetailName = 'chat-detail';
  static const String newChatName = 'new-chat';
  static const String foldersName = 'folders';
  static const String folderDetailName = 'folder-detail';
  static const String settingsName = 'settings';
  static const String profileName = 'profile';
  static const String apiKeysName = 'api-keys';
  static const String usageName = 'usage';
  static const String modelSettingsName = 'model-settings';
  static const String themeName = 'theme';
}