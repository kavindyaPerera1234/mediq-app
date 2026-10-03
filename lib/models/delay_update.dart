import 'package:cloud_firestore/cloud_firestore.dart';

class DelayUpdate {
  final String delayId;
  final String queueSessionId;
  final String hospitalId;
  final String departmentId;
  final String reason;
  final int additionalMinutes;
  final String createdBy; // userId
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  DelayUpdate({
    required this.delayId,
    required this.queueSessionId,
    required this.hospitalId,
    required this.departmentId,
    required this.reason,
    required this.additionalMinutes,
    required this.createdBy,
    this.isActive = true,
    this.createdAt,
    this.resolvedAt,
  });

  factory DelayUpdate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DelayUpdate(
      delayId: doc.id,
      queueSessionId: data['queueSessionId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      reason: data['reason'] ?? '',
      additionalMinutes: data['additionalMinutes'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueSessionId': queueSessionId,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'reason': reason,
      'additionalMinutes': additionalMinutes,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}
