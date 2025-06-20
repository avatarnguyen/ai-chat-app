import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_app/l10n/l10n.dart';
import 'core/di/bloc_providers.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/auth/presentation/pages/auth_ui_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/domain/entities/user.dart';

// Define color variables
final Color pinkColor = const Color(0xFFDA79E5);
final Color purpleColor = const Color(0xFF6139F7);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: BlocProviders.repositoryProviders,
      child: MultiBlocProvider(
        providers: BlocProviders.providers,
        child: MaterialApp(
          title: 'AI Chat App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: purpleColor),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: purpleColor,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: purpleColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: purpleColor.withAlpha(200),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade900,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.grey.shade900,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          themeMode: ThemeMode.system,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthWrapper(authenticatedBuilder: _buildHomePage),
          routes: {
            AuthUIPage.routeName: (context) => const AuthUIPage(),
            HomePage.routeName: (context) => const HomePage(),
          },
          builder: (context, child) {
            return Banner(
              message: 'Codika',
              location: BannerLocation.topEnd,
              color: pinkColor,
              shadow: BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }

  /// Builder for authenticated home page
  static Widget _buildHomePage(BuildContext context, User user) {
    return const HomePage();
  }
}
