import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/staff_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Initialization Warning: $e');
  }

  // Pre-load Doctor Silva auth session to bypass login screen by default
  final authService = AuthService();
  await authService.signInDemoRole('doctor');

  runApp(MediQApp(authService: authService));
}

class MediQApp extends StatelessWidget {
  final AuthService? authService;

  const MediQApp({
    super.key,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final activeAuth = authService ?? AuthService();

    return MaterialApp(
      title: 'MediQ — OPD Staff Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StaffDashboardScreen(authService: activeAuth),
    );
  }
}