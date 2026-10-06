import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientNic;
  final bool isCaregiverBooking;
  final String relationship;
  final String priority;
  final String hospitalId;
  final String hospitalName;
  final String departmentId;
  final String departmentName;
  final String roomNumber;
  final String appointmentDate; // 'yyyy-MM-dd'
  final String timeSlot;
  final String tokenCode;
  final String status; // 'confirmed', 'completed', 'cancelled'
  final DateTime? createdAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientNic,
    this.isCaregiverBooking = false,
    this.relationship = 'Self',
    this.priority = 'normal',
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
    this.roomNumber = 'OPD Room 01',
    required this.appointmentDate,
    required this.timeSlot,
    required this.tokenCode,
    this.status = 'confirmed',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientNic': patientNic,
      'userId': patientId,
      'caregiverId': isCaregiverBooking ? (patientNic.isNotEmpty ? patientNic : patientId) : null,
      'isCaregiverBooking': isCaregiverBooking,
      'relationship': relationship,
      'priority': priority,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'roomNumber': roomNumber,
      'appointmentDate': appointmentDate,
      'timeSlot': timeSlot,
      'tokenCode': tokenCode,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']);
    }

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Patient',
      patientNic: data['patientNic'] ?? '',
      isCaregiverBooking: data['isCaregiverBooking'] ?? false,
      relationship: data['relationship'] ?? 'Self',
      priority: data['priority'] ?? 'normal',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      departmentId: data['departmentId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      roomNumber: data['roomNumber'] ?? 'OPD Room 01',
      appointmentDate: data['appointmentDate'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      tokenCode: data['tokenCode'] ?? 'A-001',
      status: data['status'] ?? 'confirmed',
      createdAt: created,
    );
  }
}
