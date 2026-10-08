import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;

  final String patientId;
  final String? caregiverId;
  final String? caregiverPatientId;

  final String hospitalId;
  final String departmentId;
  final String slotId;

  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String patientName;

  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  final String hospitalName;
  final String departmentName;
  final String tokenCode;
  final String timeSlot;

  AppointmentModel({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.caregiverPatientId,
    required this.hospitalId,
    required this.departmentId,
    required this.slotId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.hospitalName,
    required this.departmentName,
    required this.tokenCode,
    required this.timeSlot,
    required this.patientName,
    this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.completedAt,
  });

  factory AppointmentModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppointmentModel(
      id: id,
      patientId: data['patientId'] ?? data['userId'] ?? '',
      caregiverId: data['caregiverId'],
      caregiverPatientId: data['caregiverPatientId'],
      hospitalId: data['hospitalId'] ?? '',
      departmentId: data['departmentId'] ?? data['clinicId'] ?? '',
      slotId: data['slotId'] ?? '',
      patientName: data['patientName'] ?? '',
      appointmentDate: data['appointmentDate'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'confirmed',
      hospitalName: data['hospitalName'] ?? '',
      departmentName: data['departmentName'] ?? data['clinicName'] ?? '',
      tokenCode: data['tokenCode'] ?? data['tokenNumber'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      cancelledAt: _parseTimestamp(data['cancelledAt']),
      completedAt: _parseTimestamp(data['completedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'tokenCode': tokenCode,
      'tokenNumber': tokenCode,
      'patientName': patientName,
      'hospitalName': hospitalName,
      'departmentName': departmentName,
      'clinicName': departmentName,
      'timeSlot': timeSlot,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'cancelledAt': cancelledAt,
      'completedAt': completedAt,
    };
  }
}