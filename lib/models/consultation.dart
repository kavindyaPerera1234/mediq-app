import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String consultationId;
  final String appointmentId;
  final String queueEntryId;
  final String patientId;
  final String doctorId;
  final String hospitalId;
  final String departmentId;
  final String status; // in_progress, completed
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Consultation({
    required this.consultationId,
    required this.appointmentId,
    required this.queueEntryId,
    required this.patientId,
    required this.doctorId,
    this.hospitalId = 'HOSP-001',
    this.departmentId = 'DEPT-001',
    this.status = 'in_progress',
    this.notes = '',
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Consultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final docId = data['staffId'] ?? data['doctorId'] ?? '';
    return Consultation(
      consultationId: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      queueEntryId: data['queueEntryId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: docId,
      hospitalId: data['hospitalId'] ?? 'HOSP-001',
      departmentId: data['departmentId'] ?? 'DEPT-001',
      status: data['status'] ?? 'in_progress',
      notes: data['notes'] ?? '',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'queueEntryId': queueEntryId,
      'patientId': patientId,
      'staffId': doctorId,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'status': status,
      'notes': notes,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
