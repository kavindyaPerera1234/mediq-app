import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String appointmentId;
  final String patientId;
  final String caregiverId;
  final String caregiverPatientId;
  final String hospitalId;
  final String departmentId;
  final String slotId;
  final String appointmentDate; // YYYY-MM-DD
  final String startTime;
  final String endTime;
  final String status; // booked, completed, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  Appointment({
    required this.appointmentId,
    required this.patientId,
    this.caregiverId = '',
    this.caregiverPatientId = '',
    required this.hospitalId,
    required this.departmentId,
    required this.slotId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    this.status = 'booked',
    this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.completedAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Appointment(
      appointmentId: doc.id,
      patientId: data['patientId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      caregiverPatientId: data['caregiverPatientId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      slotId: data['slotId'] ?? '',
      appointmentDate: data['appointmentDate'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'booked',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'caregiverId': caregiverId,
      'caregiverPatientId': caregiverPatientId,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'slotId': slotId,
      'appointmentDate': appointmentDate,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
