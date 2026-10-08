import 'package:cloud_firestore/cloud_firestore.dart';

class QueueSession {
  final String queueSessionId;
  final String hospitalId;
  final String departmentId;
  final String date; // YYYY-MM-DD
  final String status; // not_started, active, paused, delayed, completed
  final String currentTokenNumber;
  final String lastIssuedTokenNumber;
  final int estimatedMinutesPerPatient;
  final int delayMinutes;
  final String delayReason;
  final DateTime? pausedAt;
  final DateTime? resumedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QueueSession({
    required this.queueSessionId,
    required this.hospitalId,
    required this.departmentId,
    required this.date,
    this.status = 'active',
    this.currentTokenNumber = 'A-000',
    this.lastIssuedTokenNumber = 'A-000',
    this.estimatedMinutesPerPatient = 10,
    this.delayMinutes = 0,
    this.delayReason = '',
    this.pausedAt,
    this.resumedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory QueueSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final token = data['currentTokenNumber'] ?? data['currentToken'] ?? 'A-000';
    final lastToken = data['lastIssuedTokenNumber'] ?? data['lastIssuedToken'] ?? 'A-000';

    return QueueSession(
      queueSessionId: doc.id,
      hospitalId: data['hospitalId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'active',
      currentTokenNumber: token,
      lastIssuedTokenNumber: lastToken,
      estimatedMinutesPerPatient: data['estimatedMinutesPerPatient'] ?? 10,
      delayMinutes: data['delayMinutes'] ?? 0,
      delayReason: data['delayReason'] ?? '',
      pausedAt: (data['pausedAt'] as Timestamp?)?.toDate(),
      resumedAt: (data['resumedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueSessionId': queueSessionId,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'date': date,
      'status': status,
      'currentToken': currentTokenNumber,
      'currentTokenNumber': currentTokenNumber,
      'lastIssuedToken': lastIssuedTokenNumber,
      'lastIssuedTokenNumber': lastIssuedTokenNumber,
      'estimatedMinutesPerPatient': estimatedMinutesPerPatient,
      'delayMinutes': delayMinutes,
      'delayReason': delayReason,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'resumedAt': resumedAt != null ? Timestamp.fromDate(resumedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
