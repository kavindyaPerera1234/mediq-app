class AppointmentModel {
  final String id;

  final String patientId;
  final String? caregiverId;
  final String? caregiverPatientId;

  final String hospitalId;
  final String departmentId;
  final String slotId;

  final String appointmentDate;
  final String startTime;
  final String endTime;

  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  final String hospitalName;
  final String departmentName;
  final String tokenCode;
  final String timeSlot;

  AppointmentModel({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.caregiverPatientId,
    required this.hospitalId,
    required this.departmentId,
    required this.slotId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.hospitalName,
    required this.departmentName,
    required this.tokenCode,
    required this.timeSlot,
    this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.completedAt,
  });

  factory AppointmentModel.fromFirestore(
        String id,
        Map<String, dynamic> data,
    ) {
        return AppointmentModel(
          id: id,
          patientId: data['patientId'] ?? '',

          caregiverId: data['caregiverId'],

          caregiverPatientId:
          data['caregiverPatientId'],

          hospitalId: data['hospitalId'] ?? '',

          departmentId: data['departmentId'] ?? '',

          slotId: data['slotId'] ?? '',

          appointmentDate:
          data['appointmentDate'] ?? '',

          startTime:
          data['startTime'] ?? '',

          endTime:
          data['endTime'] ?? '',

          status:
          data['status'] ?? 'confirmed',

          hospitalName: data['hospitalName'] ?? '',

          departmentName: data['departmentName'] ?? '',

          tokenCode: data['tokenCode'] ?? '',

          timeSlot: data['timeSlot'] ?? '',

          createdAt:
          data['createdAt']?.toDate(),

          updatedAt:
          data['updatedAt']?.toDate(),

          cancelledAt:
          data['cancelledAt']?.toDate(),

          completedAt:
          data['completedAt']?.toDate(),
        );
      }

      Map<String, dynamic> toFirestore(){
        return {
          'patientId': patientId,
          'caregiverId': caregiverId,
          'caregiverPatientId': caregiverPatientId,
          'hospitalId': hospitalId,
          'departmentId': departmentId,
          'slotId': slotId,
          'appointmentDate': appointmentDate,
          'startTime': startTime,
          'endTime': endTime,
          'status': status,
          'createdAt': createdAt,
          'updatedAt': updatedAt,
          'cancelledAt': cancelledAt,
          'completedAt': completedAt,
        };
      }
}