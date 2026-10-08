import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
import '../../../../core/constants/app_translations.dart';
import 'hospital_selection_screen.dart';
import '../admin/screens/hospital_admin_dashboard.dart';
import '../backend/backend.dart';

class CaregiverSetupScreen extends StatefulWidget {
  const CaregiverSetupScreen({super.key});

  @override
  State<CaregiverSetupScreen> createState() => _CaregiverSetupScreenState();
}

class _CaregiverSetupScreenState extends State<CaregiverSetupScreen> {
  // Initially null so neither option is auto-selected by default
  String? _bookingMode;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();

  String? _selectedRelationship;
  String _selectedPriority = 'normal';

  String? _selectedDependentNic;
  final List<String> _relationships = ['Father', 'Mother', 'Child', 'Spouse', 'Other'];
  final CaregiverService _caregiverService = CaregiverService();
  String get _currentUserId => ProfileService.activeProfileNotifier.value.patientId;
  String get _currentPatientNic => ProfileService.activeProfileNotifier.value.nic;

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  void _proceedToHospitalSelection() {
    if (_bookingMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who this appointment is for to continue.'),
          backgroundColor: AppColors.statusOrange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_bookingMode == 'someone_else') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    final activeProfile = ProfileService.activeProfileNotifier.value;
    final selfName = activeProfile.fullName.isNotEmpty ? activeProfile.fullName : 'Patient';
    final selfNic = (activeProfile.nic.isNotEmpty && activeProfile.nic != 'N/A') ? activeProfile.nic : '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalSelectionScreen(
          isCaregiverBooking: _bookingMode == 'someone_else',
          patientName: _bookingMode == 'someone_else' ? _nameController.text.trim() : selfName,
          patientNic: _bookingMode == 'someone_else' ? _nicController.text.trim() : selfNic,
          relationship: _bookingMode == 'someone_else' ? (_selectedRelationship ?? 'Other') : 'Self',
          priority: _bookingMode == 'someone_else' ? _selectedPriority : 'normal',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('navAppointments'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Module 1 Hospital Admin Console',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HospitalAdminDashboard()),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // Ministry of Health Sri Lanka Trust Banner
                  _buildTrustBanner(),

                  // Segmented 5-Step Stepper (Clean & uncluttered)
                  _buildSegmentedStepper(),

                  Expanded(
                    child: SingleChildScrollView(
                      // 100px bottom padding ensures sticky button never cuts off the bottom chips/inputs
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.tr('whoIsAppointmentFor'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppTranslations.tr('chooseOptionBelow'),
                            style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
                          ),
                          const SizedBox(height: 20),

                          // Option 1: Myself
                          _buildOptionCard(
                            id: 'myself',
                            title: AppTranslations.tr('myself'),
                            subtitle: AppTranslations.tr('myselfDesc'),
                            icon: Icons.person_rounded,
                          ),

                          const SizedBox(height: 14),

                          // Option 2: Someone Else (Caregiver Mode)
                          _buildOptionCard(
                            id: 'someone_else',
                            title: AppTranslations.tr('someoneElse'),
                            subtitle: AppTranslations.tr('someoneElseDesc'),
                            icon: Icons.family_restroom_rounded,
                          ),

                          const SizedBox(height: 24),

                          // Dynamic Content: Shows ONLY after user selects an option
                          if (_bookingMode == 'myself')
                            _buildMyselfProfileCard()
                          else if (_bookingMode == 'someone_else')
                            _buildCaregiverForm()
                          else
                            _buildSelectionPrompt(),
                        ],
                      ),
                    ),
                  ),

                  // Pinned Bottom Action Button
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Ministry of Health Sri Lanka Official Trust Banner
  Widget _buildTrustBanner() {
    final lang = AppAccessibility.currentLanguage.value;
    final bannerText = lang == 'si'
        ? 'සෞඛ්‍ය අමාත්‍යාංශය • නොමිලේ OPD E-Channeling සේවාව'
        : (lang == 'ta'
            ? 'சுகாதார அமைச்சு • இலவச OPD மின்-பதிவு சேவை'
            : 'Ministry of Health Sri Lanka • Free OPD E-Channeling');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 16, color: AppColors.accentColor),
          const SizedBox(width: 8),
          Text(
            bannerText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accentColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Segmented 5-Step Progress Stepper
  Widget _buildSegmentedStepper() {
    final lang = AppAccessibility.currentLanguage.value;
    final nextHospital = lang == 'si' ? 'ඊළඟ: රෝහල' : (lang == 'ta' ? 'அடுத்தது: மருத்துவமனை' : 'Next: Hospital');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr('step1Title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                nextHospital,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Clean Distinct Segments
          Row(
            children: [
              _buildStepSegment(isActive: true, isCompleted: false),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: false),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: false),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: false),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({required bool isActive, required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentColor
              : isCompleted
                  ? AppColors.statusGreen
                  : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // Placeholder prompt when nothing is selected yet
  Widget _buildSelectionPrompt() {
    final lang = AppAccessibility.currentLanguage.value;
    final promptText = lang == 'si'
        ? 'රෝගියාගේ විස්තර ඇතුළත් කිරීමට කරුණාකර ඉහත විකල්ප දෙකෙන් එකක් තෝරන්න.'
        : (lang == 'ta'
            ? 'தொடர மேலே உள்ள இரண்டு விருப்பங்களில் ஒன்றைத் தேர்ந்தெடுக்கவும்.'
            : 'Select one of the two options above to enter patient details and proceed.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, color: AppColors.accentColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              promptText,
              style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Option Selection Card with Soft Tint on Selected State
  Widget _buildOptionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _bookingMode == id;

    return InkWell(
      onTap: () => setState(() => _bookingMode = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipBg : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentColor : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accentColor.withValues(alpha: 0.12)
                  : (AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03)),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentColor.withValues(alpha: 0.2) : AppColors.innerCardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accentColor : AppColors.bodyText,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accentColor : AppColors.headingText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.bodyText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.accentColor : AppColors.bodyText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Pre-filled Card for Primary Patient (Myself)
  Widget _buildMyselfProfileCard() {
    final lang = AppAccessibility.currentLanguage.value;
    final verifiedTitle = lang == 'si' ? 'තහවුරු කළ රෝගී විස්තර' : (lang == 'ta' ? 'சரிபார்க்கப்பட்ட சுயவிவர விவரங்கள்' : 'Verified Profile Details');
    final nameLabel = lang == 'si' ? 'සම්පූර්ණ නම:' : (lang == 'ta' ? 'முழு பெயர்:' : 'Full Name:');
    final nicLabel = lang == 'si' ? 'හැඳුනුම්පත් අංකය (NIC):' : (lang == 'ta' ? 'அடையாள அட்டை (NIC):' : 'National ID (NIC):');
    final phoneLabel = lang == 'si' ? 'දුරකථන අංකය:' : (lang == 'ta' ? 'தொலைபேசி எண்:' : 'Mobile Phone:');
    final noticeText = lang == 'si'
        ? 'සායන ටෝකනය සහ පෝලිම් SMS පණිවිඩ ඔබගේ ලියාපදිංචි දුරකථන අංකයට යවනු ලැබේ.'
        : (lang == 'ta'
            ? 'சந்திப்பு டோக்கன் மற்றும் வரிசை SMS உங்கள் தொலைபேசிக்கு அனுப்பப்படும்.'
            : 'Appointment token & queue SMS will be sent to your registered mobile number.');
    final editHint = lang == 'si'
        ? 'පැතිකඩ විස්තර ඔබගේ NIC ගිණුමට සම්බන්ධ කර ඇත.'
        : (lang == 'ta'
            ? 'சுயவிவர விவரங்கள் உங்கள் NIC உடன் இணைக்கப்பட்டுள்ளன.'
            : 'Profile details are linked to your NIC account.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.statusGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    verifiedTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingText,
                    ),
                  ),
                ],
              ),
              // User Control: Change details hint
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editHint),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppTranslations.tr('editProfile'), style: TextStyle(fontSize: 12, color: AppColors.accentColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(height: 20, color: AppColors.cardBorder),
          ValueListenableBuilder<PatientProfileModel>(
            valueListenable: ProfileService.activeProfileNotifier,
            builder: (context, activeProfile, _) {
              final selfName = activeProfile.fullName.isNotEmpty ? activeProfile.fullName : 'Patient';
              final selfNic = activeProfile.nic.isNotEmpty ? activeProfile.nic : 'N/A';
              final selfPhone = activeProfile.phone.isNotEmpty ? activeProfile.phone : '';

              return Column(
                children: [
                  _buildInfoRow(nameLabel, selfName),
                  const SizedBox(height: 10),
                  _buildInfoRow(nicLabel, selfNic),
                  const SizedBox(height: 10),
                  _buildInfoRow(phoneLabel, selfPhone),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accentColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    noticeText,
                    style: TextStyle(fontSize: 12, color: AppColors.accentColor, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText)),
      ],
    );
  }

  // Dynamic Caregiver Form
  Widget _buildCaregiverForm() {
    final lang = AppAccessibility.currentLanguage.value;
    final depTitle = lang == 'si' ? 'රෝගියාගේ තොරතුරු (යැපෙන්නා)' : (lang == 'ta' ? 'நோயாளி தகவல் (குடும்ப உறுப்பினர்)' : 'Patient Information (Dependent)');

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark ? Colors.black26 : AppColors.statusOrange.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.statusOrange, size: 22),
                const SizedBox(width: 8),
                Text(
                  depTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headingText,
                  ),
                ),
              ],
            ),
            Divider(height: 22, color: AppColors.cardBorder),

            // Quick Select from Registered Dependents
            StreamBuilder<List<CaregiverPatientModel>>(
              stream: _caregiverService.streamCaregiverPatients(_currentUserId, patientNic: _currentPatientNic),
              builder: (context, snapshot) {
                final dependents = snapshot.data ?? [];
                if (dependents.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.family_restroom_rounded, size: 16, color: AppColors.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslations.tr('savedDependents'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...dependents.map((dep) {
                              final isSelected = _selectedDependentNic == dep.patientNic;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.person_rounded,
                                    size: 16,
                                    color: isSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.accentColor,
                                  ),
                                  label: Text(
                                    '${dep.patientName} (${dep.relationship})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.headingText,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.accentColor,
                                  backgroundColor: AppColors.innerCardBg,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.accentColor : AppColors.cardBorder,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDependentNic = dep.patientNic;
                                        _nameController.text = dep.patientName;
                                        _nicController.text = dep.patientNic;
                                        if (_relationships.contains(dep.relationship)) {
                                          _selectedRelationship = dep.relationship;
                                        } else {
                                          _selectedRelationship = 'Other';
                                        }
                                        _selectedPriority = dep.priority;
                                      } else {
                                        _selectedDependentNic = null;
                                        _nameController.clear();
                                        _nicController.clear();
                                        _selectedRelationship = null;
                                        _selectedPriority = 'normal';
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Text(AppTranslations.tr('patientFullName'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontSize: 14, color: AppColors.headingText),
              decoration: _inputDecoration('e.g., Sunil Perera', Icons.person_outline),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
            ),
            const SizedBox(height: 14),

            Text(AppTranslations.tr('nicOrBirthCert'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nicController,
              style: TextStyle(fontSize: 14, color: AppColors.headingText),
              decoration: _inputDecoration('e.g., 195812345678', Icons.badge_outlined),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter NIC or Birth Cert No' : null,
            ),
            const SizedBox(height: 14),

            Text(AppTranslations.tr('relationship'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              dropdownColor: AppColors.cardSurface,
              style: TextStyle(fontSize: 14, color: AppColors.headingText),
              iconEnabledColor: AppColors.headingText,
              hint: Text('Select Relationship (e.g. Father, Mother...)', style: TextStyle(fontSize: 13, color: AppColors.bodyText)),
              decoration: _inputDecoration('Select Relationship', Icons.people_outline),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: AppColors.headingText)))).toList(),
              validator: (val) => val == null || val.isEmpty ? 'Please select relationship' : null,
              onChanged: (val) {
                if (val != null) setState(() => _selectedRelationship = val);
              },
            ),
            const SizedBox(height: 16),

            Text(AppTranslations.tr('specialPriority'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip('normal', AppTranslations.tr('standardPriority'), Icons.accessibility_new),
                _buildPriorityChip('elderly', AppTranslations.tr('elderlyPriority'), Icons.elderly),
                _buildPriorityChip('disabled', AppTranslations.tr('wheelchairPriority'), Icons.accessible),
                _buildPriorityChip('pregnant', AppTranslations.tr('maternityPriority'), Icons.pregnant_woman),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, IconData icon) {
    final isSelected = _selectedPriority == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.headingText),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.headingText)),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.accentColor,
      backgroundColor: AppColors.innerCardBg,
      side: BorderSide(
        color: isSelected ? AppColors.accentColor : AppColors.cardBorder,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedPriority = value);
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.bodyText, size: 20),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: AppColors.bodyText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.innerCardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.accentColor, width: 1.5),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final isOptionSelected = _bookingMode != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedToHospitalSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOptionSelected ? AppColors.accentColor : (AppColors.isDark ? const Color(0xFF334155) : AppColors.border),
              foregroundColor: isOptionSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.bodyText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.tr('continueToHospital'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOptionSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.bodyText,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isOptionSelected ? (AppColors.isDark ? Colors.black : Colors.white) : AppColors.bodyText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}