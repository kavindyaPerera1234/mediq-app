import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_accessibility.dart';
import 'features/auth_live_queue_module3/screens/auth/splash_screen.dart';
import 'core/localization/app_language.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
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

  runApp(const MediQApp());
}

class MediQApp extends StatelessWidget {
  const MediQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isLargeTextMode,
        AppAccessibility.isHighContrastMode,
        AppAccessibility.isSimplifiedNav,
        AppAccessibility.isVoiceGuidance,
        AppLanguage.currentLanguage,
      ]),
      builder: (context, _) {
        final isLargeText = AppAccessibility.isLargeTextMode.value;
        final isHighContrast = AppAccessibility.isHighContrastMode.value;

        return MaterialApp(
          title: 'MediQ - OPD Queue Management',
          debugShowCheckedModeBanner: false,
          // Eliminates theme transition lerp crashes completely
          themeAnimationDuration: Duration.zero,
          theme: isHighContrast ? _buildHighContrastTheme() : _buildStandardTheme(),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                // 1.22x provides genuine senior readability without layout overflow
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
    // Soothing, eye-friendly high contrast dark slate theme (NO harsh neon orange)
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF38BDF8),
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        secondary: Color(0xFF818CF8),
        surface: Color(0xFF1E293B),
        onPrimary: Colors.black,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}