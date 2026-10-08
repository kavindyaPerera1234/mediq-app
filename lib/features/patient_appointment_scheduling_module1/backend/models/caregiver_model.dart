import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverPatientModel {
  final String id;
  final String caregiverUserId;
  final String patientName;
  final String patientNic;
  final String relationship; // 'Father', 'Mother', 'Child', 'Spouse', 'Other'
  final String priority; // 'elderly', 'wheelchair', 'maternity', 'normal'
  final DateTime? lastBookedAt;

  const CaregiverPatientModel({
    required this.id,
    required this.caregiverUserId,
    required this.patientName,
    required this.patientNic,
    required this.relationship,
    this.priority = 'normal',
    this.lastBookedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caregiverUserId': caregiverUserId,
      'patientName': patientName,
      'patientNic': patientNic,
      'relationship': relationship,
      'priority': priority,
      'lastBookedAt': lastBookedAt != null ? Timestamp.fromDate(lastBookedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory CaregiverPatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? lastBooked;
    if (data['lastBookedAt'] is Timestamp) {
      lastBooked = (data['lastBookedAt'] as Timestamp).toDate();
    }

    return CaregiverPatientModel(
      id: doc.id,
      caregiverUserId: data['caregiverUserId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientNic: data['patientNic'] ?? '',
      relationship: data['relationship'] ?? 'Family',
      priority: data['priority'] ?? 'normal',
      lastBookedAt: lastBooked,
    );
  }
}
