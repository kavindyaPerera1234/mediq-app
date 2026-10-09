class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String status;
  final bool isRead;

  final String? userId;
  final String? patientId;
  final String? patientName;
  final String? appointmentId;

  final String? tokenNumber;
  final String? hospitalName;
  final String? clinicName;
  final String? roomNumber;

  final String? appointmentDate;
  final String? timeSlot;
  final String? dateTime;

  // Near Turn
  final String? nowServing;
  final String? peopleAhead;
  final String? estimatedWait;

  // Delay
  final String? affectedOPD;
  final String? delayTime;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.isRead,
    this.userId,
    this.patientId,
    this.patientName,
    this.appointmentId,
    this.tokenNumber,
    this.hospitalName,
    this.clinicName,
    this.roomNumber,
    this.appointmentDate,
    this.timeSlot,
    this.dateTime,
    this.nowServing,
    this.peopleAhead,
    this.estimatedWait,
    this.affectedOPD,
    this.delayTime,
  });

  factory NotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),

      status: (json['status'] ??
              (json['isRead'] == true ? 'READ' : 'NEW'))
          .toString(),

      isRead: json['isRead'] == true,

      userId: json['userId']?.toString(),

      patientId: json['patientId']?.toString(),

      patientName: json['patientName']?.toString(),

      appointmentId:
          json['appointmentId']?.toString(),

      tokenNumber:
          (json['tokenNumber'] ??
                  json['tokenCode'])
              ?.toString(),

      hospitalName:
          json['hospitalName']?.toString(),

      clinicName:
          (json['clinicName'] ??
                  json['departmentName'])
              ?.toString(),

      roomNumber:
          json['roomNumber']?.toString(),

      appointmentDate:
          json['appointmentDate']?.toString(),

      timeSlot:
          json['timeSlot']?.toString(),

      dateTime:
          (json['dateTime'] ??
                  json['createdAt'])
              ?.toString(),

      nowServing:
          json['nowServing']?.toString(),

      peopleAhead:
          (json['patientsAhead'] ??
                  json['peopleAhead'])
              ?.toString(),

      estimatedWait:
          json['estimatedWait']?.toString(),

      affectedOPD:
          (json['affectedOPD'] ??
                  json['clinicName'] ??
                  json['departmentName'])
              ?.toString(),

      delayTime:
          json['delayTime']?.toString(),
    );
  }

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationModel(
      id: id,

      type: (data['type'] ?? '').toString(),

      title: (data['title'] ?? '').toString(),

      message:
          (data['message'] ?? '').toString(),

      status: (data['status'] ??
              (data['isRead'] == true
                  ? 'READ'
                  : 'NEW'))
          .toString(),

      isRead: data['isRead'] == true,

      userId:
          data['userId']?.toString(),

      patientId:
          data['patientId']?.toString(),

      patientName:
          data['patientName']?.toString(),

      appointmentId:
          data['appointmentId']?.toString(),

      tokenNumber:
          (data['tokenNumber'] ??
                  data['tokenCode'])
              ?.toString(),

      hospitalName:
          data['hospitalName']?.toString(),

      clinicName:
          (data['clinicName'] ??
                  data['departmentName'])
              ?.toString(),

      roomNumber:
          data['roomNumber']?.toString(),

      appointmentDate:
          data['appointmentDate']?.toString(),

      timeSlot:
          data['timeSlot']?.toString(),

      dateTime:
          (data['dateTime'] ??
                  data['createdAt'])
              ?.toString(),

      nowServing:
          data['nowServing']?.toString(),

      peopleAhead:
          (data['patientsAhead'] ??
                  data['peopleAhead'])
              ?.toString(),

      estimatedWait:
          data['estimatedWait']?.toString(),

      affectedOPD:
          (data['affectedOPD'] ??
                  data['clinicName'] ??
                  data['departmentName'])
              ?.toString(),

      delayTime:
          data['delayTime']?.toString(),
    );
  }
}