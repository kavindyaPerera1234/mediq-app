import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SeniorModeSettingsScreen extends StatefulWidget {
  const SeniorModeSettingsScreen({super.key});

  @override
  State<SeniorModeSettingsScreen> createState() => _SeniorModeSettingsScreenState();
}

class _SeniorModeSettingsScreenState extends State<SeniorModeSettingsScreen> {
  // Toggle states matching our Figma design
  bool _largeTextMode = true; // Active in Figma!
  bool _highContrastMode = false;
  bool _simplifiedNav = false;
  bool _voiceGuidance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Subtitle
              Text(
                'Accessibility',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Senior & Accessibility Options',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Toggle 1: Large Text Mode (Active State)
              _buildToggleCard(
                title: 'Large Text Mode',
                subtitle: 'Enlarges all labels & numbers',
                icon: Icons.text_fields_outlined,
                isActive: _largeTextMode,
                onChanged: (val) {
                  setState(() {
                    _largeTextMode = val;
                  });
                },
              ),
              const SizedBox(height: 14),

              // 3. Toggle 2: High Contrast Mode
              _buildToggleCard(
                title: 'High Contrast Mode',
                subtitle: 'Crisp black & white elements',
                icon: Icons.contrast_outlined,
                isActive: _highContrastMode,
                onChanged: (val) {
                  setState(() {
                    _highContrastMode = val;
                  });
                },
              ),
              const SizedBox(height: 14),

              // 4. Toggle 3: Simplified Navigation
              _buildToggleCard(
                title: 'Simplified Navigation',
                subtitle: 'Bigger buttons, no complex menus',
                icon: Icons.grid_view_outlined,
                isActive: _simplifiedNav,
                onChanged: (val) {
                  setState(() {
                    _simplifiedNav = val;
                  });
                },
              ),
              const SizedBox(height: 14),

              // 5. Toggle 4: Voice Guidance
              _buildToggleCard(
                title: 'Voice Guidance',
                subtitle: 'Announce token changes aloud',
                icon: Icons.volume_up_outlined,
                isActive: _voiceGuidance,
                onChanged: (val) {
                  setState(() {
                    _voiceGuidance = val;
                  });
                },
              ),
              const SizedBox(height: 28),

              // 6. Live Preview Card (Figma Large Text Comparison Box)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIEW (LARGE TEXT MODE)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

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
                                  'Standard Size',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
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
                        const SizedBox(width: 12),

                        // Enlarged Size Box (Active Highlight)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _largeTextMode
                                  ? AppColors.primaryLight.withOpacity(0.5)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _largeTextMode
                                    ? AppColors.primary
                                    : AppColors.border,
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
                                    color: _largeTextMode
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'A-024',
                                  style: GoogleFonts.inter(
                                    fontSize: 26, // Big 26px bold font!
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
              const SizedBox(height: 20),
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