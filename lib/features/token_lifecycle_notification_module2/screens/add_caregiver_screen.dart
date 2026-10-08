import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AddCaregiverScreen extends StatefulWidget {
  final String appointmentId;

  const AddCaregiverScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AddCaregiverScreen> createState() =>
      _AddCaregiverScreenState();
}

class _AddCaregiverScreenState extends State<AddCaregiverScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  String? _selectedRelationship;
  String? _selectedLanguage;

  bool _smsNotifications = true;
  bool _appNotifications = true;

  bool _isSearchingCaregiver = false;
  bool _isSaving = false;

  String? _caregiverUid;
  bool _caregiverFound = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final List<String> _relationships = [
    'Parent',
    'Child',
    'Spouse',
    'Sibling',
    'Friend',
    'Other',
  ];

  final List<String> _languages = [
    'English',
    'Sinhala',
    'Tamil',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIND CAREGIVER BY PHONE NUMBER
  // ============================================================

  Future<void> _findCaregiver() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the caregiver phone number.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSearchingCaregiver = true;
      _caregiverFound = false;
      _caregiverUid = null;
    });

    try {
      final result = await _firestore
          .collection('users')
          .where(
            'phone',
            isEqualTo: phone,
          )
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isSearchingCaregiver = false;
          _caregiverFound = false;
          _caregiverUid = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No MediQ account was found for this phone number.',
            ),
          ),
        );

        return;
      }

      final caregiverDoc = result.docs.first;
      final data = caregiverDoc.data();

      final role =
          (data['role'] ?? '').toString().toLowerCase();

      final uid =
          (data['uid'] ?? caregiverDoc.id).toString();

      final fullName =
          (data['fullName'] ?? '').toString();

      final phoneNumber =
          (data['phone'] ?? phone).toString();

      final preferredLanguage =
          (data['preferredLanguage'] ?? '').toString();

      // Existing users collection uses patient accounts.
      if (role.isNotEmpty && role != 'patient') {
        if (!mounted) return;

        setState(() {
          _isSearchingCaregiver = false;
          _caregiverFound = false;
          _caregiverUid = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This account cannot be added as a caregiver.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _isSearchingCaregiver = false;
        _caregiverFound = true;
        _caregiverUid = uid;

        if (fullName.isNotEmpty) {
          _nameController.text = fullName;
        }

        if (phoneNumber.isNotEmpty) {
          _phoneController.text = phoneNumber;
        }

        if (preferredLanguage == 'en') {
          _selectedLanguage = 'English';
        } else if (preferredLanguage == 'si') {
          _selectedLanguage = 'Sinhala';
        } else if (preferredLanguage == 'ta') {
          _selectedLanguage = 'Tamil';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fullName.isNotEmpty
                ? '$fullName found.'
                : 'Caregiver account found.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearchingCaregiver = false;
        _caregiverFound = false;
        _caregiverUid = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to find caregiver account: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE CAREGIVER
  // ============================================================

  Future<void> _saveCaregiver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the relationship.',
          ),
        ),
      );
      return;
    }

    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the preferred language.',
          ),
        ),
      );
      return;
    }

    if (!_smsNotifications && !_appNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one notification method.',
          ),
        ),
      );
      return;
    }

    // App notification requires a registered account.
    if (_appNotifications && !_caregiverFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify the caregiver phone number first.',
          ),
        ),
      );
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> caregiverData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'relationship': _selectedRelationship,
        'preferredLanguage': _selectedLanguage,
        'appNotifications': _appNotifications,
        'smsNotifications': _smsNotifications,
      };

      // Save caregiver UID when the account was found.
      if (_caregiverUid != null &&
          _caregiverUid!.isNotEmpty) {
        caregiverData['uid'] = _caregiverUid;
      }

      await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .set(
        {
          'assistedQueue': {
            'enabled': true,
            'caregiver': caregiverData,
          },
          'assistedQueueEnabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Caregiver saved successfully.',
          ),
        ),
      );

      // Return to Assisted Queue Setup.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save caregiver: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION METHOD TILE
  // IMPORTANT:
  // No SwitchListTile here.
  // Uses Row + Switch to avoid ListTile/DecoratedBox assertion.
  // ============================================================

  Widget _notificationMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Switch
          Switch(
            value: value,
            onChanged: _isSaving ? null : onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Add Caregiver',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Caregiver Details',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Add someone you trust to receive important queue alerts and help you stay informed.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NAME
              // ==================================================

              const Text(
                'Caregiver Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Name',
                  hint: 'Enter caregiver name',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter the caregiver name.';
                  }

                  if (value.trim().length < 2) {
                    return 'Please enter a valid name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // PHONE
              // ==================================================

              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,

                onChanged: (_) {
                  if (_caregiverFound ||
                      _caregiverUid != null) {
                    setState(() {
                      _caregiverFound = false;
                      _caregiverUid = null;
                    });
                  }
                },

                decoration: _inputDecoration(
                  label: 'Phone Number',
                  hint: 'Enter caregiver phone number',
                  icon: Icons.phone_outlined,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter the phone number.';
                  }

                  final phone = value.trim();

                  if (!RegExp(
                    r'^[0-9+\-\s]{7,15}$',
                  ).hasMatch(phone)) {
                    return 'Please enter a valid phone number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 10),

              // ==================================================
              // FIND CAREGIVER
              // ==================================================

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed:
                      _isSearchingCaregiver ||
                              _isSaving
                          ? null
                          : _findCaregiver,

                  icon: _isSearchingCaregiver
                      ? const SizedBox(
                          height: 17,
                          width: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.search,
                          size: 18,
                        ),

                  label: Text(
                    _isSearchingCaregiver
                        ? 'Finding Caregiver...'
                        : _caregiverFound
                            ? 'Caregiver Account Found'
                            : 'Find Caregiver',
                  ),

                  style: OutlinedButton.styleFrom(
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

              if (_caregiverFound) ...[
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Colors.green,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        'MediQ account found. App notifications can be sent to this caregiver.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // ==================================================
              // RELATIONSHIP
              // ==================================================

              const Text(
                'Relationship',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _selectedRelationship,

                decoration: _inputDecoration(
                  label: 'Relationship',
                  icon: Icons.family_restroom_outlined,
                ),

                items: _relationships
                    .map(
                      (relationship) =>
                          DropdownMenuItem<String>(
                        value: relationship,
                        child: Text(relationship),
                      ),
                    )
                    .toList(),

                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRelationship =
                              value;
                        });
                      },

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Please select the relationship.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // LANGUAGE
              // ==================================================

              const Text(
                'Preferred Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _selectedLanguage,

                decoration: _inputDecoration(
                  label: 'Preferred Language',
                  icon: Icons.language_outlined,
                ),

                items: _languages
                    .map(
                      (language) =>
                          DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      ),
                    )
                    .toList(),

                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Please select the preferred language.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NOTIFICATION METHODS
              // ==================================================

              const Text(
                'Notification Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              _notificationMethodTile(
                title: 'SMS Notifications',
                subtitle:
                    'Send queue alerts to the caregiver phone number.',
                icon: Icons.sms_outlined,
                value: _smsNotifications,
                onChanged: (value) {
                  setState(() {
                    _smsNotifications = value;
                  });
                },
              ),

              _notificationMethodTile(
                title: 'App Notifications',
                subtitle:
                    'Send queue alerts to the caregiver MediQ account.',
                icon: Icons.notifications_outlined,
                value: _appNotifications,
                onChanged: (value) {
                  setState(() {
                    _appNotifications = value;
                  });
                },
              ),

              if (_appNotifications &&
                  !_caregiverFound) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.orange,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'Find the caregiver account using the phone number before saving App Notifications.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ==================================================
              // SAVE CAREGIVER
              // ==================================================

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed:
                      _isSaving
                          ? null
                          : _saveCaregiver,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Caregiver',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CANCEL
              // ==================================================

              SizedBox(
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                        },

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    side:
                        const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}