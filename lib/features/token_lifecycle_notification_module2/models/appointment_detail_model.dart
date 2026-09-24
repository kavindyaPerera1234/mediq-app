class AppointmentDetailModel {
  final String appointmentId;
  final String patientId;
  final String hospitalName;
  final String clinicName;
  final String doctorName;
  final String date;
  final String time;
  final String status;


  AppointmentDetailModel({
    required this.appointmentId,
    required this.patientId,
    required this.hospitalName,
    required this.clinicName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
  });


  // Firestore → Model
  factory AppointmentDetailModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return AppointmentDetailModel(
      appointmentId: id,
      patientId: data['patientId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      clinicName: data['clinicName'] ?? '',
      doctorName: data['doctorName'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      status: data['status'] ?? 'confirmed',
    );
  }


  // Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'hospitalName': hospitalName,
      'clinicName': clinicName,
      'doctorName': doctorName,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}