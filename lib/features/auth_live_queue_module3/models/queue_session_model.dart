import 'package:cloud_firestore/cloud_firestore.dart';

enum QueueSessionStatus {
  active,
  paused,
  delayed,
  completed,
}

class QueueSessionModel {
  final String sessionId;
  final String hospitalId;
  final String hospitalName;
  final String departmentId;
  final String departmentName;
  final String roomNumber;
  final String doctorName;
  final String currentTokenServing;
  final String lastIssuedToken;
  final String date;
  final int totalTokens;
  final int estimatedMinutesPerPatient;
  final QueueSessionStatus status;
  final int delayMinutes;
  final String? delayReason;
  final DateTime lastUpdated;

  QueueSessionModel({
    required this.sessionId,
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
    required this.roomNumber,
    required this.doctorName,
    required this.currentTokenServing,
    this.lastIssuedToken = 'A-015',
    this.date = '',
    this.totalTokens = 40,
    this.estimatedMinutesPerPatient = 4,
    this.status = QueueSessionStatus.active,
    this.delayMinutes = 0,
    this.delayReason,
    required this.lastUpdated,
  });

  /// Aliases matching shared specification
  String get queueSessionId => sessionId;
  String get currentToken => currentTokenServing;
  DateTime get updatedAt => lastUpdated;

  bool get isDelayed => status == QueueSessionStatus.delayed || delayMinutes > 0;
  bool get isPaused => status == QueueSessionStatus.paused;

  Map<String, dynamic> toMap() {
    return {
      'queueSessionId': sessionId,
      'sessionId': sessionId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'roomNumber': roomNumber,
      'doctorName': doctorName,
      'currentToken': currentTokenServing,
      'currentTokenServing': currentTokenServing,
      'lastIssuedToken': lastIssuedToken,
      'date': date,
      'totalTokens': totalTokens,
      'estimatedMinutesPerPatient': estimatedMinutesPerPatient,
      'status': status.name,
      'delayMinutes': delayMinutes,
      'delayReason': delayReason,
      'updatedAt': lastUpdated.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory QueueSessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return QueueSessionModel(
      sessionId: id ?? map['queueSessionId'] ?? map['sessionId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? 'General Hospital Colombo',
      departmentId: map['departmentId'] ?? '',
      departmentName: map['departmentName'] ?? 'General OPD',
      roomNumber: map['roomNumber'] ?? 'Room 04',
      doctorName: map['doctorName'] ?? 'Dr. H. M. Perera',
      currentTokenServing: map['currentToken'] ?? map['currentTokenServing'] ?? 'A-001',
      lastIssuedToken: map['lastIssuedToken'] ?? 'A-015',
      date: map['date'] ?? map['appointmentDate'] ?? '',
      totalTokens: (map['totalTokens'] as num?)?.toInt() ?? 40,
      estimatedMinutesPerPatient: (map['estimatedMinutesPerPatient'] as num?)?.toInt() ?? 4,
      status: QueueSessionStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (map['status'] ?? 'active').toString().toLowerCase(),
        orElse: () => QueueSessionStatus.active,
      ),
      delayMinutes: (map['delayMinutes'] as num?)?.toInt() ?? 0,
      delayReason: map['delayReason'],
      lastUpdated: map['updatedAt'] != null
          ? parseDate(map['updatedAt'])
          : (map['lastUpdated'] != null ? parseDate(map['lastUpdated']) : DateTime.now()),
    );
  }
}
