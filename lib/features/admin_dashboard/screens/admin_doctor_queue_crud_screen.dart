import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/queue_service.dart';

class AdminDoctorQueueCrudScreen extends StatefulWidget {
  final String? initialSessionId;

  const AdminDoctorQueueCrudScreen({
    super.key,
    this.initialSessionId,
  });

  @override
  State<AdminDoctorQueueCrudScreen> createState() => _AdminDoctorQueueCrudScreenState();
}

class _AdminDoctorQueueCrudScreenState extends State<AdminDoctorQueueCrudScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QueueService _queueService = QueueService();

  // Queue Tokens Filter & Search
  String _tokenSearchQuery = '';
  String _tokenStatusFilter = 'all'; // all, waiting, called, in_consultation, on_hold, completed, missed, emergency

  // Consultations Filter & Search
  String _consultationSearchQuery = '';
  String _consultationStatusFilter = 'all'; // all, in_progress, completed

  final TextEditingController _tokenSearchCtrl = TextEditingController();
  final TextEditingController _consultationSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenSearchCtrl.dispose();
    _consultationSearchCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Queue & Consultations (CRUD)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              'Module 4 • Doctor Queue Management Console',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Queue Tokens'),
            Tab(icon: Icon(Icons.medical_services_rounded, size: 20), text: 'Consultations'),
            Tab(icon: Icon(Icons.schedule_rounded, size: 20), text: 'Sessions & Delays'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQueueTokensTab(),
          _buildConsultationsTab(),
          _buildSessionsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: QUEUE TOKENS CRUD (Patient Queue Entries)
  // ===========================================================================

  Widget _buildQueueTokensTab() {
    return Column(
      children: [
        // Top Toolbar: Search + Add Token Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tokenSearchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by token, patient name, or NIC...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _tokenSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _tokenSearchCtrl.clear();
                                  setState(() => _tokenSearchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) => setState(() => _tokenSearchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Issue Token',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => _showCreateQueueTokenDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTokenFilterPill('all', 'All Tokens'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('waiting', 'Waiting'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('called', 'Called'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('in_consultation', 'In Consultation'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('on_hold', 'On Hold'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('completed', 'Completed'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('missed', 'Skipped'),
                    const SizedBox(width: 6),
                    _buildTokenFilterPill('emergency', 'Emergency Priority'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Live Real-Time Queue Entries Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection(AppConstants.queueEntriesCollection)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading tokens: ${snapshot.error}',
                      style: GoogleFonts.inter(color: AppColors.error)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;

              // Filter by status
              if (_tokenStatusFilter == 'emergency') {
                docs = docs.where((d) => (d.data()['priority'] ?? '') == 'emergency').toList();
              } else if (_tokenStatusFilter != 'all') {
                docs = docs.where((d) {
                  final st = (d.data()['status'] ?? 'waiting').toString().toLowerCase();
                  return st == _tokenStatusFilter;
                }).toList();
              }

              // Search Filter
              if (_tokenSearchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data();
                  final token = (data['tokenCode'] ?? data['tokenNumber'] ?? '').toString().toLowerCase();
                  final name = (data['patientName'] ?? '').toString().toLowerCase();
                  final nic = (data['patientNic'] ?? '').toString().toLowerCase();
                  return token.contains(_tokenSearchQuery) ||
                      name.contains(_tokenSearchQuery) ||
                      nic.contains(_tokenSearchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No queue tokens found matching criteria',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Patient to Queue'),
                        onPressed: () => _showCreateQueueTokenDialog(context),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _buildQueueTokenCard(doc.id, doc.data());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTokenFilterPill(String key, String label) {
    final isSelected = _tokenStatusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _tokenStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueTokenCard(String docId, Map<String, dynamic> data) {
    final token = data['tokenCode'] ?? data['tokenNumber'] ?? 'A-001';
    final patientName = data['patientName'] ?? 'Unknown Patient';
    final patientNic = data['patientNic'] ?? data['patientId'] ?? '';
    final status = (data['status'] ?? 'waiting').toString().toLowerCase();
    final priority = (data['priority'] ?? 'normal').toString().toLowerCase();
    final queueSessionId = data['queueSessionId'] ?? 'General';
    final isEmergency = priority == 'emergency';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency
              ? Colors.red.shade400
              : status == 'called'
                  ? AppColors.primary
                  : AppColors.border,
          width: isEmergency || status == 'called' ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isEmergency
                        ? Colors.red.shade50
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEmergency ? Colors.red.shade300 : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    token.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isEmergency ? Colors.red.shade700 : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (patientNic.isNotEmpty) ...[
                            Text(
                              'NIC: $patientNic',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                          Text(
                            'Session: $queueSessionId',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emergency_rounded, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                'EMERGENCY TRIAGE PRIORITY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // CRUD Actions Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Call Patient (Update)
                if (status == 'waiting' || status == 'on_hold')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 16),
                      label: Text(
                        'Call',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _callPatient(docId, token.toString(), queueSessionId.toString()),
                    ),
                  ),

                // Start Consultation (Update)
                if (status == 'called') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: Text(
                        'Start Consult',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _startConsultationForToken(docId, data),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Complete Consultation (Update)
                if (status == 'in_consultation') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(
                        'Complete',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _completeConsultationForToken(docId, data),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                const SizedBox(width: 6),

                // Hold / Resume Button (Update)
                if (status == 'called' || status == 'waiting')
                  IconButton(
                    tooltip: 'Put on Hold',
                    icon: const Icon(Icons.pause_circle_outline_rounded, color: Colors.orange, size: 22),
                    onPressed: () => _holdPatient(docId, token.toString()),
                  )
                else if (status == 'on_hold')
                  IconButton(
                    tooltip: 'Resume to Waiting',
                    icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.green, size: 22),
                    onPressed: () => _resumePatient(docId, token.toString()),
                  ),

                // Toggle Emergency Priority (Update)
                IconButton(
                  tooltip: isEmergency ? 'Remove Emergency Priority' : 'Set Emergency Priority',
                  icon: Icon(
                    Icons.emergency_rounded,
                    color: isEmergency ? Colors.red : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () => _toggleEmergencyPriority(docId, isEmergency),
                ),

                // Edit Entry (Update)
                IconButton(
                  tooltip: 'Edit Patient Entry',
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                  onPressed: () => _showEditQueueTokenDialog(context, docId, data),
                ),

                // Skip / Missed (Soft Delete)
                if (status != 'completed' && status != 'missed')
                  IconButton(
                    tooltip: 'Skip / No-Show',
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.amber, size: 22),
                    onPressed: () => _skipPatient(docId, token.toString()),
                  ),

                // Permanent Delete (Hard Delete)
                IconButton(
                  tooltip: 'Delete Token Permanently',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteQueueToken(context, docId, token.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'waiting':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'WAITING';
        break;
      case 'called':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'CALLED';
        break;
      case 'in_consultation':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        label = 'IN CONSULTATION';
        break;
      case 'on_hold':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'ON HOLD';
        break;
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'COMPLETED';
        break;
      case 'missed':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'SKIPPED';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: CONSULTATIONS CRUD (Doctor Clinical Sessions)
  // ===========================================================================

  Widget _buildConsultationsTab() {
    return Column(
      children: [
        // Top Toolbar: Search + Add Consultation Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _consultationSearchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by doctor, patient, or notes...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _consultationSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _consultationSearchCtrl.clear();
                                  setState(() => _consultationSearchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) => setState(() => _consultationSearchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'New Consult',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => _showCreateConsultationDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Pills
              Row(
                children: [
                  _buildConsultationFilterPill('all', 'All Consultations'),
                  const SizedBox(width: 8),
                  _buildConsultationFilterPill('in_progress', 'In Progress'),
                  const SizedBox(width: 8),
                  _buildConsultationFilterPill('completed', 'Completed'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Live Real-Time Consultations Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection(AppConstants.consultationsCollection)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading consultations: ${snapshot.error}',
                      style: GoogleFonts.inter(color: AppColors.error)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;

              // Filter by status
              if (_consultationStatusFilter != 'all') {
                docs = docs.where((d) {
                  final st = (d.data()['status'] ?? 'in_progress').toString().toLowerCase();
                  return st == _consultationStatusFilter;
                }).toList();
              }

              // Search Query
              if (_consultationSearchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data();
                  final docName = (data['doctorId'] ?? data['staffId'] ?? '').toString().toLowerCase();
                  final patName = (data['patientName'] ?? data['patientId'] ?? '').toString().toLowerCase();
                  final notes = (data['notes'] ?? '').toString().toLowerCase();
                  return docName.contains(_consultationSearchQuery) ||
                      patName.contains(_consultationSearchQuery) ||
                      notes.contains(_consultationSearchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No consultation records found',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Start New Consultation'),
                        onPressed: () => _showCreateConsultationDialog(context),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _buildConsultationCard(doc.id, doc.data());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationFilterPill(String key, String label) {
    final isSelected = _consultationStatusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _consultationStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard(String docId, Map<String, dynamic> data) {
    final doctor = data['doctorId'] ?? data['staffId'] ?? 'Dr. S. Perera';
    final patient = data['patientName'] ?? data['patientId'] ?? 'Patient';
    final dept = data['departmentId'] ?? 'General Medicine';
    final status = (data['status'] ?? 'in_progress').toString().toLowerCase();
    final notes = data['notes'] ?? 'No clinical notes recorded yet.';
    final isCompleted = status == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.teal.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                            size: 18,
                            color: isCompleted ? Colors.green : Colors.teal,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Patient: $patient',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Attending: $doctor • $dept',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? Colors.green.shade800 : Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clinical Notes Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLINICAL NOTES & DIAGNOSIS:',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  notes.toString().isNotEmpty ? notes.toString() : 'No notes entered.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Action Buttons Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Notes (Update)
                TextButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Edit Notes'),
                  onPressed: () => _showEditConsultationNotesDialog(context, docId, notes.toString()),
                ),
                const SizedBox(width: 8),

                // Mark Complete (Update)
                if (!isCompleted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _completeConsultationRecord(docId, data),
                  ),

                // Delete Consultation (Delete)
                IconButton(
                  tooltip: 'Delete Consultation Record',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteConsultation(context, docId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: OPD SESSIONS & DELAY BROADCASTS CRUD
  // ===========================================================================

  Widget _buildSessionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OPD Clinic Queue Sessions',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _showCreateQueueSessionDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Sessions Stream
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection(AppConstants.queueSessionsCollection).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: Text('No active queue sessions configured.')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _buildSessionCrudCard(doc.id, doc.data());
                },
              );
            },
          ),

          const SizedBox(height: 28),

          // Delay Broadcast Records
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active OPD Delay Alerts',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                icon: const Icon(Icons.broadcast_on_personal_rounded, size: 16),
                label: const Text('Broadcast Delay'),
                onPressed: () => _showBroadcastDelayDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Delay Updates Stream
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection(AppConstants.delayUpdatesCollection)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'No OPD delays active. Clinic operating on schedule.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final reason = data['reason'] ?? data['delayReason'] ?? 'Doctor delay';
                  final mins = data['additionalMinutes'] ?? data['delayMinutes'] ?? 15;
                  final sessId = data['queueSessionId'] ?? 'General';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+$mins min delay ($sessId)',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                              ),
                              Text(
                                reason.toString(),
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete / Dismiss Delay Notice',
                          icon: const Icon(Icons.close_rounded, color: Colors.amber, size: 20),
                          onPressed: () => _deleteDelayUpdate(doc.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCrudCard(String sessionId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final currentToken = data['currentToken'] ?? data['currentTokenNumber'] ?? 'A-001';
    final dept = data['departmentId'] ?? 'OPD';
    final hosp = data['hospitalId'] ?? 'NHSL';
    final isPaused = status == 'paused';
    final isDelayed = status == 'delayed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaused
              ? Colors.blueGrey
              : isDelayed
                  ? Colors.amber.shade400
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dept ($hosp)',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Session ID: $sessionId',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaused ? Colors.blueGrey.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaused ? Colors.blueGrey.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Current Serving: ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                currentToken.toString(),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const Spacer(),

              // Pause / Resume (Update)
              IconButton(
                tooltip: isPaused ? 'Resume Session' : 'Pause Session',
                icon: Icon(
                  isPaused ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded,
                  color: isPaused ? Colors.green : Colors.blueGrey,
                  size: 24,
                ),
                onPressed: () => _togglePauseSession(sessionId, isPaused),
              ),

              // Reset / Close Session (Delete/Close)
              IconButton(
                tooltip: 'Reset Session Counters',
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.orange, size: 22),
                onPressed: () => _resetSessionCounters(sessionId),
              ),

              // Delete Session (Hard Delete)
              IconButton(
                tooltip: 'Delete Session Document',
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteSession(context, sessionId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CRUD OPERATIONS: QUEUE TOKENS
  // ===========================================================================

  void _showCreateQueueTokenDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nicCtrl = TextEditingController();
    final tokenCtrl = TextEditingController(text: 'A-${DateTime.now().minute}${DateTime.now().second}');
    String selectedPriority = 'normal';
    String selectedHospital = 'nhsl';
    String selectedDept = 'gen_med';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_task_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Issue Patient Token', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Token Number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Patient Full Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Patient NIC / ID',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'OPD Clinic / Department',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gen_med', child: Text('General Medicine OPD')),
                        DropdownMenuItem(value: 'dept_pediatrics', child: Text('Pediatrics Clinic')),
                        DropdownMenuItem(value: 'dept_cardiology', child: Text('Cardiology Clinic')),
                        DropdownMenuItem(value: 'ortho', child: Text('Orthopedics Clinic')),
                        DropdownMenuItem(value: 'ent', child: Text('ENT Specialty OPD')),
                      ],
                      onChanged: (val) => setDlgState(() => selectedDept = val ?? 'gen_med'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Triage Priority',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                        DropdownMenuItem(value: 'elderly', child: Text('Elderly Priority')),
                        DropdownMenuItem(value: 'pregnant', child: Text('Maternity / Pregnant')),
                        DropdownMenuItem(value: 'disabled', child: Text('Disability / Wheelchair')),
                        DropdownMenuItem(value: 'emergency', child: Text('🚨 Emergency Priority')),
                      ],
                      onChanged: (val) => setDlgState(() => selectedPriority = val ?? 'normal'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final token = tokenCtrl.text.trim();
                    final nic = nicCtrl.text.trim();
                    if (token.isEmpty || name.isEmpty) return;

                    Navigator.pop(dialogCtx);

                    try {
                      final sessionId = AppConstants.defaultQueueSessionId(selectedHospital, selectedDept);
                      final now = FieldValue.serverTimestamp();

                      final newDocRef = _firestore.collection(AppConstants.queueEntriesCollection).doc();
                      await newDocRef.set({
                        'queueEntryId': newDocRef.id,
                        'queueSessionId': sessionId,
                        'tokenCode': token,
                        'tokenNumber': token,
                        'patientName': name,
                        'patientNic': nic,
                        'priority': selectedPriority,
                        'status': 'waiting',
                        'queuePosition': 1,
                        'createdAt': now,
                        'updatedAt': now,
                      });

                      // Log Event
                      await _queueService.createQueueEvent(
                        queueSessionId: sessionId,
                        queueEntryId: newDocRef.id,
                        performedBy: 'admin_console',
                        eventType: 'token_created',
                        newStatus: 'waiting',
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Token $token issued for $name!'), backgroundColor: AppColors.success),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to issue token: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                  child: const Text('Issue Token'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditQueueTokenDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['patientName'] ?? '');
    final nicCtrl = TextEditingController(text: data['patientNic'] ?? '');
    String selectedPriority = data['priority'] ?? 'normal';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Patient Token Entry', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Patient Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nicCtrl,
                    decoration: const InputDecoration(labelText: 'Patient NIC', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                      DropdownMenuItem(value: 'elderly', child: Text('Elderly Priority')),
                      DropdownMenuItem(value: 'pregnant', child: Text('Maternity Priority')),
                      DropdownMenuItem(value: 'disabled', child: Text('Disabled Priority')),
                      DropdownMenuItem(value: 'emergency', child: Text('🚨 Emergency Priority')),
                    ],
                    onChanged: (val) => setDlgState(() => selectedPriority = val ?? 'normal'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    try {
                      await _firestore.collection(AppConstants.queueEntriesCollection).doc(docId).update({
                        'patientName': nameCtrl.text.trim(),
                        'patientNic': nicCtrl.text.trim(),
                        'priority': selectedPriority,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient token updated successfully!'), backgroundColor: AppColors.success),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _callPatient(String docId, String token, String sessionId) async {
    try {
      await _queueService.callSpecificPatient(
        queueEntryId: docId,
        staffUserId: 'admin_master_console',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient $token called!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to call patient: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _holdPatient(String docId, String token) async {
    try {
      await _queueService.holdPatient(queueEntryId: docId, staffUserId: 'admin_console');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token $token placed on hold.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to hold patient: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resumePatient(String docId, String token) async {
    try {
      await _queueService.resumePatient(queueEntryId: docId, staffUserId: 'admin_console');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token $token resumed to waiting list.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume patient: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _skipPatient(String docId, String token) async {
    try {
      await _queueService.skipPatient(queueEntryId: docId, staffUserId: 'admin_console', reason: 'Absent / No-Show');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token $token marked as skipped (No-Show).'), backgroundColor: Colors.amber.shade900),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to skip: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleEmergencyPriority(String docId, bool currentlyEmergency) async {
    try {
      await _firestore.collection(AppConstants.queueEntriesCollection).doc(docId).update({
        'priority': currentlyEmergency ? 'normal' : 'emergency',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyEmergency ? 'Priority set to Normal.' : '🚨 Emergency priority assigned!'),
          backgroundColor: currentlyEmergency ? Colors.blueGrey : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update priority: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmDeleteQueueToken(BuildContext context, String docId, String token) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Queue Token?'),
        content: Text('Are you sure you want to permanently delete token "$token"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestore.collection(AppConstants.queueEntriesCollection).doc(docId).delete();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Token $token deleted.'), backgroundColor: AppColors.error),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CRUD OPERATIONS: CONSULTATIONS
  // ===========================================================================

  void _showCreateConsultationDialog(BuildContext context) {
    final patientCtrl = TextEditingController();
    final doctorCtrl = TextEditingController(text: 'Dr. S. Perera');
    final roomCtrl = TextEditingController(text: 'OPD Room 01');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Start Clinical Consultation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patientCtrl,
                  decoration: const InputDecoration(labelText: 'Patient Name / ID', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(labelText: 'Attending Doctor', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Examination Room', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Initial Clinical Notes / Vitals', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                final patient = patientCtrl.text.trim();
                if (patient.isEmpty) return;

                Navigator.pop(dialogCtx);
                try {
                  final now = FieldValue.serverTimestamp();
                  final ref = _firestore.collection(AppConstants.consultationsCollection).doc();
                  await ref.set({
                    'consultationId': ref.id,
                    'patientName': patient,
                    'patientId': patient,
                    'doctorId': doctorCtrl.text.trim(),
                    'staffId': doctorCtrl.text.trim(),
                    'room': roomCtrl.text.trim(),
                    'departmentId': 'gen_med',
                    'hospitalId': 'nhsl',
                    'notes': notesCtrl.text.trim(),
                    'status': 'in_progress',
                    'startedAt': now,
                    'createdAt': now,
                    'updatedAt': now,
                  });

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Consultation started!'), backgroundColor: Colors.teal),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to start consultation: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Start Consultation'),
            ),
          ],
        );
      },
    );
  }

  void _showEditConsultationNotesDialog(BuildContext context, String docId, String existingNotes) {
    final notesCtrl = TextEditingController(text: existingNotes);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Clinical Notes & Diagnosis'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter clinical observations, prescription, and advice...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestore.collection(AppConstants.consultationsCollection).doc(docId).update({
                  'notes': notesCtrl.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clinical notes updated successfully!'), backgroundColor: Colors.teal),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save notes: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  Future<void> _startConsultationForToken(String entryDocId, Map<String, dynamic> data) async {
    try {
      final now = FieldValue.serverTimestamp();
      final patName = data['patientName'] ?? 'Patient';

      // 1. Create Consultation doc
      final ref = _firestore.collection(AppConstants.consultationsCollection).doc();
      await ref.set({
        'consultationId': ref.id,
        'queueEntryId': entryDocId,
        'patientName': patName,
        'patientId': data['patientId'] ?? '',
        'doctorId': 'Dr. S. Perera',
        'staffId': 'Dr. S. Perera',
        'departmentId': 'gen_med',
        'hospitalId': 'nhsl',
        'notes': 'Consultation commenced via OPD Console.',
        'status': 'in_progress',
        'startedAt': now,
        'createdAt': now,
        'updatedAt': now,
      });

      // 2. Update queue entry
      await _firestore.collection(AppConstants.queueEntriesCollection).doc(entryDocId).update({
        'status': 'in_consultation',
        'consultationStartedAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation started for $patName!'), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start consultation: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _completeConsultationForToken(String entryDocId, Map<String, dynamic> data) async {
    try {
      final now = FieldValue.serverTimestamp();
      final patName = data['patientName'] ?? 'Patient';

      await _firestore.collection(AppConstants.queueEntriesCollection).doc(entryDocId).update({
        'status': 'completed',
        'completedAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation completed for $patName!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete consultation: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _completeConsultationRecord(String docId, Map<String, dynamic> data) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _firestore.collection(AppConstants.consultationsCollection).doc(docId).update({
        'status': 'completed',
        'completedAt': now,
        'updatedAt': now,
      });

      // Sync queue entry if attached
      final entryId = data['queueEntryId'];
      if (entryId != null && entryId.toString().isNotEmpty) {
        try {
          await _firestore.collection(AppConstants.queueEntriesCollection).doc(entryId.toString()).update({
            'status': 'completed',
            'completedAt': now,
            'updatedAt': now,
          });
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation marked as completed!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmDeleteConsultation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Consultation Record?'),
        content: const Text('Are you sure you want to permanently delete this clinical consultation record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestore.collection(AppConstants.consultationsCollection).doc(docId).delete();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Consultation deleted.'), backgroundColor: AppColors.error),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CRUD OPERATIONS: SESSIONS & DELAYS
  // ===========================================================================

  void _showCreateQueueSessionDialog(BuildContext context) {
    final sessIdCtrl = TextEditingController(text: 'nhsl_gen_med_${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');
    final tokenCtrl = TextEditingController(text: 'A-001');
    String selectedHosp = 'nhsl';
    String selectedDept = 'gen_med';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Initialize New Queue Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sessIdCtrl,
              decoration: const InputDecoration(labelText: 'Queue Session ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(labelText: 'Starting Token Number', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final now = FieldValue.serverTimestamp();
                final sId = sessIdCtrl.text.trim();
                await _firestore.collection(AppConstants.queueSessionsCollection).doc(sId).set({
                  'queueSessionId': sId,
                  'hospitalId': selectedHosp,
                  'departmentId': selectedDept,
                  'status': 'active',
                  'currentToken': tokenCtrl.text.trim(),
                  'currentTokenNumber': tokenCtrl.text.trim(),
                  'lastIssuedToken': tokenCtrl.text.trim(),
                  'delayMinutes': 0,
                  'createdAt': now,
                  'updatedAt': now,
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Queue session $sId created!'), backgroundColor: AppColors.success),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create session: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Create Session'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDelayDialog(BuildContext context) {
    int selectedMinutes = 20;
    String selectedReason = 'Doctor attending ward rounds';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Broadcast Clinic Delay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedMinutes,
                decoration: const InputDecoration(labelText: 'Additional Minutes', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('+15 Minutes')),
                  DropdownMenuItem(value: 20, child: Text('+20 Minutes')),
                  DropdownMenuItem(value: 30, child: Text('+30 Minutes')),
                  DropdownMenuItem(value: 45, child: Text('+45 Minutes')),
                  DropdownMenuItem(value: 60, child: Text('+60 Minutes')),
                ],
                onChanged: (val) => setDlgState(() => selectedMinutes = val ?? 20),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(labelText: 'Delay Reason', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Doctor attending ward rounds', child: Text('Doctor attending ward rounds')),
                  DropdownMenuItem(value: 'Emergency surgical consultation', child: Text('Emergency surgical consultation')),
                  DropdownMenuItem(value: 'Diagnostic equipment delay', child: Text('Diagnostic equipment delay')),
                  DropdownMenuItem(value: 'Complex patient examination', child: Text('Complex patient examination')),
                ],
                onChanged: (val) => setDlgState(() => selectedReason = val ?? 'Doctor delay'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  final now = FieldValue.serverTimestamp();
                  final ref = _firestore.collection(AppConstants.delayUpdatesCollection).doc();
                  await ref.set({
                    'delayUpdateId': ref.id,
                    'additionalMinutes': selectedMinutes,
                    'delayMinutes': selectedMinutes,
                    'reason': selectedReason,
                    'delayReason': selectedReason,
                    'createdBy': 'admin_crud_console',
                    'isActive': true,
                    'createdAt': now,
                  });

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('+$selectedMinutes min delay broadcasted!'), backgroundColor: Colors.amber.shade900),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to broadcast: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePauseSession(String sessionId, bool currentlyPaused) async {
    try {
      final newStatus = currentlyPaused ? 'active' : 'paused';
      await _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyPaused ? 'Queue session resumed.' : 'Queue session paused.'),
          backgroundColor: currentlyPaused ? AppColors.success : Colors.blueGrey,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update session: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resetSessionCounters(String sessionId) async {
    try {
      await _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId).update({
        'currentToken': 'A-001',
        'currentTokenNumber': 'A-001',
        'delayMinutes': 0,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session reset to A-001.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmDeleteSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Queue Session?'),
        content: Text('Are you sure you want to permanently delete session "$sessionId"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId).delete();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session deleted.'), backgroundColor: AppColors.error),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDelayUpdate(String docId) async {
    try {
      await _firestore.collection(AppConstants.delayUpdatesCollection).doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delay alert dismissed.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete delay: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
