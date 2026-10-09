import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../../../core/services/voice_guidance_service.dart';
import '../backend/backend.dart';

class SeniorModeSettingsScreen extends StatefulWidget {
  const SeniorModeSettingsScreen({super.key});

  @override
  State<SeniorModeSettingsScreen> createState() => _SeniorModeSettingsScreenState();
}

class _SeniorModeSettingsScreenState extends State<SeniorModeSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  String get _patientNic => ProfileService.activeProfileNotifier.value.nic;

  Future<void> _updateSetting({
    bool? largeText,
    bool? highContrast,
    bool? simplified,
    bool? voice,
  }) async {
    if (largeText != null) {
      AppAccessibility.setLargeTextMode(largeText);
    }
    if (highContrast != null) {
      AppAccessibility.setHighContrastMode(highContrast);
    }
    if (simplified != null) {
      AppAccessibility.setSimplifiedNav(simplified);
    }
    if (voice != null) {
      AppAccessibility.setVoiceGuidance(voice);
      if (voice) {
        VoiceGuidanceService.speak(
          AppAccessibility.currentLanguage.value == 'si'
              ? "හඬ මඟපෙන්වීම සක්‍රිය කරන ලදී"
              : "Voice Guidance is activated. OPD tokens and screen navigation will be announced aloud.",
          context: context,
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voice Guidance disabled."),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    }

    await _profileService.saveAccessibilitySettings(
      patientNic: _patientNic,
      largeTextMode: AppAccessibility.isLargeTextMode.value,
      highContrastMode: AppAccessibility.isHighContrastMode.value,
      simplifiedNav: AppAccessibility.isSimplifiedNav.value,
      voiceGuidance: AppAccessibility.isVoiceGuidance.value,
    );
  }

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
        final isDark = AppAccessibility.isHighContrastMode.value;
        final isLargeText = AppAccessibility.isLargeTextMode.value;
        final isSimplified = AppAccessibility.isSimplifiedNav.value;
        final isVoice = AppAccessibility.isVoiceGuidance.value;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B132B) : AppColors.background,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('accessibility'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      AppTranslations.tr('accessibility'),
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
                    const SizedBox(height: 18),

                    // 2. Trilingual Language Selector Card
                    _buildLanguageSelector(isDark),
                    const SizedBox(height: 16),

                    // 3. Toggle 1: Large Text Mode
                    _buildToggleCard(
                      title: AppTranslations.tr('largeText'),
                      subtitle: AppTranslations.tr('largeTextDesc'),
                      icon: Icons.text_fields_outlined,
                      isActive: isLargeText,
                      onChanged: (val) => _updateSetting(largeText: val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // 4. Toggle 2: High Contrast Mode
                    _buildToggleCard(
                      title: AppTranslations.tr('highContrast'),
                      subtitle: AppTranslations.tr('highContrastDesc'),
                      icon: Icons.contrast_outlined,
                      isActive: isDark,
                      onChanged: (val) => _updateSetting(highContrast: val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // 5. Toggle 3: Simplified Navigation
                    _buildToggleCard(
                      title: AppTranslations.tr('simplifiedNav'),
                      subtitle: AppTranslations.tr('simplifiedNavDesc'),
                      icon: Icons.grid_view_outlined,
                      isActive: isSimplified,
                      onChanged: (val) => _updateSetting(simplified: val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // 6. Toggle 4: Voice Guidance
                    _buildToggleCard(
                      title: AppTranslations.tr('voiceGuidance'),
                      subtitle: AppTranslations.tr('voiceGuidanceDesc'),
                      icon: Icons.volume_up_outlined,
                      isActive: isVoice,
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
                                color: isLargeText
                                    ? (isDark ? const Color(0xFF243356) : AppColors.primaryLight.withValues(alpha: 0.5))
                                    : (isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isLargeText
                                      ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                                      : (isDark ? const Color(0xFF3A506B) : AppColors.border),
                                  width: isLargeText ? 1.5 : 1,
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
                                      color: isLargeText
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
                                      color: isLargeText
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
                const SizedBox(height: 16),

                // 7. Interactive Voice Guidance Audio Tester
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2541) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isVoice ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary) : (isDark ? const Color(0xFF3A506B) : AppColors.border),
                      width: isVoice ? 1.5 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 20, color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'VOICE GUIDANCE LIVE DEMO',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap buttons below to test real-time speech synthesis for elderly patients & visually impaired:',
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.volume_up_rounded, size: 16),
                            label: const Text('🔊 Call Token A-024', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              VoiceGuidanceService.speak(
                                'Token Number A-024, please proceed to OPD Room 01 for consultation.',
                                context: context,
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : AppColors.textDark,
                              side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.record_voice_over_outlined, size: 16),
                            label: const Text('🔊 සිංහල නිවේදනය', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              VoiceGuidanceService.speak(
                                'ටෝකන් අංක ඒ බිංදුවයි විසි හතර, කරුණාකර අංක එක කාමරයට පැමිණෙන්න.',
                                context: context,
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : AppColors.textDark,
                              side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.record_voice_over_outlined, size: 16),
                            label: const Text('🔊 தமிழ் அறிவிப்பு', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              VoiceGuidanceService.speak(
                                'டோக்கன் எண் ஏ இருபத்தி நான்கு, தயவுசெய்து அறை ஒன்றுக்கு செல்லவும்.',
                                context: context,
                              );
                            },
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
  },
);
  }

  Widget _buildLanguageSelector(bool isDark) {
    final currentLang = AppAccessibility.currentLanguage.value;
    final options = [
      {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'label': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'label': 'தமிழ்', 'flag': '🇱🇰'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryLight,
          width: 1.5,
        ),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF243356) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.tr('language'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppTranslations.tr('selectLanguage'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final isSelected = currentLang == opt['code'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      AppAccessibility.setLanguage(opt['code']!);
                      if (opt['code'] == 'si') {
                        VoiceGuidanceService.speak('භාෂාව සිංහල ලෙස වෙනස් කරන ලදී', context: context);
                      } else if (opt['code'] == 'ta') {
                        VoiceGuidanceService.speak('மொழி தமிழில் மாற்றப்பட்டது', context: context);
                      } else {
                        VoiceGuidanceService.speak('Language switched to English', context: context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                            : (isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                              : (isDark ? const Color(0xFF3A506B) : AppColors.border),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt['flag']!,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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