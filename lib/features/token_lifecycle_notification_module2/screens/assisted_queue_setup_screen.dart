import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_caregiver_screen.dart';
import 'caregiver_alert_status_screen.dart';

import '../../../core/constants/app_colors.dart';

class AssistedQueueSetupScreen extends StatefulWidget {
  final String appointmentId;

  const AssistedQueueSetupScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AssistedQueueSetupScreen> createState() =>
      _AssistedQueueSetupScreenState();
}

class _AssistedQueueSetupScreenState
    extends State<AssistedQueueSetupScreen> {
  bool assistedQueueEnabled = false;
  bool isLoading = true;
  bool isSaving = false;

  Map<String, dynamic>? caregiverData;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAssistedQueueData();
  }

  // ============================================================
  // LOAD EXISTING DATA
  // ============================================================

  Future<void> _loadAssistedQueueData() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (appointmentDoc.exists &&
          appointmentDoc.data() != null) {
        final data = appointmentDoc.data()!;

        final assistedQueue =
            data['assistedQueue'];

        if (assistedQueue is Map) {
          assistedQueueEnabled =
              assistedQueue['enabled'] == true;

          final caregiver =
              assistedQueue['caregiver'];

          if (caregiver is Map) {
            caregiverData =
                Map<String, dynamic>.from(
              caregiver,
            );
          } else {
            caregiverData = null;
          }
        } else {
          assistedQueueEnabled =
              data['assistedQueueEnabled'] == true;

          caregiverData = null;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load Assisted Queue settings: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE ENABLE / DISABLE
  // ============================================================

  Future<void> _updateAssistedQueue(
    bool value,
  ) async {
    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .set(
        {
          'assistedQueue': {
            'enabled': value,
          },
          'assistedQueueEnabled': value,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        assistedQueueEnabled = value;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Assisted Queue enabled'
                : 'Assisted Queue disabled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update Assisted Queue: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ADD CAREGIVER
  // ============================================================

  Future<void> _addCaregiver() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCaregiverScreen(
          appointmentId: widget.appointmentId,
        ),
      ),
    );

    // Caregiver was saved.
    // Reload the appointment data.
    if (result == true && mounted) {
      await _loadAssistedQueueData();
    }
  }

  // ============================================================
  // VIEW CAREGIVER ALERT STATUS
  // ============================================================

  Future<void> _viewCaregiverAlertStatus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CaregiverAlertStatusScreen(
          appointmentId: widget.appointmentId,
        ),
      ),
    );
  }

  // ============================================================
  // GET CAREGIVER VALUE
  // ============================================================

  String _caregiverValue(
    String key, {
    String fallback = 'Not available',
  }) {
    final value = caregiverData?[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  // ============================================================
  // CAREGIVER DETAILS CARD
  // ============================================================

  Widget _buildCaregiverDetails() {
    if (caregiverData == null) {
      return Column(
        children: [
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  assistedQueueEnabled
                      ? _addCaregiver
                      : null,
              icon: const Icon(
                Icons.person_add_alt_1,
                size: 19,
              ),
              label: const Text(
                'Add Caregiver',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                side:
                    const BorderSide(
                  color: AppColors.primary,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 18),

        // ======================================================
        // SAVED CAREGIVER
        // ======================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caregiver Added',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _caregiverValue(
                        'name',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _caregiverValue(
                        'phone',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _caregiverValue(
                        'relationship',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Added',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // VIEW ALERT STATUS BUTTON
        // ======================================================

        SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(
            onPressed:
                assistedQueueEnabled
                    ? _viewCaregiverAlertStatus
                    : null,

            icon: const Icon(
              Icons.notifications_active_outlined,
              size: 19,
            ),

            label: const Text(
              'View Caregiver Alert Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ======================================================
        // ADD / CHANGE CAREGIVER
        // ======================================================

        SizedBox(
          width: double.infinity,

          child: OutlinedButton.icon(
            onPressed:
                assistedQueueEnabled
                    ? _addCaregiver
                    : null,

            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
            ),

            label: const Text(
              'Change Caregiver',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 13,
              ),
              side:
                  const BorderSide(
                color: AppColors.primary,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color:
                AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Assisted Queue',
          style: TextStyle(
            color:
                AppColors.textPrimary,
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // HEADER CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(20),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      border: Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withOpacity(
                              0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),

                          child: const Icon(
                            Icons
                                .people_alt_outlined,
                            color:
                                AppColors.primary,
                            size: 28,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        const Text(
                          'Assisted Queue Mode',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Get help from a caregiver when your appointment turn is approaching.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // ENABLE / DISABLE CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,

                          decoration:
                              BoxDecoration(
                            color:
                                assistedQueueEnabled
                                    ? AppColors
                                        .primary
                                        .withOpacity(
                                      0.10,
                                    )
                                    : Colors.grey
                                        .withOpacity(
                                      0.10,
                                    ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          child: Icon(
                            assistedQueueEnabled
                                ? Icons
                                    .notifications_active_outlined
                                : Icons
                                    .notifications_none_outlined,
                            color:
                                assistedQueueEnabled
                                    ? AppColors
                                        .primary
                                    : Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Enable Assisted Queue',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: AppColors
                                      .textPrimary,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                assistedQueueEnabled
                                    ? 'Caregiver assistance is enabled.'
                                    : 'Turn this on to add a caregiver.',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value:
                              assistedQueueEnabled,
                          activeColor:
                              AppColors.primary,
                          onChanged: isSaving
                              ? null
                              : _updateAssistedQueue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // CAREGIVER SECTION
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,

                              decoration:
                                  BoxDecoration(
                                color: Colors.blue
                                    .withOpacity(
                                  0.08,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),

                              child: const Icon(
                                Icons
                                    .person_add_alt_1_outlined,
                                color:
                                    AppColors.primary,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    'Caregiver',
                                    style:
                                        TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      color: AppColors
                                          .textPrimary,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    'Add someone who can help you with queue alerts.',
                                    style:
                                        TextStyle(
                                      fontSize: 12,
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Show Add Caregiver OR saved caregiver.
                        _buildCaregiverDetails(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // INFORMATION
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),

                    decoration:
                        BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.05),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color:
                              AppColors.primary,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Your caregiver can receive important queue alerts when your turn is approaching.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }
}