import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
import '../../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'clinic_selection_screen.dart';

class HospitalSelectionScreen extends StatefulWidget {
  final bool isCaregiverBooking;
  final String patientName;
  final String patientNic;
  final String relationship;
  final String priority;

  const HospitalSelectionScreen({
    super.key,
    this.isCaregiverBooking = false,
    this.patientName = 'Patient',
    this.patientNic = 'N/A',
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  State<HospitalSelectionScreen> createState() => _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> {
  late List<GovernmentHospital> _allHospitals;
  late List<GovernmentHospital> _filteredHospitals;
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<QuerySnapshot>? _hospitalsSub;
  StreamSubscription<QuerySnapshot>? _departmentsSub;
  final Map<String, List<OpdClinic>> _hospitalClinics = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastHospitalDocs = [];

  @override
  void initState() {
    super.initState();
    _allHospitals = GovernmentHospital.getSampleHospitals();
    _filteredHospitals = List.from(_allHospitals);
    _startRealtimeListeners();
  }

  void _startRealtimeListeners() {
    // 1. Listen to departments collection for custom clinics
    _departmentsSub = FirebaseFirestore.instance
        .collection('departments')
        .snapshots()
        .listen((snapshot) {
      final Map<String, List<OpdClinic>> clinicMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;

        final hospName = (data['hospitalName'] ?? '').toString().trim().toLowerCase();
        final hospId = (data['hospitalId'] ?? '').toString().trim().toLowerCase();
        final deptId = doc.id;
        final name = (data['name'] ?? 'OPD Clinic').toString();
        final room = (data['roomNumber'] ?? 'OPD Room 01').toString();
        final hours = (data['operatingHours'] ?? '8:00 AM - 12:00 PM').toString();

        IconData icon = Icons.medical_services_outlined;
        final lowerName = name.toLowerCase();
        if (lowerName.contains('pediatric') || lowerName.contains('child')) {
          icon = Icons.child_care_outlined;
        } else if (lowerName.contains('ortho') || lowerName.contains('bone')) {
          icon = Icons.accessibility_new_outlined;
        } else if (lowerName.contains('ent') || lowerName.contains('ear')) {
          icon = Icons.hearing_outlined;
        } else if (lowerName.contains('derma') || lowerName.contains('skin')) {
          icon = Icons.healing_outlined;
        } else if (lowerName.contains('cardio') || lowerName.contains('heart')) {
          icon = Icons.favorite_outline_rounded;
        }

        final clinic = OpdClinic(
          id: deptId,
          name: name,
          hours: hours,
          icon: icon,
          isOpen: true,
          roomNumber: room,
        );

        if (hospName.isNotEmpty) {
          clinicMap.putIfAbsent(hospName, () => []).add(clinic);
        }
        if (hospId.isNotEmpty) {
          clinicMap.putIfAbsent(hospId, () => []).add(clinic);
        }
      }

      if (mounted) {
        setState(() {
          _hospitalClinics.clear();
          _hospitalClinics.addAll(clinicMap);
          _mergeHospitals();
        });
      }
    });

    // 2. Listen to hospitals collection for dynamic government hospitals
    _hospitalsSub = FirebaseFirestore.instance
        .collection('hospitals')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _lastHospitalDocs = snapshot.docs;
          _mergeHospitals();
        });
      }
    });
  }

  void _mergeHospitals([List<QueryDocumentSnapshot<Map<String, dynamic>>>? firestoreDocs]) {
    if (firestoreDocs != null) {
      _lastHospitalDocs = firestoreDocs;
    }

    final Map<String, GovernmentHospital> map = {};
    final Set<String> disabledHospitalKeys = {};

    for (var doc in _lastHospitalDocs) {
      final data = doc.data();
      final id = doc.id.toLowerCase();
      final name = (data['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final bool isActive;
      if (data['isActive'] is bool) {
        isActive = data['isActive'] as bool;
      } else if (data['isOpdAvailable'] is bool) {
        isActive = data['isOpdAvailable'] as bool;
      } else {
        isActive = true;
      }

      if (!isActive) {
        disabledHospitalKeys.add(id);
        disabledHospitalKeys.add(cleanName);
        continue;
      }

      // Check for attached custom clinics
      final customClinics = _hospitalClinics[name.toLowerCase()] ??
          _hospitalClinics[id] ??
          _hospitalClinics[(data['hospitalId'] ?? '').toString().toLowerCase()];

      map[id] = GovernmentHospital.fromMap(
        data,
        doc.id,
        customClinics: customClinics,
      );
    }

    // Add default hospitals only if they were NOT explicitly disabled in Firestore
    for (var def in GovernmentHospital.getSampleHospitals()) {
      final defId = def.id.toLowerCase();
      final defClean = def.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final isExplicitlyDisabled = disabledHospitalKeys.contains(defId) ||
          disabledHospitalKeys.any((k) => defClean.contains(k) || k.contains(defClean));

      if (isExplicitlyDisabled) {
        continue;
      }

      final alreadyExists = map.values.any((h) {
        final hClean = h.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        return h.id.toLowerCase() == defId || hClean.contains(defClean) || defClean.contains(hClean);
      });
      if (!alreadyExists && !map.containsKey(defId)) {
        map[defId] = def;
      }
    }

    _allHospitals = map.values.where((h) => h.isOpdAvailable).toList();
    _filterHospitals(_searchController.text);
  }

  void _filterHospitals(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHospitals = List.from(_allHospitals);
      } else {
        final q = query.toLowerCase().trim();
        _filteredHospitals = _allHospitals
            .where((h) =>
                h.name.toLowerCase().contains(q) ||
                h.location.toLowerCase().contains(q) ||
                h.district.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _hospitalsSub?.cancel();
    _departmentsSub?.cancel();
    _searchController.dispose();
    super.dispose();
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
              AppTranslations.tr('chooseHospital'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // Segmented 5-Step Stepper (Step 2 of 5)
                  _buildSegmentedStepper(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Context Badge
                          _buildPatientContextBadge(),

                          const SizedBox(height: 12),

                          Text(
                            AppTranslations.tr('chooseHospital'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.tr('chooseHospitalSubtitle'),
                            style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.3),
                          ),
                          const SizedBox(height: 16),

                          // Search Bar with Clean Fill
                          _buildSearchBar(),

                          const SizedBox(height: 16),

                          // Hospitals List
                          Expanded(
                            child: _filteredHospitals.isEmpty
                                ? _buildEmptyState()
                                : ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _filteredHospitals.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final hospital = _filteredHospitals[index];
                                      return _buildHospitalCard(hospital);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Segmented 5-Step Progress Stepper (Step 2 Active, Step 1 Completed)
  Widget _buildSegmentedStepper() {
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
                AppTranslations.tr('step2Title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                AppTranslations.tr('nextClinic'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segments with interactive navigation
          Row(
            children: [
              _buildStepSegment(
                step: 1,
                label: 'Patient',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 2,
                label: 'Hospital',
                isActive: true,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 3,
                label: 'Clinic',
                isActive: false,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 4,
                label: 'Date',
                isActive: false,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 5,
                label: 'Slot',
                isActive: false,
                isCompleted: false,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final color = isActive
        ? AppColors.accentColor
        : isCompleted
            ? AppColors.statusGreen
            : AppColors.cardBorder;

    return Expanded(
      child: Tooltip(
        message: 'Step $step: $label${isCompleted ? ' (Tap to edit)' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$step. $label',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.accentColor : (isCompleted ? AppColors.headingText : AppColors.bodyText),
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
  }

  // HCI Context Badge: Reminds the user who the booking is for
  Widget _buildPatientContextBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            widget.isCaregiverBooking ? Icons.family_restroom_rounded : Icons.person_rounded,
            size: 16,
            color: AppColors.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Booking for: ${widget.patientName} (${widget.relationship})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.headingText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.priority != 'normal') ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusOrangeLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.priority.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusOrange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Clean Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterHospitals,
        style: TextStyle(fontSize: 14, color: AppColors.headingText),
        decoration: InputDecoration(
          hintText: AppTranslations.tr('searchHospital'),
          hintStyle: TextStyle(fontSize: 13, color: AppColors.bodyText),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.bodyText, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.bodyText),
                  onPressed: () {
                    _searchController.clear();
                    _filterHospitals('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // Polished Hospital Card
  Widget _buildHospitalCard(GovernmentHospital hospital) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'ClinicSelection'),
            builder: (context) => ClinicSelectionScreen(
              hospital: hospital,
              isCaregiverBooking: widget.isCaregiverBooking,
              patientName: widget.patientName,
              patientNic: widget.patientNic,
              relationship: widget.relationship,
              priority: widget.priority,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_hospital_rounded,
                color: AppColors.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Hospital Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.bodyText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.location,
                          style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status Badges (Wrap prevents overflow on narrow screens)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.statusGreenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.statusGreen),
                            const SizedBox(width: 4),
                            Text(
                              AppTranslations.tr('openToday'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.innerCardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '${hospital.clinics.length} ${AppTranslations.tr('clinicsCount')}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            // Forward Chevron Arrow
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.bodyText,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.bodyText.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No Government Hospitals Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
            ),
            const SizedBox(height: 6),
            Text(
              'Please try searching with another hospital name, city, or district.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}