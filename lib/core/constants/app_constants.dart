class AppConstants {
  static const String appName = 'MediQ';
  static const String appTitle = 'OPD Queue Management';

  // Shared Firebase Collection Names (EXACT names)
  static const String usersCollection = 'users';
  static const String patientProfilesCollection = 'patient_profiles';
  static const String staffProfilesCollection = 'staff_profiles';
  static const String caregiverPatientsCollection = 'caregiver_patients';
  static const String hospitalsCollection = 'hospitals';
  static const String departmentsCollection = 'departments';
  static const String appointmentSlotsCollection = 'appointment_slots';
  static const String appointmentsCollection = 'appointments';
  static const String queueSessionsCollection = 'queue_sessions';
  static const String queueEntriesCollection = 'queue_entries';
  static const String queueEventsCollection = 'queue_events';
  static const String notificationsCollection = 'notifications';
  static const String deviceTokensCollection = 'device_tokens';
  static const String consultationsCollection = 'consultations';
  static const String delayUpdatesCollection = 'delay_updates';

  // Queue Entry Statuses
  static const String statusWaiting = 'waiting';
  static const String statusApproaching = 'approaching';
  static const String statusCalled = 'called';
  static const String statusInConsultation = 'in_consultation';
  static const String statusOnHold = 'on_hold';
  static const String statusMissed = 'missed';
  static const String statusRejoined = 'rejoined';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Queue Session Statuses
  static const String sessionNotStarted = 'not_started';
  static const String sessionActive = 'active';
  static const String sessionPaused = 'paused';
  static const String sessionDelayed = 'delayed';
  static const String sessionCompleted = 'completed';

  // Priority Levels
  static const String priorityNormal = 'normal';
  static const String priorityElderly = 'elderly';
  static const String priorityPregnant = 'pregnant';
  static const String priorityDisabled = 'disabled';
  static const String priorityEmergency = 'emergency';

  // Staff Roles
  static const String roleDoctor = 'doctor';
  static const String roleNurse = 'nurse';
  static const String roleReceptionist = 'receptionist';
  static const String roleAdmin = 'admin';
}