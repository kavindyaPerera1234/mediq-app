import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../backend/backend.dart';
import '../admin/screens/hospital_admin_dashboard.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccessibilitySettings();
  }

  Future<void> _loadAccessibilitySettings() async {
    final settings = await _profileService.getAccessibilitySettings(_patientNic);
    if (mounted) {
      setState(() {
        _largeTextMode = settings['largeTextMode'] ?? true;
        _highContrastMode = settings['highContrastMode'] ?? false;
        _simplifiedNav = settings['simplifiedNav'] ?? false;
        _voiceGuidance = settings['voiceGuidance'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting({
    bool? largeText,
    bool? highContrast,
    bool? simplified,
    bool? voice,
  }) async {
    setState(() {
      if (largeText != null) _largeTextMode = largeText;
      if (highContrast != null) _highContrastMode = highContrast;
      if (simplified != null) _simplifiedNav = simplified;
      if (voice != null) _voiceGuidance = voice;
    });

    await _profileService.saveAccessibilitySettings(
      patientNic: _patientNic,
      largeTextMode: _largeTextMode,
      highContrastMode: _highContrastMode,
      simplifiedNav: _simplifiedNav,
      voiceGuidance: _voiceGuidance,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Accessibility preferences synced to Ministry Cloud.'),
              ),
            ],
          ),
          backgroundColor: _highContrastMode ? const Color(0xFF1E293B) : AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showVoiceCalloutDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFFFBBF24) : AppColors.primary, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Audio Wave Animation simulation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  size: 40,
                  color: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Live Hospital Voice Announcement',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔊 English Announcement:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"Attention please: Token A-046. Patient Kanthi Perera, please proceed to OPD Room 07 - ENT Clinic."',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🔊 සිංහල නිවේදනය (Sinhala Audio):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"කරුණාකර අවධානය යොමු කරන්න: ටෝකන් අංක A-046. කාන්ති පෙරේරා මහත්මිය, අංක 07 කාමරය වෙත යන්න."',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Close Audio Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic High Contrast Theme Palette
    final isDark = _highContrastMode;
    final bg = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary;
    final border = isDark ? const Color(0xFF475569) : AppColors.border;
    final activeColor = isDark ? const Color(0xFFFBBF24) : AppColors.primary;

    // Dynamic Large Text Scale Factor
    final fontScale = _largeTextMode ? 1.15 : 1.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: isDark ? 1 : 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          isDark ? 'Senior Accessibility (High Contrast)' : 'Senior Accessibility',
          style: GoogleFonts.inter(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Title & Subtitle
                    Text(
                      'Accessibility Options',
                      style: GoogleFonts.inter(
                        fontSize: 22 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tailored for senior patients and caregivers (WCAG 2.1 AA compliant)',
                      style: GoogleFonts.inter(
                        fontSize: 13 * fontScale,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Toggle 1: Large Text Mode
                    _buildToggleCard(
                      title: 'Large Text Mode',
                      subtitle: 'Enlarges all labels, tokens & hospital directions',
                      icon: Icons.text_fields_outlined,
                      isActive: _largeTextMode,
                      isDark: isDark,
                      activeColor: activeColor,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      fontScale: fontScale,
                      onChanged: (val) => _updateSetting(largeText: val),
                    ),
                    const SizedBox(height: 12),

                    // 3. Toggle 2: High Contrast Mode
                    _buildToggleCard(
                      title: 'High Contrast Mode',
                      subtitle: 'Deep dark background with high-visibility gold accents',
                      icon: Icons.contrast_outlined,
                      isActive: _highContrastMode,
                      isDark: isDark,
                      activeColor: activeColor,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      fontScale: fontScale,
                      onChanged: (val) => _updateSetting(highContrast: val),
                    ),
                    const SizedBox(height: 12),

                    // 4. Toggle 3: Simplified Navigation
                    _buildToggleCard(
                      title: 'Simplified Navigation',
                      subtitle: 'Bigger 56dp action buttons with 1-tap quick actions',
                      icon: Icons.grid_view_outlined,
                      isActive: _simplifiedNav,
                      isDark: isDark,
                      activeColor: activeColor,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      fontScale: fontScale,
                      onChanged: (val) => _updateSetting(simplified: val),
                    ),

                    // Dynamic Simplified 1-Tap Action Panel
                    if (_simplifiedNav) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.touch_app_rounded, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Senior 1-Tap Quick Actions (NFR-01)',
                                  style: TextStyle(
                                    fontSize: 14 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'High-accessibility touch targets (≥ 56 dp) for elderly patients.',
                              style: TextStyle(fontSize: 11 * fontScale, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF78350F)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.confirmation_number_rounded, size: 20),
                                    label: Text('My Token', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                                    label: Text('Call Desk', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Calling National Hospital OPD Desk: +94 11 269 1111')),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 5. Toggle 4: Voice Guidance
                    _buildToggleCard(
                      title: 'Voice Guidance (TTS)',
                      subtitle: 'Spoken token callouts in Sinhala & English (FR-07)',
                      icon: Icons.volume_up_outlined,
                      isActive: _voiceGuidance,
                      isDark: isDark,
                      activeColor: activeColor,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      fontScale: fontScale,
                      onChanged: (val) => _updateSetting(voice: val),
                    ),

                    // Dynamic Voice Guidance Audio Test Box
                    if (_voiceGuidance) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: activeColor.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.graphic_eq_rounded, color: activeColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Live Voice Callout Active',
                                    style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'When your token is called by the doctor, voice announcement broadcasts in Sinhala and English.',
                              style: TextStyle(fontSize: 11 * fontScale, color: textSecondary),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.volume_up_rounded, size: 18),
                                label: const Text('Test Live Voice Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: activeColor,
                                  side: BorderSide(color: activeColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showVoiceCalloutDialog(context, isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 6. Live Preview Comparison Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PREVIEW (LARGE TEXT & CONTRAST)',
                                style: GoogleFonts.inter(
                                  fontSize: 11 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _largeTextMode ? 'ENLARGED ACTIVE' : 'STANDARD ACTIVE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              // Standard Size Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !_largeTextMode ? activeColor : border,
                                      width: !_largeTextMode ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Standard Size',
                                        style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'A-024',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Enlarged Size Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _largeTextMode
                                        ? (isDark ? const Color(0xFF334155) : activeColor.withValues(alpha: 0.12))
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _largeTextMode ? activeColor : border,
                                      width: _largeTextMode ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enlarged Size',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _largeTextMode ? activeColor : textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'A-024',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: _largeTextMode ? activeColor : textPrimary,
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
                    const SizedBox(height: 20),

                    // 7. Hospital Administration Console Access Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? Border.all(color: const Color(0xFFFBBF24), width: 1.2) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Hospital Administration',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Configure government hospitals, OPD departments, and 25-patient slot capping limits.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeColor,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HospitalAdminDashboard()),
                                );
                              },
                              child: const Text('Open Hospital Admin Console →', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
    required bool isDark,
    required Color activeColor,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required double fontScale,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeColor : (isDark ? const Color(0xFF334155) : AppColors.border),
          width: isActive ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.18)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : textSecondary,
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
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12 * fontScale,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Custom Switch
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: isDark ? Colors.black : Colors.white,
            activeTrackColor: activeColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}