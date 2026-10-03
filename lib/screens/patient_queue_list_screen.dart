import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/queue_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/loading_widget.dart';
import 'patient_queue_detail_screen.dart';
import 'call_next_patient_screen.dart';
import 'hold_and_resume_screen.dart';
import 'emergency_priority_screen.dart';
import 'staff_delay_communication_screen.dart';

class PatientQueueListScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;
  final int initialTabIndex;

  const PatientQueueListScreen({
    super.key,
    required this.authService,
    this.queueSessionId = 'QS-001',
    this.initialTabIndex = 0,
  });

  @override
  State<PatientQueueListScreen> createState() => _PatientQueueListScreenState();
}

class _PatientQueueListScreenState extends State<PatientQueueListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPriority = 'All';
  int _currentBottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: const [
            Text(
              "Today's Queue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "General Medicine OPD",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.primary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            tooltip: 'Emergency Priority',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyPriorityScreen(
                    authService: widget.authService,
                    queueSessionId: widget.queueSessionId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pause_circle_outline_rounded, color: AppColors.warning),
            tooltip: 'Patients on Hold',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HoldAndResumeScreen(
                    authService: widget.authService,
                    queueSessionId: widget.queueSessionId,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Waiting'),
            Tab(text: 'On Hold'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QueueEntry>>(
          stream: _firestoreService.streamQueueEntries(widget.queueSessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const LoadingWidget(message: 'Loading Today\'s Queue...');
            }

            final entries = snapshot.data ?? [];

            // Apply Search Query & Priority Filter
            final filteredEntries = entries.where((e) {
              final query = _searchQuery.toLowerCase().trim();
              final name = (e.patientName ?? '').toLowerCase();
              final token = (e.tokenNumber).toLowerCase();
              final code = (e.tokenCode).toLowerCase();
              
              final matchesSearch = query.isEmpty ||
                  name.contains(query) ||
                  token.contains(query) ||
                  code.contains(query);

              final matchesPriority = _selectedPriority == 'All'
                  ? true
                  : (_selectedPriority == 'Emergency'
                      ? e.priority == 'emergency'
                      : (_selectedPriority == 'Priority'
                          ? (e.priority == 'elderly' || e.priority == 'pregnant' || e.priority == 'disabled')
                          : e.priority == 'normal'));

              return matchesSearch && matchesPriority;
            }).toList();

            final waitingEntries = filteredEntries
                .where((e) =>
                    e.status == 'waiting' ||
                    e.status == 'approaching' ||
                    e.status == 'called' ||
                    e.status == 'in_consultation' ||
                    e.status == 'rejoined')
                .toList();

            final onHoldEntries = filteredEntries.where((e) => e.status == 'on_hold').toList();
            final completedEntries = filteredEntries.where((e) => e.status == 'completed').toList();

            return Column(
              children: [
                // Top Call Next Quick Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.primaryLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.queue_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Active Queue: ${waitingEntries.length} Patients Waiting',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CallNextPatientScreen(
                                authService: widget.authService,
                                queueSessionId: widget.queueSessionId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.campaign_rounded, size: 16),
                        label: const Text('Call Next', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(80, 34),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar & Filter Chips Section
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by patient name or token (e.g., A-012)...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Emergency', 'Priority', 'Normal'].map((priorityTag) {
                            final isSelected = _selectedPriority == priorityTag;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(
                                  priorityTag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: priorityTag == 'Emergency'
                                    ? AppColors.error
                                    : (priorityTag == 'Priority' ? AppColors.warning : AppColors.primary),
                                backgroundColor: AppColors.background,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPriority = priorityTag;
                                    });
                                  }
                                },
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQueueList(context, waitingEntries, emptyMessage: 'No waiting patients found.'),
                      _buildQueueList(context, onHoldEntries, emptyMessage: 'No patients currently on hold.'),
                      _buildQueueList(context, completedEntries, emptyMessage: 'No completed consultations found.'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: StaffBottomNavigation(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffDelayCommunicationScreen(
                  authService: widget.authService,
                  queueSessionId: widget.queueSessionId,
                ),
              ),
            );
          } else if (index == 4) {
            StaffBottomNavigation.showStaffProfileModal(context, widget.authService);
          } else {
            setState(() {
              _currentBottomNavIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, List<QueueEntry> entries, {required String emptyMessage}) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return QueueCard(
          entry: entry,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientQueueDetailScreen(
                  authService: widget.authService,
                  queueEntryId: entry.queueEntryId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
