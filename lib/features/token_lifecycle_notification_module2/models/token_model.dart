class TokenModel {
  final String tokenId;
  final String appointmentId;
  final String tokenNumber;
  final String status;
  final int queuePosition;
  final int estimatedWaitMinutes;
  final String qrCode;


  TokenModel({
    required this.tokenId,
    required this.appointmentId,
    required this.tokenNumber,
    required this.status,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
    required this.qrCode,
  });


  // Convert Firestore document to TokenModel
  factory TokenModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return TokenModel(
      tokenId: id,
      appointmentId: data['appointmentId'] ?? '',
      tokenNumber: data['tokenNumber'] ?? '',
      status: data['status'] ?? 'waiting',
      queuePosition: data['queuePosition'] ?? 0,
      estimatedWaitMinutes: data['estimatedWaitMinutes'] ?? 0,
      qrCode: data['qrCode'] ?? '',
    );
  }


  // Convert TokenModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'appointmentId': appointmentId,
      'tokenNumber': tokenNumber,
      'status': status,
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'qrCode': qrCode,
    };
  }
}