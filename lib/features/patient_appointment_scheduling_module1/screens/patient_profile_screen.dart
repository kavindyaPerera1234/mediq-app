import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../backend/backend.dart';
import 'senior_mode_settings_screen.dart';
import '../admin/screens/hospital_admin_dashboard.dart';

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

  final String _currentUserId = 'user_sandeepani_001';
  final String _currentPatientNic = '200164801234';
  String _appointmentFilter = 'upcoming'; // 'upcoming' or 'past'

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getPatientProfile(_currentPatientNic);
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
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Patient Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),

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
                          final updated = PatientProfileModel(
                            patientId: _profile.patientId,
                            fullName: nameController.text.trim(),
                            nic: _profile.nic,
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            bloodGroup: bloodGroup,
                            dateOfBirth: _profile.dateOfBirth,
                            gender: _profile.gender,
                            emergencyContactName: emergencyNameController.text.trim(),
                            emergencyContactPhone: emergencyPhoneController.text.trim(),
                            isSeniorModeEnabled: _profile.isSeniorModeEnabled,
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
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Family Member / Dependent',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Full Name'),
                    TextField(
                      controller: nameCtrl,
                      decoration: _inputDecoration('e.g. Sunil Perera'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('National ID (NIC) / Birth Reg'),
                    TextField(
                      controller: nicCtrl,
                      decoration: _inputDecoration('e.g. 195812345678'),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Relationship'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: rel,
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
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: prio,
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
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Patient Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileDialog,
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
                // 1. Patient Profile Card
                _buildProfileHeaderCard(),
                const SizedBox(height: 16),

                // 2. Dependents / Caregiver Patients (Live Stream)
                _buildCaregiversSection(),
                const SizedBox(height: 16),

                // 3. My Booked Appointments History (Live Stream)
                _buildAppointmentsSection(),
                const SizedBox(height: 16),

                // 4. Accessibility Settings Card
                _buildAccessibilityTile(),
                const SizedBox(height: 12),

                // 5. Hospital Admin Console Card
                _buildAdminConsoleTile(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _profile.fullName.isNotEmpty ? _profile.fullName[0] : 'P',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _profile.bloodGroup,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIC: ${_profile.nic}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profile.phone,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn('GENDER', _profile.gender),
              Container(width: 1, height: 24, color: AppColors.border),
              _buildInfoColumn('DOB', _profile.dateOfBirth),
              Container(width: 1, height: 24, color: AppColors.border),
              _buildInfoColumn('EMERGENCY', _profile.emergencyContactName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  // Live StreamBuilder for Caregiver Dependents
  Widget _buildCaregiversSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Family Dependents',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Member', style: TextStyle(fontSize: 12)),
                onPressed: _showAddCaregiverDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Family members registered under your care for easy 1-tap booking.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'No dependents added yet. Tap "+ Add Member" above.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dep.patientName} (${dep.relationship})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                Text('NIC: ${dep.patientNic}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          onPressed: () => _caregiverService.deleteCaregiverPatient(dep.id),
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

  // Live StreamBuilder for My Booked Appointments
  Widget _buildAppointmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.confirmation_number_outlined, color: AppColors.statusOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'My Active OPD Tokens & Appointments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Live appointments synced with Ministry of Health Cloud.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                if (app.status == 'cancelled') return false;
                return app.appointmentDate.compareTo(todayStr) >= 0;
              }).toList();

              final pastList = list.where((app) {
                if (app.status == 'cancelled') return true;
                return app.appointmentDate.compareTo(todayStr) < 0;
              }).toList();

              final displayedList = _appointmentFilter == 'upcoming' ? upcomingList : pastList;

              return Column(
                children: [
                  // Segmented Filter Tabs: Upcoming vs Past History
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
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
                                color: _appointmentFilter == 'upcoming' ? AppColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _appointmentFilter == 'upcoming'
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Upcoming Active (${upcomingList.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _appointmentFilter == 'upcoming' ? AppColors.primary : AppColors.textSecondary,
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
                                color: _appointmentFilter == 'past' ? AppColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _appointmentFilter == 'past'
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Past History (${pastList.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _appointmentFilter == 'past' ? AppColors.primary : AppColors.textSecondary,
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
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _appointmentFilter == 'upcoming'
                              ? 'No upcoming appointments. Book your next visit in Tab 1!'
                              : 'No past appointments found.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...displayedList.map((app) {
                      final isConfirmed = app.status == 'confirmed';
                      final isUpcoming = isConfirmed && app.appointmentDate.compareTo(todayStr) >= 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
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
                                            color: AppColors.primaryLight.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            app.tokenCode,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.border.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            app.roomNumber,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isUpcoming
                                                ? AppColors.statusGreen.withValues(alpha: 0.12)
                                                : (app.status == 'cancelled'
                                                    ? AppColors.error.withValues(alpha: 0.12)
                                                    : Colors.blueGrey.withValues(alpha: 0.12)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isUpcoming
                                                ? 'ACTIVE'
                                                : (app.status == 'cancelled' ? 'CANCELLED' : 'COMPLETED'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isUpcoming
                                                  ? AppColors.statusGreen
                                                  : (app.status == 'cancelled' ? AppColors.error : Colors.blueGrey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  app.departmentName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${app.hospitalName} • ${app.appointmentDate} • ${app.timeSlot}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      app.isCaregiverBooking ? Icons.family_restroom_rounded : Icons.person_outline_rounded,
                                      size: 13,
                                      color: app.isCaregiverBooking ? AppColors.statusOrange : AppColors.primary,
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
                                          color: app.isCaregiverBooking ? AppColors.statusOrange : AppColors.primary,
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
                                      child: const Text(
                                        'View Pass →',
                                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
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

  Widget _buildAccessibilityTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SeniorModeSettingsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.accessibility_new_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Senior Accessibility Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enlarged fonts, high contrast & voice audio assistance',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminConsoleTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HospitalAdminDashboard()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hospital Admin Console',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Configure hospitals, OPD clinics, and 25-patient slot capping',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showTokenPassModal(AppointmentModel app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isConfirmed = app.status == 'confirmed';
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Digital Pass Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OPD Digital Token Pass',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ESTIMATED TOKEN NUMBER',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.tokenCode,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Room: ${app.roomNumber}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details
              _buildModalDetailRow('Hospital', app.hospitalName),
              const Divider(height: 16, color: AppColors.border),
              _buildModalDetailRow('Specialty Clinic', app.departmentName),
              const Divider(height: 16, color: AppColors.border),
              _buildModalDetailRow('Date', app.appointmentDate),
              const Divider(height: 16, color: AppColors.border),
              _buildModalDetailRow('Time Slot', app.timeSlot),
              const Divider(height: 16, color: AppColors.border),
              _buildModalDetailRow('Patient Name', app.patientName),
              const Divider(height: 16, color: AppColors.border),
              _buildModalDetailRow('NIC', app.patientNic),
              const Divider(height: 16, color: AppColors.border),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
