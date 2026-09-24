class NotificationModel {

  final String id;
  final String type;
  final String title;
  final String message;
  final String status;
  final bool isRead;


  NotificationModel({

    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.isRead,

  });



  factory NotificationModel.sample(){

    return NotificationModel(

      id: "NOT001",

      type: "appointment_confirmed",

      title: "Appointment Confirmed",

      message:
          "Your OPD appointment has been successfully confirmed.",

      status: "NEW",

      isRead: false,

    );

  }

}