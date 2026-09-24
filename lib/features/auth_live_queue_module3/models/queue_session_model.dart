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
    this.totalTokens = 40,
    this.estimatedMinutesPerPatient = 4,
    this.status = QueueSessionStatus.active,
    this.delayMinutes = 0,
    this.delayReason,
    required this.lastUpdated,
  });

  bool get isDelayed => status == QueueSessionStatus.delayed || delayMinutes > 0;
  bool get isPaused => status == QueueSessionStatus.paused;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'roomNumber': roomNumber,
      'doctorName': doctorName,
      'currentTokenServing': currentTokenServing,
      'totalTokens': totalTokens,
      'estimatedMinutesPerPatient': estimatedMinutesPerPatient,
      'status': status.name,
      'delayMinutes': delayMinutes,
      'delayReason': delayReason,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory QueueSessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return QueueSessionModel(
      sessionId: id ?? map['sessionId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? 'General Hospital Colombo',
      departmentId: map['departmentId'] ?? '',
      departmentName: map['departmentName'] ?? 'General OPD',
      roomNumber: map['roomNumber'] ?? 'Room 04',
      doctorName: map['doctorName'] ?? 'Dr. H. M. Perera',
      currentTokenServing: map['currentTokenServing'] ?? 'A-001',
      totalTokens: (map['totalTokens'] as num?)?.toInt() ?? 40,
      estimatedMinutesPerPatient: (map['estimatedMinutesPerPatient'] as num?)?.toInt() ?? 4,
      status: QueueSessionStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (map['status'] ?? 'active').toString().toLowerCase(),
        orElse: () => QueueSessionStatus.active,
      ),
      delayMinutes: (map['delayMinutes'] as num?)?.toInt() ?? 0,
      delayReason: map['delayReason'],
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
