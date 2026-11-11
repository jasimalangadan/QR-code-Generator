import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/qr_provider.dart';
import 'repositories/qr_repository.dart';
import 'ui/screens/preview_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';

void main() async {
  // Ensure Flutter framework binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inject Firebase repository in production mode
  final QrRepository qrRepository = FirebaseQrRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QrProvider(repository: qrRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _getInitialScreen() {
    try {
      final uri = Uri.base;
      final fullUrl = uri.toString();
      final hasScanOrPreview = uri.path.contains('/scan') ||
          uri.path.contains('/preview') ||
          (uri.hasFragment &&
              (uri.fragment.contains('/scan') ||
                  uri.fragment.contains('/preview')));
      final hasId = uri.queryParameters.containsKey('id') ||
          (uri.hasFragment && uri.fragment.contains('id='));
      final hasData = uri.queryParameters.containsKey('data') ||
          (uri.hasFragment && uri.fragment.contains('data='));

      if (hasScanOrPreview || hasId || hasData) {
        return PreviewScreen(scanUrl: fullUrl, isExternalScan: true);
      }
    } catch (_) {
      // Fallback in case of unexpected environment issues
    }
    return const SplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Us Profile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(),
    );
  }
}
