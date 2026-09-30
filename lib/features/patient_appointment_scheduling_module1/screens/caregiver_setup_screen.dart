import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'hospital_selection_screen.dart';
import '../admin/screens/hospital_admin_dashboard.dart';
import '../models/caregiver_model.dart';
import '../services/caregiver_service.dart';

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

  String _selectedRelationship = 'Father';
  String _selectedPriority = 'normal';

  final List<String> _relationships = ['Father', 'Mother', 'Child', 'Spouse', 'Other'];
  final CaregiverService _caregiverService = CaregiverService();
  final String _currentUserId = 'user_200164801234';

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalSelectionScreen(
          isCaregiverBooking: _bookingMode == 'someone_else',
          patientName: _bookingMode == 'someone_else' ? _nameController.text.trim() : 'Sandeepani Perera',
          patientNic: _bookingMode == 'someone_else' ? _nicController.text.trim() : '200164801234',
          relationship: _bookingMode == 'someone_else' ? _selectedRelationship : 'Self',
          priority: _bookingMode == 'someone_else' ? _selectedPriority : 'normal',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Book OPD Appointment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
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
                      const Text(
                        'Who is this appointment for?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please choose an option below to proceed with government OPD booking.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // Option 1: Myself
                      _buildOptionCard(
                        id: 'myself',
                        title: 'Booking for Myself',
                        subtitle: 'I am the primary patient receiving OPD consultation.',
                        icon: Icons.person_rounded,
                      ),

                      const SizedBox(height: 14),

                      // Option 2: Someone Else (Caregiver Mode)
                      _buildOptionCard(
                        id: 'someone_else',
                        title: 'Booking for Someone Else',
                        subtitle: 'I am a caregiver booking for a parent, child, or dependent.',
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
  }

  // Ministry of Health Sri Lanka Official Trust Banner
  Widget _buildTrustBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.6),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.health_and_safety_outlined, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            'Ministry of Health Sri Lanka • Free OPD E-Channeling',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Segmented 5-Step Progress Stepper
  Widget _buildSegmentedStepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Step 1 of 5: Patient Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Next: Hospital',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
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
              ? AppColors.primary
              : isCompleted
                  ? AppColors.statusGreen
                  : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // Placeholder prompt when nothing is selected yet
  Widget _buildSelectionPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: const [
          Icon(Icons.touch_app_outlined, color: AppColors.primary, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Select one of the two options above to enter patient details and proceed.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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
          // Soft tint when selected so it clearly pops
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.textDark.withValues(alpha: 0.03),
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
                color: isSelected ? AppColors.primaryLight : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Pre-filled Card for Primary Patient (Myself)
  Widget _buildMyselfProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
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
                children: const [
                  Icon(Icons.verified_user_rounded, color: AppColors.statusGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Verified Profile Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              // User Control: Change details hint
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile details are linked to your NIC account.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          _buildInfoRow('Full Name:', 'Sandeepani Perera'),
          const SizedBox(height: 10),
          _buildInfoRow('National ID (NIC):', '200164801234'),
          const SizedBox(height: 10),
          _buildInfoRow('Mobile Phone:', '+94 77 123 4567'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Appointment token & queue SMS will be sent to your registered mobile number.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.3),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  // Dynamic Caregiver Form
  Widget _buildCaregiverForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.statusOrangeLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.statusOrange.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.edit_note_rounded, color: AppColors.statusOrange, size: 22),
                SizedBox(width: 8),
                Text(
                  'Patient Information (Dependent)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: AppColors.border),

            // Quick Select from Registered Dependents
            StreamBuilder<List<CaregiverPatientModel>>(
              stream: _caregiverService.streamCaregiverPatients(_currentUserId),
              builder: (context, snapshot) {
                final dependents = snapshot.data ?? [];
                if (dependents.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved Family Members (Tap to auto-fill)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: dependents.map((dep) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ActionChip(
                              avatar: const Icon(Icons.person, size: 14, color: AppColors.primary),
                              label: Text(
                                '${dep.patientName} (${dep.relationship})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                              onPressed: () {
                                setState(() {
                                  _nameController.text = dep.patientName;
                                  _nicController.text = dep.patientNic;
                                  if (_relationships.contains(dep.relationship)) {
                                    _selectedRelationship = dep.relationship;
                                  } else {
                                    _selectedRelationship = 'Other';
                                  }
                                  _selectedPriority = dep.priority;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            const Text('Patient Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('e.g., Sunil Perera', Icons.person_outline),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
            ),
            const SizedBox(height: 14),

            const Text('NIC / Birth Certificate No *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nicController,
              decoration: _inputDecoration('e.g., 195812345678', Icons.badge_outlined),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter NIC or Birth Cert No' : null,
            ),
            const SizedBox(height: 14),

            const Text('Relationship to Patient *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: _inputDecoration('', Icons.people_outline),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRelationship = val);
              },
            ),
            const SizedBox(height: 16),

            const Text('Special Priority Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip('normal', 'Standard', Icons.accessibility_new),
                _buildPriorityChip('elderly', 'Elderly (60+)', Icons.elderly),
                _buildPriorityChip('disabled', 'Wheelchair', Icons.accessible),
                _buildPriorityChip('pregnant', 'Maternity', Icons.pregnant_woman),
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
          Icon(icon, size: 14, color: isSelected ? AppColors.surface : AppColors.textDark),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.surface : AppColors.textDark)),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (selected) {
        if (selected) setState(() => _selectedPriority = value);
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final isOptionSelected = _bookingMode != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
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
              backgroundColor: isOptionSelected ? AppColors.primary : AppColors.border,
              foregroundColor: isOptionSelected ? AppColors.surface : AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Hospital Selection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOptionSelected ? AppColors.surface : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isOptionSelected ? AppColors.surface : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}