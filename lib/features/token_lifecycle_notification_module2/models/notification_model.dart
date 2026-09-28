class NotificationModel {

  final String id;
  final String type;
  final String title;
  final String message;
  final String status;
  final bool isRead;

  final String? tokenNumber;
  final String? hospitalName;
  final String? clinicName;
  final String? dateTime;

  // Near turn details
  final String? nowServing;
  final String? peopleAhead;
  final String? estimatedWait;

  // Delay details
  final String? affectedOPD;
  final String? delayTime;


  NotificationModel({

    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.isRead,

    this.tokenNumber,
    this.hospitalName,
    this.clinicName,
    this.dateTime,

    this.nowServing,
    this.peopleAhead,
    this.estimatedWait,

    this.affectedOPD,
    this.delayTime,

  });



  factory NotificationModel.fromJson(
      Map<String, dynamic> json
      ){

    return NotificationModel(

      id: json['id'] ?? '',

      type: json['type'] ?? '',

      title: json['title'] ?? '',

      message: json['message'] ?? '',

      status: json['status'] ?? '',

      isRead: json['isRead'] ?? false,


      tokenNumber: json['tokenNumber'],

      hospitalName: json['hospitalName'],

      clinicName: json['clinicName'],

      dateTime: json['dateTime'],


      nowServing: json['nowServing'],

      peopleAhead: json['peopleAhead'],

      estimatedWait: json['estimatedWait'],


      affectedOPD: json['affectedOPD'],

      delayTime: json['delayTime'],

    );

  }


}