import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tuition_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/demo_provider.dart';
import 'providers/guardian_provider.dart';
import 'services/push_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push notifications (Feature 5 offline half). Wrapped so a Firebase misconfig
  // can never stop the app from launching.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushService.instance.init();
  } catch (e) {
    debugPrint('Firebase/push init skipped: $e');
  }
  runApp(const BDTuitionApp());
}

class BDTuitionApp extends StatelessWidget {
  const BDTuitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TuitionProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => DemoProvider()),
        ChangeNotifierProvider(create: (_) => GuardianProvider()),
      ],
      child: MaterialApp(
        title: 'BDTuition',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
