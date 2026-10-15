import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  final String? userId;
  final String? startTime;
  final String? endTime;
  final String? slotId;

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
    this.userId,
    this.startTime,
    this.endTime,
    this.slotId,
  });

  bool get isExpiredOrPassed {
    final st = status.toLowerCase().trim();
    if (st == 'called' || st == 'serving' || st == 'in_consultation' || st == 'arrived' || st == 'on_hold') {
      return false;
    }
    if (st == 'completed' || st == 'cancelled' || st == 'missed' || st == 'expired') {
      return true;
    }

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // If date is before today -> Expired / Past
    if (appointmentDate.compareTo(todayStr) < 0) {
      return true;
    }

    // If date is in the future -> Upcoming
    if (appointmentDate.compareTo(todayStr) > 0) {
      return false;
    }

    // If appointment is TODAY: Check if the slot end time has passed
    try {
      String endTimeStr = endTime ?? '';
      if (endTimeStr.isEmpty && timeSlot.contains('-')) {
        endTimeStr = timeSlot.split('-').last.trim();
      } else if (endTimeStr.isEmpty) {
        endTimeStr = timeSlot.trim();
      }

      final cleanTime = endTimeStr.toUpperCase();
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        DateTime? slotEnd;
        try {
          final parsed = DateFormat('h:mm a').parse(endTimeStr.trim());
          slotEnd = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
        } catch (_) {
          try {
            final parsed = DateFormat('hh:mm a').parse(endTimeStr.trim());
            slotEnd = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
          } catch (_) {}
        }
        if (slotEnd != null && now.isAfter(slotEnd)) {
          return true;
        }
      } else if (endTimeStr.contains(':')) {
        final parts = endTimeStr.split(':');
        final h = int.tryParse(parts[0].trim()) ?? 0;
        final m = int.tryParse(parts[1].trim()) ?? 0;
        final slotEnd = DateTime(now.year, now.month, now.day, h, m);
        if (now.isAfter(slotEnd)) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  static String _extractStartTime(String slot) {
    if (slot.contains('-')) {
      return slot.split('-').first.trim();
    }
    return slot;
  }

  static String _extractEndTime(String slot) {
    if (slot.contains('-')) {
      return slot.split('-').last.trim();
    }
    return slot;
  }

  Map<String, dynamic> toMap() {
    final effectiveUserId = userId ?? patientId;
    return {
      'appointmentId': id,
      'patientId': patientId,
      'userId': effectiveUserId,
      'patientName': patientName,
      'patientNic': patientNic,
      'isCaregiverBooking': isCaregiverBooking,
      'relationship': relationship,
      'priority': priority,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'clinicId': departmentId,
      'clinicName': departmentName,
      'roomNumber': roomNumber,
      'appointmentDate': appointmentDate,
      'timeSlot': timeSlot,
      'startTime': startTime ?? _extractStartTime(timeSlot),
      'endTime': endTime ?? _extractEndTime(timeSlot),
      'slotId': slotId ?? '',
      'tokenCode': tokenCode,
      'tokenNumber': tokenCode,
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

    final tSlot = data['timeSlot'] ?? '';

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? data['userId'] ?? '',
      userId: data['userId'] ?? data['patientId'],
      patientName: data['patientName'] ?? 'Patient',
      patientNic: data['patientNic'] ?? '',
      isCaregiverBooking: data['isCaregiverBooking'] ?? false,
      relationship: data['relationship'] ?? 'Self',
      priority: data['priority'] ?? 'normal',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      departmentId: data['departmentId'] ?? data['clinicId'] ?? '',
      departmentName: data['departmentName'] ?? data['clinicName'] ?? '',
      roomNumber: data['roomNumber'] ?? 'OPD Room 01',
      appointmentDate: data['appointmentDate'] ?? '',
      timeSlot: tSlot,
      startTime: data['startTime'] ?? _extractStartTime(tSlot),
      endTime: data['endTime'] ?? _extractEndTime(tSlot),
      slotId: data['slotId'],
      tokenCode: data['tokenCode'] ?? data['tokenNumber'] ?? 'A-001',
      status: data['status'] ?? 'confirmed',
      createdAt: created,
    );
  }
}
