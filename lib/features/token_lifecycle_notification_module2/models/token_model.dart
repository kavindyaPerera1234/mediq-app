class DigitalToken {

  final String tokenNumber;
  final String tokenCode;
  final String hospitalName;
  final String clinicName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;


  DigitalToken({

    required this.tokenNumber,
    required this.tokenCode,
    required this.hospitalName,
    required this.clinicName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,

  });


  factory DigitalToken.sample(){

    return DigitalToken(

      tokenNumber: "24",
      tokenCode: "A-024",
      hospitalName: "National Hospital of Sri Lanka",
      clinicName: "General Medicine",
      appointmentDate: "20 October 2026",
      appointmentTime: "9:00 AM",
      status: "CONFIRMED",

    );

  }

}