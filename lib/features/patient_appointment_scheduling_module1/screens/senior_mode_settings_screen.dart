import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/services/voice_guidance_service.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Accessibility & Senior Mode',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Senior & Accessibility options apply instantly across the whole application',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Toggle 1: Large Text Mode
                _buildToggleCard(
                  title: 'Large Text Mode',
                  subtitle: 'Enlarges all labels, tokens & hospital text',
                  icon: Icons.text_fields_outlined,
                  isActive: _largeTextMode,
                  onChanged: (val) => _updateSetting(largeText: val),
                ),
                const SizedBox(height: 12),

                // 3. Toggle 2: High Contrast Mode
                _buildToggleCard(
                  title: 'High Contrast Mode',
                  subtitle: 'High contrast theme with soft dark slate & clear labels',
                  icon: Icons.contrast_outlined,
                  isActive: _highContrastMode,
                  onChanged: (val) => _updateSetting(highContrast: val),
                ),
                const SizedBox(height: 12),

                // 4. Toggle 3: Simplified Navigation
                _buildToggleCard(
                  title: 'Simplified Navigation',
                  subtitle: 'Converts bottom navigation into 3 large senior buttons',
                  icon: Icons.grid_view_outlined,
                  isActive: _simplifiedNav,
                  onChanged: (val) => _updateSetting(simplified: val),
                ),
                const SizedBox(height: 12),

                // 5. Toggle 4: Voice Guidance
                _buildToggleCard(
                  title: 'Voice Guidance',
                  subtitle: 'Announces booked tokens & directions aloud with speech',
                  icon: Icons.volume_up_outlined,
                  isActive: _voiceGuidance,
                  onChanged: (val) => _updateSetting(voice: val),
                ),
                const SizedBox(height: 20),

                // 6. Live Preview Comparison Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                          color: AppColors.textSecondary,
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
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
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
                                      color: AppColors.textPrimary,
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
                                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _largeTextMode
                                      ? AppColors.primary
                                      : AppColors.border,
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
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
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
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.borderActive : AppColors.border,
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
                  ? AppColors.primaryLight
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
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
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}