import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

enum AppLanguage { english, sinhala, tamil }

class WelcomeEntryScreen extends StatefulWidget {
  const WelcomeEntryScreen({super.key});

  @override
  State<WelcomeEntryScreen> createState() => _WelcomeEntryScreenState();
}

class _WelcomeEntryScreenState extends State<WelcomeEntryScreen> {
  AppLanguage _selectedLanguage = AppLanguage.english;

  // ── Localised strings ──────────────────────────────────────────────────────
  String get _subtitle {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'රජයේ රෝහල් OPD පෝලිම් සහ හමුවීම් පද්ධතිය';
      case AppLanguage.tamil:
        return 'அரசு மருத்துவமனை OPD வரிசை & சந்திப்பு அமைப்பு';
      case AppLanguage.english:
        return 'Government Hospital OPD Queue & Appointment System';
    }
  }

  String get _feat1Title {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'රාජ්‍ය ගොඩනැගිලිවල රැඳී සිටීමට අවශ්‍ය නැත';
      case AppLanguage.tamil:
        return 'வரிசையில் காத்திருக்க வேண்டாம்';
      case AppLanguage.english:
        return 'No Need to Wait in Corridors';
    }
  }

  String get _feat1Sub {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'ඕනෑම තැනින් ඔබේ ටෝකන් ස්ථානය නරඹන්න';
      case AppLanguage.tamil:
        return 'எங்கிருந்தும் உங்கள் டோக்கன் நிலையை கண்காணிக்கவும்';
      case AppLanguage.english:
        return 'Track your live token position from anywhere';
    }
  }

  String get _feat2Title {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'ඔබේ වාරය මඟ හැරෙන්නේ නැත';
      case AppLanguage.tamil:
        return 'உங்கள் முறையை தவறவிடாதீர்கள்';
      case AppLanguage.english:
        return 'Never Miss Your Turn';
    }
  }

  String get _feat2Sub {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'ඔබේ ටෝකන් ඇමතූ විට පූර්ණ තිරය ඇඟවීම්';
      case AppLanguage.tamil:
        return 'உங்கள் டோக்கன் அழைக்கப்படும்போது முழு திரை அறிவிப்பு';
      case AppLanguage.english:
        return 'Full-screen loud alerts when your token is called';
    }
  }

  String get _feat3Title {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'වැඩිහිටියන් හා රැකබලාගන්නන්ට සුදුසු';
      case AppLanguage.tamil:
        return 'பராமரிப்பாளர் மற்றும் மூத்தோர் நட்பு';
      case AppLanguage.english:
        return 'Caregiver & Senior Friendly';
    }
  }

  String get _feat3Sub {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'පවුලේ සාමාජිකයන්ට දුරස්ථව නිරීක්ෂණය කළ හැකිය';
      case AppLanguage.tamil:
        return 'குடும்ப உறுப்பினர்கள் தொலைவில் இருந்து கண்காணிக்கலாம்';
      case AppLanguage.english:
        return 'Family members can monitor queue progress remotely';
    }
  }

  String get _signInLabel {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'රෝගී / රැකබලාගන්නා පිවිසීම';
      case AppLanguage.tamil:
        return 'நோயாளி / பராமரிப்பாளர் உள்நுழைவு';
      case AppLanguage.english:
        return 'Patient / Caregiver Sign In';
    }
  }

  String get _registerLabel {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'නව රෝගියෙකු ලියාපදිංචි කරන්න';
      case AppLanguage.tamil:
        return 'புதிய நோயாளியை பதிவு செய்யவும்';
      case AppLanguage.english:
        return 'Register New Patient';
    }
  }

  String get _staffLabel {
    switch (_selectedLanguage) {
      case AppLanguage.sinhala:
        return 'වෛද්‍ය / රෝහල් කාර්ය මණ්ඩල ද්වාරය';
      case AppLanguage.tamil:
        return 'மருத்துவர் / மருத்துவமனை ஊழியர் போர்டல்';
      case AppLanguage.english:
        return 'Doctor / Hospital Staff Portal';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Language Selector ─────────────────────────────────────────
              _buildLanguageSelector(),

              const SizedBox(height: 20),

              // ── Logo ──────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                'MediQ',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // ── Feature pills ─────────────────────────────────────────────
              _buildFeaturePill(
                icon: Icons.access_time_rounded,
                title: _feat1Title,
                subtitle: _feat1Sub,
              ),
              const SizedBox(height: 12),
              _buildFeaturePill(
                icon: Icons.notifications_active_rounded,
                title: _feat2Title,
                subtitle: _feat2Sub,
              ),
              const SizedBox(height: 12),
              _buildFeaturePill(
                icon: Icons.elderly_rounded,
                title: _feat3Title,
                subtitle: _feat3Sub,
              ),

              const SizedBox(height: 28),

              // ── Sign In button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(isStaffMode: false),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _signInLabel,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Register button ───────────────────────────────────────────
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _registerLabel,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Staff portal ──────────────────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(isStaffMode: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.textSecondary),
                  label: Text(
                    _staffLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language selector widget ───────────────────────────────────────────────
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildLangButton(AppLanguage.english, 'English'),
          _buildLangButton(AppLanguage.sinhala, 'සිංහල'),
          _buildLangButton(AppLanguage.tamil, 'தமிழ்'),
        ],
      ),
    );
  }

  Widget _buildLangButton(AppLanguage lang, String label) {
    final isSelected = _selectedLanguage == lang;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLanguage = lang),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Feature pill widget ───────────────────────────────────────────────────
  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
