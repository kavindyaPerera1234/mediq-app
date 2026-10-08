class QueueAlertTriggerService {
  /// Determines the alert stage from the number
  /// of patients ahead of the current patient.
  ///
  /// 0 patients ahead  -> YOUR_TURN
  /// 1-2 ahead         -> APPROACHING
  /// 3+ ahead          -> WAITING
  static String getAlertStage({
    required int patientsAhead,
  }) {
    if (patientsAhead <= 0) {
      return 'YOUR_TURN';
    }

    if (patientsAhead <= 2) {
      return 'APPROACHING';
    }

    return 'WAITING';
  }

  /// Patient should receive an approaching/turn alert
  /// when two or fewer patients are ahead.
  static bool shouldNotifyPatient({
    required int patientsAhead,
  }) {
    return patientsAhead <= 2;
  }

  /// Caregiver should receive an alert when the patient
  /// is approaching their turn.
  static bool shouldNotifyCaregiver({
    required int patientsAhead,
  }) {
    return patientsAhead <= 2;
  }

  /// True only when it is the patient's turn.
  static bool isYourTurn({
    required int patientsAhead,
  }) {
    return patientsAhead <= 0;
  }

  /// Human-readable message for the current stage.
  static String getStageMessage({
    required int patientsAhead,
  }) {
    if (patientsAhead <= 0) {
      return 'Your turn';
    }

    if (patientsAhead == 1) {
      return '1 patient ahead';
    }

    if (patientsAhead == 2) {
      return '2 patients ahead';
    }

    return '$patientsAhead patients ahead';
  }
}