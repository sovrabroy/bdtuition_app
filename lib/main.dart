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
import 'services/activity_service.dart';
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

class BDTuitionApp extends StatefulWidget {
  const BDTuitionApp({super.key});

  @override
  State<BDTuitionApp> createState() => _BDTuitionAppState();
}

class _BDTuitionAppState extends State<BDTuitionApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observe app foreground/background transitions so we can measure how long
    // the teacher actually keeps the app open (admin "Teacher Activity" page).
    WidgetsBinding.instance.addObserver(this);
    // First frame is up → try to open a session and report a one-time install.
    // Both are no-ops until the teacher is logged in, and both are silent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActivityService.instance.reportInstallOnce();
      ActivityService.instance.startSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Came to the foreground: (re)open a session. If one is already open
        // this is a no-op. Also catch an install that couldn't be reported at
        // launch (e.g. the teacher logged in during this run).
        ActivityService.instance.reportInstallOnce();
        ActivityService.instance.startSession();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Went to the background or is being torn down: close the session and
        // report its duration.
        ActivityService.instance.endSession();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

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
