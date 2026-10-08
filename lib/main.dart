import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_accessibility.dart';
import 'services/auth_service.dart';
import 'services/seed_data_service.dart';
import 'features/auth_live_queue_module3/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully!");

    // Auto-seed initial demo data into Firestore project (mediq-opd)
    SeedDataService().seedDemoData().catchError((e) {
      debugPrint('Firestore Seeding Note: $e');
      return false;
    });
  } catch (e) {
    debugPrint("Firebase initialization notice: $e");
  }

  // Load authenticated user profile
  final authService = AuthService();
  await authService.loadCurrentStaffProfile();

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
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isLargeTextMode,
        AppAccessibility.isHighContrastMode,
        AppAccessibility.isSimplifiedNav,
        AppAccessibility.isVoiceGuidance,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isLargeText = AppAccessibility.isLargeTextMode.value;
        final isHighContrast = AppAccessibility.isHighContrastMode.value;

        return MaterialApp(
          title: 'MediQ - OPD Queue Management',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: isHighContrast ? _buildHighContrastTheme() : _buildStandardTheme(),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: isLargeText
                    ? const TextScaler.linear(1.22)
                    : const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }

  static ThemeData _buildStandardTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      cardColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _buildHighContrastTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.seniorHighContrastBg,
      primaryColor: AppColors.seniorHighContrastAccent,
      cardColor: AppColors.seniorHighContrastSurface,
      dividerColor: AppColors.seniorHighContrastBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.seniorHighContrastSurface,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.seniorHighContrastAccent,
        secondary: Color(0xFF818CF8),
        surface: AppColors.seniorHighContrastSurface,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}