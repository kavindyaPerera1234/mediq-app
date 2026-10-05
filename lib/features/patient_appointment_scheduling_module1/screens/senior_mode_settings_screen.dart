import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/services/voice_guidance_service.dart';
import '../../../core/localization/app_language.dart';
import '../backend/backend.dart';

class SeniorModeSettingsScreen extends StatefulWidget {
  const SeniorModeSettingsScreen({super.key});

  @override
  State<SeniorModeSettingsScreen> createState() => _SeniorModeSettingsScreenState();
}

class _SeniorModeSettingsScreenState extends State<SeniorModeSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final String _patientNic = '200164801234';

  bool _largeTextMode = true;
  bool _highContrastMode = false;
  bool _simplifiedNav = false;
  bool _voiceGuidance = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _profileService.getAccessibilitySettings(_patientNic);
    if (mounted) {
      setState(() {
        _largeTextMode = settings['largeTextMode'] ?? true;
        _highContrastMode = settings['highContrastMode'] ?? false;
        _simplifiedNav = settings['simplifiedNav'] ?? false;
        _voiceGuidance = settings['voiceGuidance'] ?? false;
      });
      AppAccessibility.setLargeTextMode(_largeTextMode);
      AppAccessibility.setHighContrastMode(_highContrastMode);
      AppAccessibility.setSimplifiedNav(_simplifiedNav);
      AppAccessibility.setVoiceGuidance(_voiceGuidance);
    }
  }

  Future<void> _updateSetting({
    bool? largeText,
    bool? highContrast,
    bool? simplified,
    bool? voice,
  }) async {
    setState(() {
      if (largeText != null) {
        _largeTextMode = largeText;
        AppAccessibility.setLargeTextMode(largeText);
      }
      if (highContrast != null) {
        _highContrastMode = highContrast;
        AppAccessibility.setHighContrastMode(highContrast);
      }
      if (simplified != null) {
        _simplifiedNav = simplified;
        AppAccessibility.setSimplifiedNav(simplified);
      }
      if (voice != null) {
        _voiceGuidance = voice;
        AppAccessibility.setVoiceGuidance(voice);
      }
    });

    if (voice == true) {
      VoiceGuidanceService.speak(
        "Voice Guidance is activated. OPD tokens and screen navigation will be announced aloud.",
        context: context,
      );
    } else if (voice == false) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice Guidance disabled."),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }

    await _profileService.saveAccessibilitySettings(
      patientNic: _patientNic,
      largeTextMode: _largeTextMode,
      highContrastMode: _highContrastMode,
      simplifiedNav: _simplifiedNav,
      voiceGuidance: _voiceGuidance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _highContrastMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Accessibility & Senior Mode',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1C2541) : AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: isDark ? 1 : 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Title & Subtitle
                Text(
                  'Accessibility Settings',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Senior & Accessibility options apply instantly across the whole application',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Language Selector Card (English, Simple Sinhala, Tamil)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2541) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF3A506B) : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded, color: isDark ? const Color(0xFF38BDF8) : AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            AppLanguage.isSinhala ? 'භාෂාව තෝරන්න' : (AppLanguage.isTamil ? 'மொழியை தேர்வு செய்' : 'Select Language'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => AppLanguage.setEnglish());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppLanguage.isEnglish ? AppColors.primary : (isDark ? const Color(0xFF243356) : AppColors.surface),
                                foregroundColor: AppLanguage.isEnglish ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                                elevation: AppLanguage.isEnglish ? 2 : 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => AppLanguage.setSinhala());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppLanguage.isSinhala ? AppColors.primary : (isDark ? const Color(0xFF243356) : AppColors.surface),
                                foregroundColor: AppLanguage.isSinhala ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                                elevation: AppLanguage.isSinhala ? 2 : 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('සිංහල', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => AppLanguage.setTamil());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppLanguage.isTamil ? AppColors.primary : (isDark ? const Color(0xFF243356) : AppColors.surface),
                                foregroundColor: AppLanguage.isTamil ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                                elevation: AppLanguage.isTamil ? 2 : 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('தமிழ்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Toggle 1: Large Text Mode
                _buildToggleCard(
                  title: 'Large Text Mode',
                  subtitle: 'Enlarges all labels, tokens & hospital text',
                  icon: Icons.text_fields_outlined,
                  isActive: _largeTextMode,
                  onChanged: (val) => _updateSetting(largeText: val),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Toggle 2: High Contrast Mode
                _buildToggleCard(
                  title: 'High Contrast Mode',
                  subtitle: 'Enhanced contrast with soft dark slate theme',
                  icon: Icons.contrast_outlined,
                  isActive: _highContrastMode,
                  onChanged: (val) => _updateSetting(highContrast: val),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 4. Toggle 3: Simplified Navigation
                _buildToggleCard(
                  title: 'Simplified Navigation',
                  subtitle: 'Converts bottom navigation into 3 large senior buttons',
                  icon: Icons.grid_view_outlined,
                  isActive: _simplifiedNav,
                  onChanged: (val) => _updateSetting(simplified: val),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 5. Toggle 4: Voice Guidance
                _buildToggleCard(
                  title: 'Voice Guidance',
                  subtitle: 'Announces booked tokens & directions aloud with speech',
                  icon: Icons.volume_up_outlined,
                  isActive: _voiceGuidance,
                  onChanged: (val) => _updateSetting(voice: val),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 6. Live Preview Comparison Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2541) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF3A506B) : AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE PREVIEW (SENIOR MODE ADAPTATION)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Standard Size Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF3A506B) : AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'A-024',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Enlarged Size Box (Active Highlight)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _largeTextMode
                                    ? (isDark ? const Color(0xFF243356) : AppColors.primaryLight.withValues(alpha: 0.5))
                                    : (isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _largeTextMode
                                      ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                                      : (isDark ? const Color(0xFF3A506B) : AppColors.border),
                                  width: _largeTextMode ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Senior Mode',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _largeTextMode
                                          ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                                          : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'A-024',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _largeTextMode
                                          ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                                          : (isDark ? Colors.white : AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? (isDark ? const Color(0xFF38BDF8) : AppColors.borderActive)
              : (isDark ? const Color(0xFF3A506B) : AppColors.border),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFF243356) : AppColors.primaryLight)
                  : (isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Custom Pill Toggle Switch
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}