import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_accessibility.dart';
import 'features/patient_appointment_scheduling_module1/screens/patient_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully!");
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
      ]),
      builder: (context, _) {
        final isLargeText = AppAccessibility.isLargeTextMode.value;
        final isHighContrast = AppAccessibility.isHighContrastMode.value;

        return MaterialApp(
          title: 'MediQ - OPD Queue Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: isHighContrast ? const Color(0xFF0F172A) : AppColors.background,
            primaryColor: isHighContrast ? const Color(0xFFF59E0B) : AppColors.primary,
            cardColor: isHighContrast ? const Color(0xFF1E293B) : AppColors.surface,
            textTheme: GoogleFonts.interTextTheme(
              isHighContrast ? ThemeData.dark().textTheme : Theme.of(context).textTheme,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: isHighContrast ? const Color(0xFFF59E0B) : AppColors.primary,
              primary: isHighContrast ? const Color(0xFFF59E0B) : AppColors.primary,
              surface: isHighContrast ? const Color(0xFF1E293B) : AppColors.surface,
              brightness: isHighContrast ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            Widget content = MediaQuery(
              data: mediaQuery.copyWith(
                // 1.35x provides clear, unmistakable accessibility font scaling for seniors (WCAG 2.1 AA)
                textScaler: isLargeText
                    ? const TextScaler.linear(1.35)
                    : const TextScaler.linear(1.0),
              ),
              child: child!,
            );

            if (isHighContrast) {
              // High-contrast color inverter (turns white backgrounds black, dark text white, blue into gold/amber)
              content = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -1.0,  0.0,  0.0, 0.0, 255.0,
                   0.0, -1.0,  0.0, 0.0, 255.0,
                   0.0,  0.0, -1.0, 0.0, 255.0,
                   0.0,  0.0,  0.0, 1.0,   0.0,
                ]),
                child: content,
              );
            }

            return content;
          },
          home: const PatientMainScreen(),
        );
      },
    );
  }
}