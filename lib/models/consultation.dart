import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String consultationId;
  final String appointmentId;
  final String queueEntryId;
  final String patientId;
  final String doctorId;
  final String status; // waiting, in_progress, completed
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Consultation({
    required this.consultationId,
    required this.appointmentId,
    required this.queueEntryId,
    required this.patientId,
    required this.doctorId,
    this.status = 'in_progress',
    this.notes = '',
    this.startedAt,
    this.completedAt,
  });

  factory Consultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Consultation(
      consultationId: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      queueEntryId: data['queueEntryId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      status: data['status'] ?? 'in_progress',
      notes: data['notes'] ?? '',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'queueEntryId': queueEntryId,
      'patientId': patientId,
      'doctorId': doctorId,
      'status': status,
      'notes': notes,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
