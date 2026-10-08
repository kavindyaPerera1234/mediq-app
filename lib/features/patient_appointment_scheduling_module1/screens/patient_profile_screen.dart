import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../../../core/services/voice_guidance_service.dart';
import '../backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'senior_mode_settings_screen.dart';
import '../../auth_live_queue_module3/screens/auth/welcome_entry_screen.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final CaregiverService _caregiverService = CaregiverService();
  final AppointmentService _appointmentService = AppointmentService();

  late PatientProfileModel _profile;
  bool _isLoading = true;

  String get _currentUserId => _profile.patientId;
  String get _currentPatientNic => _profile.nic;
  String _appointmentFilter = 'upcoming'; // 'upcoming' or 'past'
  int _selectedProfileTab = 0; // 0: Appointments, 1: Family Dependents, 2: Settings & Preferences

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.activeProfileNotifier.value;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.syncWithCurrentUser();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profile.fullName);
    final phoneController = TextEditingController(text: _profile.phone);
    final emailController = TextEditingController(text: _profile.email);
    final emergencyNameController = TextEditingController(text: _profile.emergencyContactName);
    final emergencyPhoneController = TextEditingController(text: _profile.emergencyContactPhone);
    String bloodGroup = _profile.bloodGroup;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Patient Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.headingText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 12),

                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.chipBg,
                            backgroundImage: _profile.photoUrl.isNotEmpty ? NetworkImage(_profile.photoUrl) : null,
                            child: _profile.photoUrl.isEmpty
                                ? Text(
                                    _profile.fullName.isNotEmpty ? _profile.fullName[0] : 'P',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accentColor),
                                  )
                                : null,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(context);
                              _showProfilePhotoModal();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildFieldLabel('Full Name'),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration('Enter full name'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Phone Number'),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('+94 77 123 4567'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Email Address'),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('example@gmail.com'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Blood Group'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: bloodGroup,
                          isExpanded: true,
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) {
                            return DropdownMenuItem(value: bg, child: Text(bg));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                bloodGroup = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Emergency Contact (Name & Phone)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emergencyNameController,
                            decoration: _inputDecoration('Contact Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: emergencyPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Phone No'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final updated = _profile.copyWith(
                            fullName: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            bloodGroup: bloodGroup,
                            emergencyContactName: emergencyNameController.text.trim(),
                            emergencyContactPhone: emergencyPhoneController.text.trim(),
                          );

                          setState(() {
                            _profile = updated;
                          });

                          await _profileService.savePatientProfile(updated);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: AppColors.statusGreen,
                            ),
                          );
                        },
                        child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfilePhotoModal() {
    final urlController = TextEditingController(text: _profile.photoUrl);

    final List<Map<String, String>> presetAvatars = [
      {
        'label': 'Female (Default)',
        'url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&fit=crop&crop=faces',
      },
      {
        'label': 'Nurse / Doctor',
        'url': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&fit=crop&crop=faces',
      },
      {
        'label': 'Elderly Mother',
        'url': 'https://images.unsplash.com/photo-1581579438747-1dc8d17bbce4?w=200&fit=crop&crop=faces',
      },
      {
        'label': 'Elderly Father',
        'url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&fit=crop&crop=faces',
      },
      {
        'label': 'Male Patient',
        'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&fit=crop&crop=faces',
      },
      {
        'label': 'Young Adult',
        'url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&fit=crop&crop=faces',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Profile Photo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.headingText),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                Divider(color: AppColors.cardBorder),
                const SizedBox(height: 12),
                Text(
                  'Select a Profile Avatar:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingText),
                ),
                const SizedBox(height: 12),

                // Avatar Horizontal Selector
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, idx) {
                      final item = presetAvatars[idx];
                      final isSelected = _profile.photoUrl == item['url'];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(modalCtx);
                          await _saveProfilePhoto(item['url']!);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(item['url']!),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['label']!.split(' ')[0],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // Option 2: Enter Custom Photo URL
                const Text(
                  'Or Paste Image Web URL:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        decoration: _inputDecoration('https://... image.jpg'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final url = urlController.text.trim();
                        if (url.isNotEmpty) {
                          Navigator.pop(modalCtx);
                          await _saveProfilePhoto(url);
                        }
                      },
                      child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Option 3: Remove Profile Photo
                if (_profile.photoUrl.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      label: const Text('Remove Profile Photo', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(modalCtx);
                        await _saveProfilePhoto('');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfilePhoto(String newUrl) async {
    setState(() {
      _profile = _profile.copyWith(photoUrl: newUrl);
    });
    final success = await _profileService.updateProfilePhoto(_currentPatientNic, newUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile photo updated successfully!' : 'Failed to update photo online.'),
        backgroundColor: success ? AppColors.statusGreen : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddCaregiverDialog() {
    final nameCtrl = TextEditingController();
    final nicCtrl = TextEditingController();
    String rel = 'Father';
    String prio = 'elderly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Family Member / Dependent',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.headingText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Full Name'),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.headingText),
                      decoration: _inputDecoration('e.g. Sunil Perera'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('National ID (NIC) / Birth Reg'),
                    TextField(
                      controller: nicCtrl,
                      style: TextStyle(color: AppColors.headingText),
                      decoration: _inputDecoration('e.g. 195812345678'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Relationship'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.innerCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: rel,
                          dropdownColor: AppColors.cardSurface,
                          style: TextStyle(color: AppColors.headingText, fontSize: 13),
                          isExpanded: true,
                          items: ['Father', 'Mother', 'Child', 'Spouse', 'Other'].map((r) {
                            return DropdownMenuItem(value: r, child: Text(r));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => rel = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Triage Priority Category'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.innerCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: prio,
                          dropdownColor: AppColors.cardSurface,
                          style: TextStyle(color: AppColors.headingText, fontSize: 13),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'elderly', child: Text('Elderly (60+ Years)')),
                            DropdownMenuItem(value: 'wheelchair', child: Text('Wheelchair / Special Mobility')),
                            DropdownMenuItem(value: 'maternity', child: Text('Maternity / Infant')),
                            DropdownMenuItem(value: 'normal', child: Text('Standard Patient')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => prio = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final nic = nicCtrl.text.trim();
                          if (name.isEmpty || nic.isEmpty) return;

                          await _caregiverService.addCaregiverPatient(
                            CaregiverPatientModel(
                              id: '',
                              caregiverUserId: _currentUserId,
                              patientName: name,
                              patientNic: nic,
                              relationship: rel,
                              priority: prio,
                            ),
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Family member registered successfully!'),
                              backgroundColor: AppColors.statusGreen,
                            ),
                          );
                        },
                        child: const Text('Register Dependent', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.bodyText),
      filled: true,
      fillColor: AppColors.innerCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText),
      ),
    );
  }

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
        _profile = ProfileService.activeProfileNotifier.value;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: AppColors.pageBg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('patientProfile'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: AppTranslations.tr('accessibility'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SeniorModeSettingsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppTranslations.tr('editProfile'),
                onPressed: _showEditProfileDialog,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Patient Profile Header Card
                    _buildProfileHeaderCard(),
                    const SizedBox(height: 16),

                    // 2. Clean Segmented Navigation Tabs
                    _buildProfileTabBar(),
                    const SizedBox(height: 16),

                    // 3. Dynamic Clean Tab Content
                    if (_selectedProfileTab == 0)
                      _buildAppointmentsSection()
                    else if (_selectedProfileTab == 1)
                      _buildCaregiversSection()
                    else ...[
                      _buildLanguageSelectorCard(isDark),
                      const SizedBox(height: 16),
                      _buildLogoutCard(context),
                    ],
                    const SizedBox(height: 30),
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
    final isSi = AppAccessibility.currentLanguage.value == 'si';
    final isTa = AppAccessibility.currentLanguage.value == 'ta';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSi ? 'පද්ධතියෙන් ඉවත් වන්න' : (isTa ? 'வெளியேறு' : 'Log Out')),
        content: Text(
          isSi
              ? 'ඔබට MediQ පද්ධතියෙන් ඉවත් වීමට අවශ්‍ය බව සහතිකද?'
              : (isTa ? 'MediQ இலிருந்து வெளியேற விரும்புகிறீர்களா?' : 'Are you sure you want to sign out of MediQ?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSi ? 'අවලංගු කරන්න' : (isTa ? 'ரத்து' : 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSi ? 'ඉවත් වන්න' : (isTa ? 'வெளியேறு' : 'Log Out')),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().logout();
      await _profileService.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSi ? 'සාර්ථකව ඉවත් විය.' : (isTa ? 'வெற்றிகரமாக வெளியேறியது.' : 'Successfully signed out of MediQ.')),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeEntryScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildLogoutCard(BuildContext context) {
    final isSi = AppAccessibility.currentLanguage.value == 'si';
    final isTa = AppAccessibility.currentLanguage.value == 'ta';
    final logoutText = isSi ? 'ගිණුමෙන් ඉවත් වන්න (Log Out)' : (isTa ? 'வெளியேறு (Log Out)' : 'Log Out of MediQ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusRed,
                side: BorderSide(color: AppColors.statusRed.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.statusRed),
              label: Text(
                logoutText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorCard(bool isDark) {
    final currentLang = AppAccessibility.currentLanguage.value;
    final options = [
      {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'label': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'label': 'தமிழ்', 'flag': '🇱🇰'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: AppColors.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                AppTranslations.tr('language'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
              ),
              const Spacer(),
              Text(
                AppTranslations.tr('selectLanguage'),
                style: TextStyle(fontSize: 11, color: AppColors.bodyText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: options.map((opt) {
              final isSelected = currentLang == opt['code'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      final langCode = opt['code']!;
                      AppAccessibility.setLanguage(langCode);
                      final user = AuthService().currentUser;
                      if (user != null) {
                        FirebaseFirestore.instance.collection('users').doc(user.userId).update({
                          'preferredLanguage': langCode,
                        }).catchError((_) {});
                      }
                      if (langCode == 'si') {
                        VoiceGuidanceService.speak('භාෂාව සිංහල ලෙස වෙනස් කරන ලදී', context: context);
                      } else if (langCode == 'ta') {
                        VoiceGuidanceService.speak('மொழி தமிழில் மாற்றப்பட்டது', context: context);
                      } else {
                        VoiceGuidanceService.speak('Language switched to English', context: context);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentColor : AppColors.innerCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.accentColor : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(opt['flag']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.headingText,
                            ),
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

  Widget _buildProfileTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.innerCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildTabItem(0, AppTranslations.tr('navAppointments'), Icons.confirmation_number_outlined),
          _buildTabItem(1, AppTranslations.tr('patientDependents'), Icons.family_restroom_rounded),
          _buildTabItem(2, AppTranslations.tr('settings'), Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedProfileTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedProfileTab = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentColor.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.bodyText,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.bodyText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Top bar inside profile card with Verified badge & Edit Profile button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: AppColors.accentColor),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Patient',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentColor),
                    ),
                  ],
                ),
              ),
              // Clean Edit Profile Button
              InkWell(
                onTap: _showEditProfileDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.accentColor),
                      const SizedBox(width: 5),
                      Text(
                        AppTranslations.tr('editProfile'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Interactive Avatar with Camera Badge
              Stack(
                children: [
                  GestureDetector(
                    onTap: _showProfilePhotoModal,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.chipBg,
                      backgroundImage: _profile.photoUrl.isNotEmpty
                          ? NetworkImage(_profile.photoUrl)
                          : null,
                      child: _profile.photoUrl.isEmpty
                          ? Text(
                              _profile.fullName.isNotEmpty ? _profile.fullName[0] : 'P',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accentColor),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showProfilePhotoModal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardSurface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _profile.fullName,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight.withValues(alpha: AppColors.isDark ? 0.2 : 1.0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _profile.bloodGroup,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.isDark ? const Color(0xFFFCA5A5) : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIC: ${_profile.nic}',
                      style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profile.phone,
                      style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppColors.cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildInfoColumn('GENDER', _profile.gender)),
              Container(width: 1, height: 24, color: AppColors.cardBorder),
              Expanded(child: _buildInfoColumn('DOB', _profile.dateOfBirth)),
              Container(width: 1, height: 24, color: AppColors.cardBorder),
              Expanded(
                child: Tooltip(
                  message: 'Emergency Contact: ${_profile.emergencyContactName} (${_profile.emergencyContactPhone})',
                  child: _buildInfoColumn(
                    'EMG. CONTACT',
                    _profile.emergencyContactName,
                    icon: Icons.phone_in_talk_rounded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: AppColors.bodyText),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.bodyText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Live StreamBuilder for Caregiver Dependents
  Widget _buildCaregiversSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.family_restroom_rounded, color: AppColors.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.tr('patientDependents'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(Icons.add_rounded, size: 16, color: AppColors.accentColor),
                label: Text(AppTranslations.tr('addDependent'), style: TextStyle(fontSize: 12, color: AppColors.accentColor)),
                onPressed: _showAddCaregiverDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Family members registered under your care for easy 1-tap booking.',
            style: TextStyle(fontSize: 11, color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<CaregiverPatientModel>>(
            stream: _caregiverService.streamCaregiverPatients(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.innerCardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'No dependents added yet. Tap "+ Add Member" above.',
                      style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                    ),
                  ),
                );
              }

              return Column(
                children: list.map((dep) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.innerCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, size: 18, color: AppColors.accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dep.patientName} (${dep.relationship})',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('NIC: ${dep.patientNic}', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                          tooltip: 'Remove from Family',
                          onPressed: () => _confirmDeleteCaregiver(dep),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCaregiver(CaregiverPatientModel dep) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Remove Family Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${dep.patientName} (${dep.relationship})" from your saved family dependents?',
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _caregiverService.deleteCaregiverPatient(dep.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${dep.patientName} removed from saved family members.'),
                    backgroundColor: AppColors.textDark,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusBadge(AppointmentModel app, bool isUpcoming) {
    Color bg;
    Color fg;
    String label;

    final status = app.status.toLowerCase().trim();
    if (status == 'confirmed') {
      if (isUpcoming) {
        bg = AppColors.statusGreen.withValues(alpha: 0.12);
        fg = AppColors.statusGreen;
        label = 'CONFIRMED';
      } else {
        bg = Colors.blueGrey.withValues(alpha: 0.12);
        fg = Colors.blueGrey;
        label = 'COMPLETED';
      }
    } else if (status == 'rescheduled') {
      bg = AppColors.statusOrange.withValues(alpha: 0.15);
      fg = AppColors.statusOrange;
      label = 'RESCHEDULED';
    } else if (status == 'waiting') {
      bg = AppColors.statusGreen.withValues(alpha: 0.12);
      fg = AppColors.statusGreen;
      label = 'WAITING';
    } else if (status == 'called') {
      bg = Colors.blue.withValues(alpha: 0.12);
      fg = Colors.blue;
      label = 'CALLED';
    } else if (status == 'cancelled') {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      label = 'CANCELLED';
    } else if (status == 'missed') {
      bg = Colors.deepOrange.withValues(alpha: 0.12);
      fg = Colors.deepOrange;
      label = 'MISSED';
    } else {
      bg = Colors.blueGrey.withValues(alpha: 0.12);
      fg = Colors.blueGrey;
      label = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // Live StreamBuilder for My Booked Appointments
  Widget _buildAppointmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: AppColors.statusOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'My Active OPD Tokens & Appointments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Live appointments synced with Ministry of Health Cloud.',
            style: TextStyle(fontSize: 11, color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentService.streamPatientAppointments(_currentPatientNic),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)));
              }

              final list = snapshot.data ?? [];
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

              final upcomingList = list.where((app) {
                final isFutureOrToday = app.appointmentDate.compareTo(todayStr) >= 0;
                final isActiveStatus = app.status == 'confirmed' || app.status == 'rescheduled' || app.status == 'waiting';
                return isFutureOrToday && isActiveStatus;
              }).toList();

              final pastList = list.where((app) {
                final isPastDate = app.appointmentDate.compareTo(todayStr) < 0;
                final isClosedStatus = app.status == 'completed' || app.status == 'cancelled' || app.status == 'missed' || app.status == 'called';
                return isPastDate || isClosedStatus;
              }).toList();

              final displayedList = _appointmentFilter == 'upcoming' ? upcomingList : pastList;

              return Column(
                children: [
                  // Segmented Filter Tabs: Upcoming vs Past History
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.innerCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _appointmentFilter = 'upcoming'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _appointmentFilter == 'upcoming' ? AppColors.cardSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _appointmentFilter == 'upcoming'
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${AppTranslations.tr('upcomingAppointments')} (${upcomingList.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _appointmentFilter == 'upcoming' ? AppColors.accentColor : AppColors.bodyText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _appointmentFilter = 'past'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _appointmentFilter == 'past' ? AppColors.cardSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _appointmentFilter == 'past'
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${AppTranslations.tr('pastAppointments')} (${pastList.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _appointmentFilter == 'past' ? AppColors.accentColor : AppColors.bodyText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (displayedList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.innerCardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _appointmentFilter == 'upcoming'
                              ? 'No upcoming appointments. Book your next visit in Tab 1!'
                              : 'No past appointments found.',
                          style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                        ),
                      ),
                    )
                  else
                    ...displayedList.map((app) {
                      final isUpcoming = (app.status == 'confirmed' || app.status == 'rescheduled' || app.status == 'waiting') &&
                          app.appointmentDate.compareTo(todayStr) >= 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.innerCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showTokenPassModal(app),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.chipBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            app.tokenCode,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.chipBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            app.roomNumber,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.headingText),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildAppointmentStatusBadge(app, isUpcoming),
                                        const SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.bodyText),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  app.departmentName,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${app.hospitalName} • ${app.appointmentDate} • ${app.timeSlot}',
                                  style: TextStyle(fontSize: 11, color: AppColors.bodyText),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      app.isCaregiverBooking ? Icons.family_restroom_rounded : Icons.person_outline_rounded,
                                      size: 13,
                                      color: app.isCaregiverBooking ? AppColors.statusOrange : AppColors.accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        app.isCaregiverBooking
                                            ? 'Patient: ${app.patientName} (${app.relationship})'
                                            : 'Patient: ${app.patientName} (Self)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: app.isCaregiverBooking ? AppColors.statusOrange : AppColors.accentColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isUpcoming) ...[
                                      GestureDetector(
                                        onTap: () => _confirmCancelAppointment(app),
                                        child: const Text(
                                          'Cancel Slot',
                                          style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                    GestureDetector(
                                      onTap: () => _showTokenPassModal(app),
                                      child: Text(
                                        'View Pass →',
                                        style: TextStyle(fontSize: 11, color: AppColors.accentColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  void _showTokenPassModal(AppointmentModel app) {
    VoiceGuidanceService.speak(
      "Viewing token ${app.tokenCode} for ${app.patientName}. Room ${app.roomNumber}, ${app.departmentName}.",
      context: context,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isConfirmed = app.status == 'confirmed';
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Digital Pass Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OPD Digital Token Pass',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? AppColors.statusGreen.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isConfirmed ? '● ACTIVE TOKEN' : '● CANCELLED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConfirmed ? AppColors.statusGreen : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Token Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'ESTIMATED TOKEN NUMBER',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentColor, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.tokenCode,
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.accentColor, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Room: ${app.roomNumber}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details
              _buildModalDetailRow('Hospital', app.hospitalName),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('Specialty Clinic', app.departmentName),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('Date', app.appointmentDate),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('Time Slot', app.timeSlot),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('Patient Name', app.patientName),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('NIC', app.patientNic),
              Divider(height: 16, color: AppColors.cardBorder),
              _buildModalDetailRow('Priority', app.priority.toUpperCase()),
              const SizedBox(height: 20),

              if (isConfirmed) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                    label: const Text('Cancel Appointment', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmCancelAppointment(app);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingText)),
      ],
    );
  }

  void _confirmCancelAppointment(AppointmentModel app) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Cancel Appointment?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel token ${app.tokenCode} for ${app.departmentName} on ${app.appointmentDate}?\n\nThis will release your reserved slot to other awaiting patients.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Keep Appointment'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await _appointmentService.cancelAppointment(app.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Token ${app.tokenCode} was cancelled successfully.'
                          : 'Failed to cancel appointment. Please check connection.',
                    ),
                    backgroundColor: success ? AppColors.textDark : AppColors.error,
                  ),
                );
              },
              child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
