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
    return ValueListenableBuilder<bool>(
      valueListenable: AppAccessibility.isLargeTextMode,
      builder: (context, isLargeText, _) {
        return MaterialApp(
          title: 'MediQ - OPD Queue Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            textTheme: GoogleFonts.interTextTheme(
              Theme.of(context).textTheme,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: isLargeText
                    ? const TextScaler.linear(1.18)
                    : const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          home: const PatientMainScreen(),
        );
      },
    );
  }
}