import 'package:ai_chat_app/core/config/supabase_config.dart';
import 'package:ai_chat_app/core/di/injection_container.dart';
import 'package:ai_chat_app/flavors.dart';
import 'package:flutter/material.dart';
import 'package:ai_chat_app/app.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/services.dart';

Future<void> runMainApp() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
  );

  ErrorWidget.builder = errorBuilderWidget;

  // Initialize environment variables and Supabase
  try {
    // Initialize Supabase with loaded environment variables
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    return;
  }

  // Initialize dependency injection based on environment
  try {
    final flavor = getFlavor();
    final isProd = flavor == Flavor.prod;
    final isDev = flavor == Flavor.dev;

    if (isProd) {
      await configureProductionDependencies();
      debugPrint('✅ Production dependency injection initialized');
    } else if (isDev) {
      await configureDevelopmentDependencies();
      debugPrint('✅ Development dependency injection initialized');
    } else {
      await configureDependencies();
      debugPrint('✅ Default dependency injection initialized');
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize DI: $e');
    runApp(ErrorApp(error: 'Failed to initialize app: $e'));
    return;
  }

  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

Widget errorBuilderWidget(FlutterErrorDetails details) {
  return Material(
    child: Container(
      color: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("An Error Was Encountered"),
              const SizedBox(height: 32),
              Text(details.exception.toString()),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Error app widget for critical initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Initialize App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    runMainApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
