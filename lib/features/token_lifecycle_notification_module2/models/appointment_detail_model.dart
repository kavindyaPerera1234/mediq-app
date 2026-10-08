class AppointmentModel {

  final String appointmentId;
  final String hospitalName;
  final String clinicName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;


  AppointmentModel({

    required this.appointmentId,
    required this.hospitalName,
    required this.clinicName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,

  });



  factory AppointmentModel.sample(){

    return AppointmentModel(

      appointmentId: "APT001",
      hospitalName: "National Hospital of Sri Lanka",
      clinicName: "General Medicine",
      appointmentDate: "20 October 2026",
      appointmentTime: "9:00 AM",
      status: "CONFIRMED",

    );

  }

}