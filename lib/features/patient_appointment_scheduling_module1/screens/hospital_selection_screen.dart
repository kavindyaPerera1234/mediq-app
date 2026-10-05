import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
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
    this.patientName = 'Sandeepani Perera',
    this.patientNic = '200164801234',
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

  @override
  void initState() {
    super.initState();
    _allHospitals = GovernmentHospital.getSampleHospitals();
    _filteredHospitals = List.from(_allHospitals);
  }

  void _filterHospitals(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHospitals = List.from(_allHospitals);
      } else {
        _filteredHospitals = _allHospitals
            .where((h) =>
                h.name.toLowerCase().contains(query.toLowerCase()) ||
                h.location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppAccessibility.isHighContrastMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: const Text(
              'Select Government Hospital',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                            'Choose OPD Hospital',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select the closest national or teaching hospital for consultation.',
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
                'Step 2 of 5: Hospital Selection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                'Next: OPD Clinic',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segments: Segment 1 (Green / Completed), Segment 2 (Blue / Active), 3-5 (Grey)
          Row(
            children: [
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: true, isCompleted: false),
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
          hintText: 'Search hospital name, city, or district...',
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
                          children: const [
                            Icon(Icons.check_circle_rounded, size: 11, color: AppColors.statusGreen),
                            SizedBox(width: 4),
                            Text(
                              'Open Today',
                              style: TextStyle(
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
                          '${hospital.clinics.length} Clinics',
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