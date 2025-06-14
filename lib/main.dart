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

  // Add your initialization code here

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
              const Text(
                "An Error Was Encountered",
              ),
              const SizedBox(height: 32),
              Text(
                details.exception.toString(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}