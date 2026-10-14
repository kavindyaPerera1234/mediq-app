import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String consultationId;
  final String appointmentId;
  final String queueEntryId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String tokenNumber;
  final String hospitalId;
  final String departmentId;
  final String status; // in_progress, completed, cancelled
  final String diagnosis;
  final String prescription;
  final String notes;
  final String priority;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Consultation({
    required this.consultationId,
    required this.appointmentId,
    required this.queueEntryId,
    required this.patientId,
    this.patientName = '',
    required this.doctorId,
    this.doctorName = '',
    this.tokenNumber = '',
    this.hospitalId = 'HOSP-001',
    this.departmentId = 'DEPT-001',
    this.status = 'in_progress',
    this.diagnosis = '',
    this.prescription = '',
    this.notes = '',
    this.priority = 'normal',
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
      patientName: data['patientName'] ?? '',
      doctorId: docId,
      doctorName: data['doctorName'] ?? '',
      tokenNumber: data['tokenNumber'] ?? '',
      hospitalId: data['hospitalId'] ?? 'HOSP-001',
      departmentId: data['departmentId'] ?? 'DEPT-001',
      status: data['status'] ?? 'in_progress',
      diagnosis: data['diagnosis'] ?? '',
      prescription: data['prescription'] ?? '',
      notes: data['notes'] ?? '',
      priority: data['priority'] ?? 'normal',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consultationId': consultationId,
      'appointmentId': appointmentId,
      'queueEntryId': queueEntryId,
      'patientId': patientId,
      'patientName': patientName,
      'staffId': doctorId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'tokenNumber': tokenNumber,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'status': status,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'priority': priority,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Consultation copyWith({
    String? consultationId,
    String? appointmentId,
    String? queueEntryId,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? tokenNumber,
    String? hospitalId,
    String? departmentId,
    String? status,
    String? diagnosis,
    String? prescription,
    String? notes,
    String? priority,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consultation(
      consultationId: consultationId ?? this.consultationId,
      appointmentId: appointmentId ?? this.appointmentId,
      queueEntryId: queueEntryId ?? this.queueEntryId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      hospitalId: hospitalId ?? this.hospitalId,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
