import 'app_language.dart';

/// Central Trilingual dictionary providing Simple Sinhala, Tamil, and English
/// for all 4 modules and admin console in MediQ.
class S {
  static String get lang => AppLanguage.currentLanguage.value;

  // ───────────────────────────────────────────────────────────────────────────
  // COMMON & NAVIGATION
  // ───────────────────────────────────────────────────────────────────────────
  static String get appTitle => _t(
        en: 'MediQ - OPD Queue Management',
        si: 'MediQ - රෝහල් OPD පෝලිම් කළමනාකරණය',
        ta: 'MediQ - மருத்துவமனை OPD வரிசை மேலாண்மை',
      );

  static String get navHome => _t(en: 'Home', si: 'මුල් පිටුව', ta: 'முகப்பு');
  static String get navAppointments => _t(en: 'Appointments', si: 'හමුවීම්', ta: 'சந்திப்புகள்');
  static String get navLiveQueue => _t(en: 'Live Queue', si: 'සජීවී පෝලිම', ta: 'நேரடி வரிசை');
  static String get navProfile => _t(en: 'Profile', si: 'පැතිකඩ', ta: 'சுயவிவரம்');
  static String get navSenior => _t(en: 'Senior Mode', si: 'වැඩිහිටි ප්‍රකාරය', ta: 'மூத்தோர் பயன்முறை');

  static String get btnConfirm => _t(en: 'Confirm', si: 'තහවුරු කරන්න', ta: 'உறுதி செய்');
  static String get btnCancel => _t(en: 'Cancel', si: 'අවලංගු කරන්න', ta: 'ரத்து செய்');
  static String get btnBack => _t(en: 'Back', si: 'ආපසු', ta: 'பின்னால்');
  static String get btnContinue => _t(en: 'Continue', si: 'ඉදිරියට යන්න', ta: 'தொடரவும்');
  static String get btnSave => _t(en: 'Save Changes', si: 'සුරකින්න', ta: 'சேமிக்க');
  static String get btnClose => _t(en: 'Close', si: 'වසන්න', ta: 'மூடு');
  static String get btnDone => _t(en: 'Done', si: 'ඉවරයි', ta: 'முடிந்தது');
  static String get btnSearch => _t(en: 'Search', si: 'සොයන්න', ta: 'தேடு');
  static String get btnRefresh => _t(en: 'Refresh', si: 'නැවත පූරණය කරන්න', ta: 'புதுப்பி');
  static String get btnLogout => _t(en: 'Log Out', si: 'ඉවත් වන්න', ta: 'வெளியேறு');
  static String get btnSubmit => _t(en: 'Submit', si: 'යොමු කරන්න', ta: 'சமர்ப்பிக்கவும்');

  // ───────────────────────────────────────────────────────────────────────────
  // MODULE 3: WELCOME & AUTHENTICATION
  // ───────────────────────────────────────────────────────────────────────────
  static String get welcomeTitle => _t(
        en: 'MediQ Hospital OPD',
        si: 'MediQ රෝහල් OPD පද්ධතිය',
        ta: 'MediQ மருத்துவமனை OPD',
      );

  static String get welcomeSubtitle => _t(
        en: 'Government Hospital OPD Queue & Appointment System',
        si: 'රජයේ රෝහල් OPD පෝලිම් සහ හමුවීම් පහසුකම',
        ta: 'அரசு மருத்துவமனை OPD வரிசை & சந்திப்பு முறை',
      );

  static String get welcomeFeat1Title => _t(
        en: 'No Need to Wait in Corridors',
        si: 'පෝලිම්වල රස්තියාදු වෙන්න ඕන නෑ',
        ta: 'நீண்ட வரிசையில் காத்திருக்க வேண்டாம்',
      );

  static String get welcomeFeat1Sub => _t(
        en: 'Track your live token position from anywhere',
        si: 'ඕනෑම තැනක ඉඳලා ඔබේ ටෝකන් අංකය බලාගන්න',
        ta: 'எங்கிருந்தும் உங்கள் டோக்கனை கவனிக்கலாம்',
      );

  static String get welcomeFeat2Title => _t(
        en: 'Never Miss Your Turn',
        si: 'ඔබේ වාරය කිසිදා මඟහැරෙන්නේ නැත',
        ta: 'உங்கள் முறை தவறிவிடாது',
      );

  static String get welcomeFeat2Sub => _t(
        en: 'Full-screen loud alerts when your token is called',
        si: 'ඔබේ අංකය කැඳවූ විට පැහැදිලි ඇඟවීමක් ලැබේ',
        ta: 'உங்கள் முறை வரும்போது முழு திரை அறிவிப்பு வரும்',
      );

  static String get welcomeFeat3Title => _t(
        en: 'Caregiver & Senior Friendly',
        si: 'වැඩිහිටියන්ට සහ රැකබලාගන්නන්ට පහසුයි',
        ta: 'மூத்தோர் மற்றும் பராமரிப்பாளர் வசதி',
      );

  static String get welcomeFeat3Sub => _t(
        en: 'Family members can monitor queue progress remotely',
        si: 'පවුලේ අයටත් ගෙදර ඉඳලා පෝලිමේ තත්වය බලන්න පුළුවන්',
        ta: 'குடும்பத்தினர் வீட்டிலிருந்தே நிலையை பார்க்கலாம்',
      );

  static String get btnPatientSignIn => _t(
        en: 'Patient / Caregiver Sign In',
        si: 'රෝගී / රැකබලාගන්නා පිවිසීම',
        ta: 'நோயாளி / பராமரிப்பாளர் உள்நுழைவு',
      );

  static String get btnRegisterPatient => _t(
        en: 'Register New Patient',
        si: 'නව රෝගියෙකු ලියාපදිංචි කරන්න',
        ta: 'புதிய நோயாளி பதிவு',
      );

  static String get btnStaffPortal => _t(
        en: 'Doctor / Hospital Staff Portal',
        si: 'වෛද්‍ය / රෝහල් කාර්ය මණ්ඩල පිවිසුම',
        ta: 'மருத்துவர் / ஊழியர் போர்டல்',
      );

  // Login Screen
  static String get patientLoginTitle => _t(en: 'Patient Sign In', si: 'රෝගී පිවිසීම', ta: 'நோயாளி உள்நுழைவு');
  static String get staffLoginTitle => _t(en: 'Staff / Admin Sign In', si: 'කාර්ය මණ්ඩල / පරිපාලක පිවිසීම', ta: 'ஊழியர் / நிர்வாகி உள்நுழைவு');
  static String get loginSubtitlePatient => _t(
        en: 'Enter your phone number or email to manage your OPD visits',
        si: 'ඔබේ දුරකථන අංකය හෝ ඊමේල් ලිපිනය ඇතුළත් කර පිවිසෙන්න',
        ta: 'உங்கள் தொலைபேசி எண் அல்லது மின்னஞ்சலை உள்ளிடவும்',
      );
  static String get loginSubtitleStaff => _t(
        en: 'Hospital-issued credentials only (Doctor, Nurse, Admin)',
        si: 'රෝහල් කාර්ය මණ්ඩලයට පමණයි (වෛද්‍ය, හෙද, පරිපාලක)',
        ta: 'மருத்துவமனை ஊழியர்களுக்கு மட்டும்',
      );

  static String get labelPhoneOrEmail => _t(en: 'Phone Number or Email', si: 'දුරකථන අංකය හෝ ඊමේල්', ta: 'தொலைபேசி எண் அல்லது மின்னஞ்சல்');
  static String get labelHospitalEmail => _t(en: 'Hospital Email Address', si: 'රෝහල් ඊමේල් ලිපිනය', ta: 'மருத்துவமனை மின்னஞ்சல்');
  static String get labelPassword => _t(en: 'Password', si: 'මුරපදය (Password)', ta: 'கடவுச்சொல்');
  static String get labelEnterPassword => _t(en: 'Enter your password', si: 'ඔබේ මුරපදය ඇතුළත් කරන්න', ta: 'கடவுச்சொல்லை உள்ளிடவும்');
  static String get btnSignIn => _t(en: 'Sign In', si: 'පිවිසෙන්න', ta: 'உள்நுழையவும்');
  static String get btnLoginWithOtp => _t(en: 'Sign in with SMS OTP', si: 'SMS කේතය (OTP) මගින් පිවිසෙන්න', ta: 'SMS OTP மூலம் உள்நுழைக');
  static String get btnLoginWithPassword => _t(en: 'Sign in with Password', si: 'මුරපදයෙන් පිවිසෙන්න', ta: 'கடவுச்சொல் மூலம் உள்நுழைக');
  static String get btnForgotPassword => _t(en: 'Forgot Password?', si: 'මුරපදය අමතකද?', ta: 'கடவுச்சொல் மறந்ததா?');
  static String get dontHaveAccount => _t(en: "Don't have an account?", si: 'ගිණුමක් නැද්ද?', ta: 'கணக்கு இல்லையா?');
  static String get registerNow => _t(en: 'Register now', si: 'ලියාපදිංචි වන්න', ta: 'இப்போதே பதிவு செய்');

  // Registration Screen
  static String get registerTitle => _t(en: 'Register Patient Account', si: 'රෝගී ගිණුමක් තනන්න', ta: 'நோயாளி கணக்கு பதிவு');
  static String get registerSubtitle => _t(
        en: 'Create an account to book OPD appointments and track tokens',
        si: 'OPD හමුවීම් වෙන්කරවා ගැනීමට සහ පෝලිම් බැලීමට ලියාපදිංචි වන්න',
        ta: 'OPD சந்திப்புகளை பதிவு செய்ய கணக்கை உருவாக்கவும்',
      );
  static String get labelFullName => _t(en: 'Full Name', si: 'සම්පූර්ණ නම', ta: 'முழு பெயர்');
  static String get labelPhone => _t(en: 'Mobile Phone Number', si: 'ජංගම දුරකථන අංකය', ta: 'கைபேசி எண்');
  static String get labelNic => _t(en: 'National Identity Card (NIC)', si: 'ජාතික හැඳුනුම්පත් අංකය (NIC)', ta: 'தேசிய அடையாள அட்டை (NIC)');
  static String get labelEmailOptional => _t(en: 'Email Address (Optional)', si: 'ඊමේල් ලිපිනය (විකල්ප)', ta: 'மின்னஞ்சல் (விருப்பத்திற்குரியது)');
  static String get labelCreatePassword => _t(en: 'Create Password', si: 'නව මුරපදයක් ඇතුළත් කරන්න', ta: 'கடவுச்சொல்லை உருவாக்கவும்');
  static String get labelConfirmPassword => _t(en: 'Confirm Password', si: 'මුරපදය තහවුරු කරන්න', ta: 'கடவுச்சொல்லை உறுதிப்படுத்தவும்');
  static String get btnCreateAccount => _t(en: 'Create Account', si: 'ගිණුම තනන්න', ta: 'கணக்கை உருவாக்கு');
  static String get alreadyHaveAccount => _t(en: 'Already have an account?', si: 'දැනටමත් ගිණුමක් තිබේද?', ta: 'ஏற்கனவே கணக்கு உள்ளதா?');

  // SMS Verification
  static String get verifyOtpTitle => _t(en: 'Verify Phone Number', si: 'දුරකථන අංකය තහවුරු කරන්න', ta: 'தொலைபேசி எண்ணை சரிபார்க்கவும்');
  static String get verifyOtpSubtitle => _t(
        en: 'Enter the 6-digit verification code sent to your mobile phone',
        si: 'ඔබගේ දුරකථනයට ලැබුණු ඉලක්කම් 6 කේතය ඇතුළත් කරන්න',
        ta: 'உங்கள் கைபேசிக்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்',
      );
  static String get btnVerifyCode => _t(en: 'Verify & Sign In', si: 'තහවුරු කර පිවිසෙන්න', ta: 'சரிபார்த்து உள்நுழைக');
  static String get btnResendCode => _t(en: 'Resend Code', si: 'නැවත කේතය එවන්න', ta: 'குறியீட்டை மீண்டும் அனுப்பு');

  // Forgot Password
  static String get forgotPasswordTitle => _t(en: 'Reset Password', si: 'මුරපදය නැවත සකසන්න', ta: 'கடவுச்சொல் மீட்டமை');
  static String get forgotPasswordSubtitle => _t(
        en: "Enter your registered email address and we'll send you a password reset link",
        si: 'ඔබගේ ලියාපදිංචි ඊමේල් ලිපිනය ඇතුළත් කළ විට මුරපදය වෙනස් කිරීමට සබැඳියක් ලැබෙනු ඇත',
        ta: 'உங்கள் பதிவு செய்யப்பட்ட மின்னஞ்சலை உள்ளிடவும்',
      );
  static String get btnSendResetLink => _t(en: 'Send Reset Link', si: 'සබැඳිය එවන්න', ta: 'இணைப்பை அனுப்பு');

  // ───────────────────────────────────────────────────────────────────────────
  // MODULE 3: LIVE QUEUE & JOURNEY
  // ───────────────────────────────────────────────────────────────────────────
  static String get liveQueueTitle => _t(en: 'Live OPD Queue', si: 'සජීවී OPD පෝලිම', ta: 'நேரடி OPD வரிசை');
  static String get tokenLabel => _t(en: 'Your Token Number', si: 'ඔබේ ටෝකන් අංකය', ta: 'உங்கள் டோக்கன் எண்');
  static String get currentServingToken => _t(en: 'Current Serving Token', si: 'දැන් කැඳවන අංකය', ta: 'தற்போதைய டோக்கன்');
  static String get peopleAhead => _t(en: 'People Ahead of You', si: 'ඔබට ඉදිරියෙන් සිටින පිරිස', ta: 'உங்களுக்கு முன்னால் உள்ளவர்கள்');
  static String get estWaitTime => _t(en: 'Estimated Wait Time', si: 'අනුමාන රැඳීසිටීමේ කාලය', ta: 'மதிப்பிடப்பட்ட நேரம்');
  static String get minutesShort => _t(en: 'mins', si: 'විනාඩි', ta: 'நிமிடங்கள்');
  static String get clinicRoom => _t(en: 'Consultation Room', si: 'ප්‍රතිකාර කාමරය', ta: 'மருத்துவர் அறை');
  static String get doctorInCharge => _t(en: 'Doctor', si: 'වෛද්‍යවරයා', ta: 'மருத்துவர்');
  static String get viewTimeline => _t(en: 'Queue Timeline', si: 'පෝලිම් කාලරේඛාව', ta: 'வரிசை காலவரிசை');
  static String get viewJourneyMap => _t(en: 'Hospital Journey Map', si: 'රෝහල් මාර්ග සිතියම', ta: 'மருத்துவமனை வரைபடம்');
  static String get noActiveQueue => _t(en: 'No active queue token found', si: 'ක්‍රියාකාරී පෝලිම් අංකයක් නොමැත', ta: 'செயலில் உள்ள டோக்கன் இல்லை');
  static String get bookAppointmentPrompt => _t(
        en: 'Book an OPD appointment to get your live queue token',
        si: 'පෝලිම් අංකයක් ලබාගැනීමට කරුණාකර හමුවීමක් වෙන්කරවා ගන්න',
        ta: 'டோக்கனைப் பெற தயவுசெய்து முன்பதிவு செய்யுங்கள்',
      );

  // States
  static String get yourTurnTitle => _t(en: "IT'S YOUR TURN NOW!", si: 'දැන් ඔබේ වාරයයි!', ta: 'இப்போது உங்கள் முறை!');
  static String get yourTurnSubtitle => _t(
        en: 'Please proceed to your assigned OPD consultation room immediately',
        si: 'කරුණාකර වහාම ඔබේ ප්‍රතිකාර කාමරය වෙත පැමිණෙන්න',
        ta: 'தயவுசெய்து உடனடியாக மருத்துவர் அறைக்கு செல்லவும்',
      );
  static String get queueDelayedTitle => _t(en: 'OPD Queue Delayed', si: 'පෝලිම සුළු වේලාවකට ප්‍රමාදයි', ta: 'வரிசை தாமதமாகிறது');
  static String get queueDelayedSub => _t(
        en: 'The doctor is handling an emergency case. Estimated resumption in a few minutes.',
        si: 'වෛද්‍යවරයා හදිසි රෝගියෙකු පරීක්ෂා කරමින් සිටී. සුළු වේලාවකින් පෝලිම නැවත ආරම්භ වේ.',
        ta: 'அவசர சிகிச்சை காரணமாக வரிசை சிறிது நேரம் தாமதமாகிறது.',
      );
  static String get queueCompletedTitle => _t(en: 'Visit Completed', si: 'ප්‍රතිකාරය අවසන් විය', ta: 'சிகிச்சை முடிந்தது');
  static String get queueCompletedSub => _t(
        en: 'Thank you for using MediQ OPD Service. You can now collect your medicines.',
        si: 'MediQ සේවාව භාවිත කළාට ස්තූතියි. දැන් ඔසුසලෙන් ඖෂධ ලබාගත හැක.',
        ta: 'நன்றி. நீங்கள் மருந்தகத்தில் மருந்துகளை பெற்றுக்கொள்ளலாம்.',
      );
  static String get rejoinQueueTitle => _t(en: 'Rejoin OPD Queue', si: 'නැවත පෝලිමට එකතු වන්න', ta: 'மீண்டும் வரிசையில் சேரவும்');
  static String get rejoinQueueSub => _t(
        en: 'Did you miss your turn? Tap below to rejoin the queue with standard priority.',
        si: 'ඔබේ අංකය මඟහැරුණාද? පහත බොත්තම ඔබා නැවත පෝලිමට එක්වන්න.',
        ta: 'உங்கள் முறை தவறிவிட்டதா? மீண்டும் வரிசையில் சேர அழுத்தவும்.',
      );
  static String get btnRejoin => _t(en: 'Rejoin Queue', si: 'නැවත පෝලිමට එක්වන්න', ta: 'மீண்டும் வரிசையில் சேரவும்');

  // ───────────────────────────────────────────────────────────────────────────
  // MODULE 1: APPOINTMENT SCHEDULING
  // ───────────────────────────────────────────────────────────────────────────
  static String get selectHospitalTitle => _t(en: 'Select Hospital', si: 'රෝහල තෝරන්න', ta: 'மருத்துவமனையை தேர்வு செய்');
  static String get searchHospitalHint => _t(en: 'Search hospital by name or district...', si: 'නම හෝ දිස්ත්‍රික්කය අනුව සොයන්න...', ta: 'பெயர் மூலம் தேடுக...');
  static String get selectClinicTitle => _t(en: 'Select OPD Clinic', si: 'OPD සායනය තෝරන්න', ta: 'OPD கிளினிக் தேர்வு செய்');
  static String get selectDateTitle => _t(en: 'Select Appointment Date', si: 'හමුවීමේ දිනය තෝරන්න', ta: 'தேதியை தேர்வு செய்');
  static String get selectTimeSlotTitle => _t(en: 'Select 1-Hour Time Slot', si: 'වේලා කලාපය තෝරන්න', ta: 'நேரத்தை தேர்வு செய்');
  static String get slotCapacityWarning => _t(en: 'Slot capacity limited to 25 patients (MoH guideline)', si: 'එක් වේලාවකට රෝගීන් 25ක් පමණි', ta: 'ஒரு நேரத்திற்கு 25 நோயாளிகள் மட்டுமே');
  static String get reviewAppointmentTitle => _t(en: 'Appointment Summary', si: 'හමුවීමේ විස්තර සාරාංශය', ta: 'முன்பதிவு சுருக்கம்');
  static String get bookingConfirmedTitle => _t(en: 'Booking Confirmed!', si: 'හමුවීම සාර්ථකව වෙන්කරවා ගත්තා!', ta: 'முன்பதிவு உறுதியானது!');
  static String get bookingConfirmedSub => _t(
        en: 'Your digital token has been generated. Please arrive 15 minutes before your slot.',
        si: 'ඔබගේ ඩිජිටල් ටෝකනය නිකුත් කෙරිණි. නියමිත වේලාවට මිනිත්තු 15 කට පෙර පැමිණෙන්න.',
        ta: 'உங்கள் டோக்கன் தயாராக உள்ளது. நேரத்திற்கு 15 நிமிடம் முன் வரவும்.',
      );

  // Senior Mode
  static String get seniorModeTitle => _t(en: 'Senior & Accessibility Mode', si: 'වැඩිහිටි සහ පහසු ප්‍රකාරය', ta: 'மூத்தோர் மற்றும் வசதி பயன்முறை');
  static String get largeTextLabel => _t(en: 'Large Text (1.22x scaling)', si: 'විශාල අකුරු (පැහැදිලිව කියවීමට)', ta: 'பெரிய எழுத்துக்கள்');
  static String get highContrastLabel => _t(en: 'Eye-friendly Dark Slate Theme', si: 'ඇසට පහසු තද පසුබිම', ta: 'கண்ணுக்கு இதமான இருண்ட நிறம்');
  static String get simplifiedNavLabel => _t(en: 'Simplified 3-Tab Navigation', si: 'සරල සංචාලන පුවරුව', ta: 'எளிய வழிகாட்டல்');
  static String get voiceGuidanceLabel => _t(en: 'Voice Status Announcements', si: 'හඬ මඟපෙන්වීම්', ta: 'குரல் அறிவிப்புகள்');

  // Caregiver Setup
  static String get caregiverTitle => _t(en: 'Caregiver & Dependent Setup', si: 'රැකබලාගන්නන්ගේ සැකසුම', ta: 'பராமரிப்பாளர் அமைப்பு');
  static String get bookingForSelf => _t(en: 'Booking for Myself', si: 'මා වෙනුවෙන් වෙන්කරවා ගැනීම', ta: 'எனக்காக முன்பதிவு');
  static String get bookingForFamily => _t(en: 'Booking for Family Member / Elder', si: 'පවුලේ සාමාජිකයෙකු වෙනුවෙන්', ta: 'குடும்பத்தினர் / முதியோருக்காக');

  // ───────────────────────────────────────────────────────────────────────────
  // MODULE 2: TOKENS & NOTIFICATIONS
  // ───────────────────────────────────────────────────────────────────────────
  static String get myAppointmentsTitle => _t(en: 'My OPD Appointments', si: 'මගේ හමුවීම්', ta: 'என் சந்திப்புகள்');
  static String get digitalTokenTitle => _t(en: 'Digital OPD Token', si: 'ඩිජිටල් OPD ටෝකනය', ta: 'டிஜிட்டல் OPD டோக்கன்');
  static String get tokenStatusBooked => _t(en: 'Booked', si: 'වෙන්කර ඇත', ta: 'முன்பதிவு செய்யப்பட்டது');
  static String get tokenStatusWaiting => _t(en: 'Waiting in Queue', si: 'පෝලිමේ රැඳී සිටී', ta: 'வரிசையில் காத்திருக்கிறது');
  static String get tokenStatusCalled => _t(en: 'Called to Room', si: 'කාමරයට කැඳවා ඇත', ta: 'அழைக்கப்பட்டது');
  static String get tokenStatusCompleted => _t(en: 'Completed', si: 'අවසන් විය', ta: 'முடிந்தது');
  static String get btnReschedule => _t(en: 'Reschedule', si: 'දිනය වෙනස් කරන්න', ta: 'தேதியை மாற்றுக');
  static String get btnCancelAppointment => _t(en: 'Cancel Appointment', si: 'හමුවීම අවලංගු කරන්න', ta: 'ரத்து செய்');
  static String get notificationCentreTitle => _t(en: 'Notification Centre', si: 'දැනුම්දීම් මධ්‍යස්ථානය', ta: 'அறிவிப்பு மையம்');

  // ───────────────────────────────────────────────────────────────────────────
  // MODULE 4: STAFF OPERATIONS
  // ───────────────────────────────────────────────────────────────────────────
  static String get staffDashboardTitle => _t(en: 'Staff OPD Console', si: 'කාර්ය මණ්ඩල පාලක පුවරුව', ta: 'ஊழியர் பணியகம்');
  static String get btnCallNext => _t(en: 'Call Next Patient', si: 'ඊළඟ රෝගියා කැඳවන්න', ta: 'அடுத்த நோயாளியை அழைக்கவும்');
  static String get btnPauseQueue => _t(en: 'Pause Queue', si: 'පෝලිම මඳක් නවත්වන්න', ta: 'வரிசையை இடைநிறுத்து');
  static String get btnEmergencyPriority => _t(en: 'Emergency Priority', si: 'හදිසි ප්‍රතිකාර ප්‍රමුඛතාව', ta: 'அவசர சிகிச்சை முன்னுரிமை');
  static String get btnBroadcastDelay => _t(en: 'Broadcast Delay Notice', si: 'ප්‍රමාදය ගැන දැනුම් දෙන්න', ta: 'தாமத அறிவிப்பை அனுப்பு');
  static String get receptionistMonitorTitle => _t(en: 'Receptionist Queue Monitor', si: 'පිළිගැනීමේ පෝලිම් නිරීක්ෂකය', ta: 'வரவேற்பாளர் வரிசை கண்காணிப்பாளர்');

  // ───────────────────────────────────────────────────────────────────────────
  // ADMIN CONSOLE
  // ───────────────────────────────────────────────────────────────────────────
  static String get adminDashboardTitle => _t(en: 'Admin Dashboard', si: 'පරිපාලක පාලක පුවරුව', ta: 'நிர்வாக டாஷ்போர்டு');
  static String get adminUsersTitle => _t(en: 'Users & Account Access', si: 'පරිශීලක ගිණුම් කළමනාකරණය', ta: 'பயனர்கள் & அணுகல்');
  static String get adminAppointmentsTitle => _t(en: 'Hospital & OPD Scheduling', si: 'රෝහල් සහ හමුවීම් සැකසුම්', ta: 'மருத்துவமனை & அட்டவணை');
  static String get adminTokensTitle => _t(en: 'Tokens & Notification Rules', si: 'ටෝකන් සහ දැනුම්දීම් නීති', ta: 'டோக்கன்கள் & அறிவிப்புகள்');
  static String get adminStaffQueuesTitle => _t(en: 'Queue & Staff Operations', si: 'පෝලිම් සහ කාර්ය මණ්ඩල මෙහෙයුම්', ta: 'வரிசை & ஊழியர் செயல்பாடுகள்');

  // Helper
  static String _t({required String en, required String si, required String ta}) {
    switch (AppLanguage.currentLanguage.value) {
      case 'si':
        return si;
      case 'ta':
        return ta;
      case 'en':
      default:
        return en;
    }
  }
}
