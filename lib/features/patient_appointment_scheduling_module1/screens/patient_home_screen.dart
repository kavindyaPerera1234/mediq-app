import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'senior_mode_settings_screen.dart';
import 'caregiver_setup_screen.dart';
import 'patient_profile_screen.dart';
import '../../auth_live_queue_module3/screens/auth/welcome_entry_screen.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../../token_lifecycle_notification_module2/screens/digital_token_details_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const PatientHomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
        ProfileService.activeProfileNotifier,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        final profile = ProfileService.activeProfileNotifier.value;
        final patientNic = profile.nic;
        final appointmentService = AppointmentService();

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MediQ Hospital Portal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Ministry of Health Sri Lanka',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppColors.appBarBg,
            elevation: isDark ? 1 : 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.accessibility_new_rounded, color: Colors.white),
                tooltip: AppTranslations.tr('accessibility'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SeniorModeSettingsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Patient Welcome Banner
                    _buildWelcomeHeader(),
                    const SizedBox(height: 16),

                    // 2. Active Token Live Card (Streamed from Firestore)
                    StreamBuilder<List<AppointmentModel>>(
                      stream: appointmentService.streamPatientAppointments(patientNic),
                      builder: (context, snapshot) {
                        final appointments = snapshot.data ?? [];
                        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final activeAppointments = appointments.where((a) {
                          final st = a.status.toLowerCase().trim();
                          if (st == 'completed' || st == 'cancelled' || st == 'missed') {
                            return false;
                          }
                          if (st == 'called' || st == 'serving' || st == 'in_consultation') {
                            return true;
                          }
                          return a.appointmentDate.compareTo(todayStr) >= 0;
                        }).toList();

                        // Prioritize appointments that are actively called/serving today
                        activeAppointments.sort((a, b) {
                          final aSt = a.status.toLowerCase().trim();
                          final bSt = b.status.toLowerCase().trim();
                          final aCalled = (aSt == 'called' || aSt == 'serving' || aSt == 'in_consultation') ? 0 : 1;
                          final bCalled = (bSt == 'called' || bSt == 'serving' || bSt == 'in_consultation') ? 0 : 1;
                          if (aCalled != bCalled) return aCalled.compareTo(bCalled);
                          return a.appointmentDate.compareTo(b.appointmentDate);
                        });

                        if (activeAppointments.isNotEmpty) {
                          return _buildActiveTokenCard(context, activeAppointments.first);
                        } else {
                          return _buildNoActiveTokenCard(context);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Quick Actions Grid
                    Text(
                      AppAccessibility.currentLanguage.value == 'si'
                          ? 'ක්ෂණික සේවාවන්'
                          : (AppAccessibility.currentLanguage.value == 'ta' ? 'விரைவு சேவைகள்' : 'Quick Services'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 20),

                    // 4. Ministry of Health Guidelines
                    Text(
                      AppTranslations.tr('hospitalGuidelines'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 10),
                    _buildGuidelinesCard(AppAccessibility.currentLanguage.value),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out of MediQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().logout();
      await ProfileService().signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed out of MediQ.'),
          backgroundColor: AppColors.statusGreen,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeEntryScreen()),
        (route) => false,
      );
    }
  }

  ImageProvider? _getProfileImage(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('data:image') || clean.startsWith('data:;base64,')) {
      try {
        final commaIdx = clean.indexOf(',');
        final base64Str = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    } else {
      try {
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }
  }

  Widget _buildWelcomeHeader() {
    final profile = ProfileService.activeProfileNotifier.value;
    final fullName = profile.fullName;
    final firstName = fullName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P';
    final patientNic = profile.nic;

    final lang = AppAccessibility.currentLanguage.value;
    String greeting;
    if (lang == 'si') {
      greeting = 'ආයුබෝවන්, $firstName';
    } else if (lang == 'ta') {
      greeting = 'வணக்கம், $firstName';
    } else {
      greeting = 'Welcome, $firstName';
    }

    final hasBloodGroup = profile.bloodGroup.isNotEmpty && profile.bloodGroup != 'Not Set';
    final bloodStr = hasBloodGroup ? 'Blood: ${profile.bloodGroup}' : null;
    final idSubtitle = (patientNic.isNotEmpty && patientNic != 'N/A')
        ? (bloodStr != null ? 'NIC: $patientNic • $bloodStr' : 'NIC: $patientNic')
        : (profile.phone.isNotEmpty
            ? (bloodStr != null ? 'Phone: ${profile.phone} • $bloodStr' : 'Phone: ${profile.phone}')
            : (bloodStr ?? 'NIC: N/A'));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.chipBg,
            backgroundImage: _getProfileImage(profile.photoUrl),
            onBackgroundImageError: profile.photoUrl.isNotEmpty ? (_, __) {} : null,
            child: (profile.photoUrl.isNotEmpty && _getProfileImage(profile.photoUrl) != null)
                ? null
                : Text(initial, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.waving_hand_rounded,
                      color: Color(0xFFFFB300),
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  idSubtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTokenCard(BuildContext context, AppointmentModel appointment) {
    final st = appointment.status.toLowerCase().trim();
    final isCalled = st == 'called' || st == 'serving' || st == 'in_consultation';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (isCalled) {
            onNavigateTab(2);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DigitalTokenDetailsScreen(
                  appointmentId: appointment.id.isNotEmpty
                      ? appointment.id
                      : appointment.tokenCode,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCalled
                  ? [const Color(0xFF0F5132), const Color(0xFF15803D)]
                  : [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: isCalled ? Border.all(color: const Color(0xFF86EFAC), width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: isCalled
                    ? const Color(0xFF15803D).withValues(alpha: 0.45)
                    : AppColors.primary.withValues(alpha: 0.3),
                blurRadius: isCalled ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCalled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFF0F5132)),
                          SizedBox(width: 5),
                          Text(
                            'YOUR TURN IS CALLED NOW!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F5132),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '● YOUR NEXT OPD TOKEN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  if (isCalled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CALLED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    Text(
                      appointment.appointmentDate,
                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.tokenCode,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment.departmentName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointment.hospitalName} • ${appointment.roomNumber}',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            appointment.isCaregiverBooking
                                ? '👨‍👩‍👧 For: ${appointment.patientName} (${appointment.relationship})'
                                : '👤 For: ${appointment.patientName} (Self)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isCalled) ...[
                        ElevatedButton.icon(
                          onPressed: () => onNavigateTab(2),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('Live Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F5132),
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DigitalTokenDetailsScreen(
                                  appointmentId: appointment.id.isNotEmpty
                                      ? appointment.id
                                      : appointment.tokenCode,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View Pass', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DigitalTokenDetailsScreen(
                                  appointmentId: appointment.id.isNotEmpty
                                      ? appointment.id
                                      : appointment.tokenCode,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(AppTranslations.tr('viewTokenPass'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (isCalled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please enter ${appointment.roomNumber} immediately. Doctor is waiting!',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveTokenCard(BuildContext context) {
    final lang = AppAccessibility.currentLanguage.value;
    String title;
    String subtitle;
    String buttonText;

    if (lang == 'si') {
      title = 'අද දින සඳහා සායන වෙන්කිරීම් නොමැත';
      subtitle = 'පෝලිම්වල නොරැඳී ඩිජිටල් ටෝකනයක් ලබාගැනීමට පහසුවෙන් සායනයක් වෙන්කරවා ගන්න.';
      buttonText = 'නව සායනයක් වෙන්කරවා ගැනීම';
    } else if (lang == 'ta') {
      title = 'இன்று செயலில் உள்ள சந்திப்புகள் இல்லை';
      subtitle = 'வரிசையில் காத்திருக்காமல் டிஜிட்டல் டோக்கனைப் பெற எளிதாக பதிவு செய்யவும்.';
      buttonText = 'புதிய சந்திப்பை பதிவு செய்யவும்';
    } else {
      title = 'No Active Appointments Today';
      subtitle = 'Book your government OPD clinic slot in 5 easy steps and get a digital pass.';
      buttonText = 'Book OPD Appointment';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headingText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.bodyText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaregiverSetupScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                buttonText,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.28,
      children: [
        _buildActionCard(
          title: AppTranslations.tr('bookNewOpd'),
          subtitle: 'Choose hospital & time',
          icon: Icons.calendar_month_rounded,
          color: AppColors.accentColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaregiverSetupScreen()),
            );
          },
        ),
        _buildActionCard(
          title: AppTranslations.tr('trackLiveQueue'),
          subtitle: 'Real-time room tracking',
          icon: Icons.format_list_numbered_rounded,
          color: AppColors.statusGreen,
          onTap: () => onNavigateTab(2),
        ),
        _buildActionCard(
          title: AppTranslations.tr('navAlerts'),
          subtitle: 'Token notifications',
          icon: Icons.sms_outlined,
          color: AppColors.statusOrange,
          onTap: () => onNavigateTab(3),
        ),
        _buildActionCard(
          title: AppTranslations.tr('patientDependents'),
          subtitle: 'Caregiver management',
          icon: Icons.person_pin_rounded,
          color: Colors.purple.shade400,
          onTap: () {
            PatientProfileScreen.selectedTabNotifier.value = 1;
            onNavigateTab(4);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.headingText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: AppColors.bodyText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinesCard(String lang) {
    String g1;
    String g2;
    String g3;

    if (lang == 'si') {
      g1 = 'OPD වේලාවන්: උදෑසන 8:00 – 12:00 | පස්වරු 12:00 – 2:00';
      g2 = 'කරුණාකර පැමිණෙන විට ඔබගේ මුල් හැඳුනුම්පත (NIC) සහ සායන පොත ඉදිරිපත් කරන්න.';
      g3 = 'වැඩිහිටියන් (60+) සහ ආබාධිත රෝගීන් සඳහා විශේෂ ප්‍රමුඛතා පෝලිම් පහසුකම් ඇත.';
    } else if (lang == 'ta') {
      g1 = 'OPD நேரம்: காலை 8:00 – 12:00 | மதியம் 12:00 – 2:00';
      g2 = 'வருகையின் போது உங்கள் அசல் NIC மற்றும் கிளினிக் புத்தகத்தை சமர்ப்பிக்கவும்.';
      g3 = 'மூத்த குடிமக்கள் (60+) மற்றும் மாற்றுத்திறனாளிகளுக்கு முன்னுரிமை வரிசை உள்ளது.';
    } else {
      g1 = 'OPD Hours: Morning 8:00 AM – 12:00 PM | Afternoon 12:00 PM – 2:00 PM';
      g2 = 'Please present your Original NIC & Clinic Book upon arrival.';
      g3 = 'Priority triage lanes available for Senior Citizens (60+) & Disabled patients.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildGuidelineRow(
            icon: Icons.schedule_rounded,
            title: g1,
          ),
          Divider(height: 14, color: AppColors.cardBorder),
          _buildGuidelineRow(
            icon: Icons.badge_outlined,
            title: g2,
          ),
          Divider(height: 14, color: AppColors.cardBorder),
          _buildGuidelineRow(
            icon: Icons.elderly_rounded,
            title: g3,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineRow({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 11.5, color: AppColors.headingText, height: 1.3),
          ),
        ),
      ],
    );
  }
}
