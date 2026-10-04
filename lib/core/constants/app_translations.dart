import 'app_accessibility.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // English
    'en': {
      'appName': 'MediQ',
      'navHome': 'Home',
      'navAppointments': 'Book OPD',
      'navQueue': 'Live Queue',
      'navAlerts': 'SMS & Alerts',
      'navProfile': 'Profile',
      
      // Accessibility
      'accessibility': 'Accessibility & Senior Mode',
      'settings': 'Settings',
      'language': 'App Language',
      'selectLanguage': 'Select App Language',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'largeText': 'Large Text Mode',
      'largeTextDesc': 'Enlarges all labels, tokens & hospital text',
      'highContrast': 'High Contrast Mode',
      'highContrastDesc': 'Eye-friendly soothing dark slate medical theme',
      'simplifiedNav': 'Simplified Navigation',
      'simplifiedNavDesc': 'Reduces navigation to 3 large essential tabs',
      'voiceGuidance': 'Voice Guidance (TTS)',
      'voiceGuidanceDesc': 'Spoken audio announcements for tokens & navigation',
      
      // Home
      'welcome': 'Welcome to OPD Portal',
      'bookNewOpd': 'Book OPD Appointment',
      'trackLiveQueue': 'Track Live OPD Queue',
      'patientDependents': 'Family Dependents',
      'hospitalGuidelines': 'OPD Arrival Guidelines',
      
      // Step 1
      'step1Title': 'Step 1 of 5: Patient Details',
      'whoIsAppointmentFor': 'Who is this appointment for?',
      'chooseOptionBelow': 'Please choose an option below to proceed with government OPD booking.',
      'myself': 'Booking for Myself',
      'myselfDesc': 'I am the primary patient receiving OPD consultation.',
      'someoneElse': 'Booking for Someone Else',
      'someoneElseDesc': 'I am a caregiver booking for a parent, child, or dependent.',
      'patientFullName': 'Patient Full Name *',
      'nicOrBirthCert': 'NIC / Birth Certificate No *',
      'relationship': 'Relationship to Patient *',
      'specialPriority': 'Special Priority Category',
      'continueToHospital': 'Continue to Hospital Selection',
      'standardPriority': 'Standard',
      'elderlyPriority': 'Elderly (60+)',
      'wheelchairPriority': 'Wheelchair',
      'maternityPriority': 'Maternity',
      'savedDependents': 'Saved Family Dependents (Tap to auto-fill)',
      
      // Step 2
      'step2Title': 'Step 2 of 5: Hospital Selection',
      'chooseHospital': 'Choose OPD Hospital',
      'chooseHospitalSubtitle': 'Select the closest national or teaching hospital for consultation.',
      'searchHospital': 'Search hospital name, city, or district...',
      'openToday': 'Open Today',
      'clinicsCount': 'Clinics',
      'nextClinic': 'Next: OPD Clinic',
      
      // Step 3
      'step3Title': 'Step 3 of 5: OPD Clinic Selection',
      'availableDepartments': 'Available OPD Departments',
      'availableDepartmentsSubtitle': 'Select the relevant medical specialty clinic for your consultation.',
      'selectedHospital': 'SELECTED HOSPITAL',
      'nextDate': 'Next: Select Date',
      
      // Step 4
      'step4Title': 'Step 4 of 5: Date Selection',
      'chooseDate': 'Choose Clinic Date',
      'chooseDateSubtitle': 'Select an available date on the OPD calendar for consultation.',
      'selectedDateHeader': 'SELECTED APPOINTMENT DATE',
      'continueToSlots': 'Continue to Time Slots',
      'nextSlot': 'Next: Time Slot',
      
      // Step 5
      'step5Title': 'Step 5 of 5: Time Slot Selection',
      'morningSession': 'Morning Session',
      'afternoonSession': 'Afternoon Session',
      'spotsLeft': 'spots left',
      'slotCappingNotice': 'Slots are capped at 25 patients to minimize clinic waiting hall delays.',
      'reviewAppointment': 'Review Appointment',
      'available': 'Available',
      'fillingFast': 'Filling Fast',
      'fullLocked': 'Full / Locked',
      'nextReview': 'Next: Review & Confirm',
      
      // Review & Confirmation
      'reviewTitle': 'Review Appointment',
      'ministryBanner': 'Ministry of Health Sri Lanka',
      'ministryBannerDesc': 'Please review your OPD clinic appointment details carefully before final submission.',
      'patientInfo': 'Patient Information',
      'hospitalDetails': 'Hospital & Clinic Details',
      'arrivalGuidance': 'Important Arrival Guidance',
      'confirmAppointment': 'Confirm Appointment',
      'appointmentConfirmed': 'Appointment Confirmed!',
      'confirmedSubtitle': 'Your OPD digital appointment token has been recorded.',
      'tokenPass': 'OPD QUEUE TOKEN',
      'activeStatus': '● ACTIVE',
      'savePass': 'Save Pass',
      'myProfile': 'My Profile',
      'backToHome': 'Back to Hospital Home',
      
      // Profile
      'patientProfile': 'Patient Profile',
      'editProfile': 'Edit Profile',
      'saveChanges': 'Save Profile Changes',
      'verifiedPatient': 'Verified Patient',
      'addDependent': 'Add Family Dependent',
      'upcomingAppointments': 'Upcoming',
      'pastAppointments': 'Past',
      'viewTokenPass': 'View Digital Token Pass',
      'cancel': 'Cancel',
      'changePhoto': 'Change Profile Photo',
    },
    
    // Sinhala
    'si': {
      'appName': 'MediQ',
      'navHome': 'මුල් පිටුව',
      'navAppointments': 'සායන වෙන්කිරීම',
      'navQueue': 'පෝලිම',
      'navAlerts': 'දැනුම්දීම්',
      'navProfile': 'පැතිකඩ',
      
      // Accessibility
      'accessibility': 'ප්‍රවේශ්‍යතාව සහ වැඩිහිටි මාදිලිය',
      'settings': 'සැකසුම්',
      'language': 'යෙදුම් භාෂාව',
      'selectLanguage': 'භාෂාව තෝරන්න',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'largeText': 'විශාල අකුරු මාදිලිය',
      'largeTextDesc': 'වැඩිහිටියන්ට පහසුවෙන් කියවිය හැකි පරිදි අකුරු විශාල කරයි',
      'highContrast': 'අඳුරු මාදිලිය (Dark Theme)',
      'highContrastDesc': 'ඇස් වලට සුවපහසු අඳුරු වෛද්‍ය තේමාව',
      'simplifiedNav': 'සරල කළ සංචලනය',
      'simplifiedNavDesc': 'ප්‍රධාන ටැබ් 3කට පමණක් සීමා කර සරල කරයි',
      'voiceGuidance': 'හඬ මගපෙන්වීම (TTS)',
      'voiceGuidanceDesc': 'ටෝකන් සහ තිර විස්තර ශබ්ද නගා කියවයි',
      
      // Home
      'welcome': 'OPD සේවාව වෙත සාදරයෙන් පිළිගනිමු',
      'bookNewOpd': 'නව සායනයක් වෙන්කරවා ගැනීම',
      'trackLiveQueue': 'සජීවී පෝලිම නිරීක්ෂණය',
      'patientDependents': 'පවුලේ යැපෙන්නන්',
      'hospitalGuidelines': 'සායන පැමිණීමේ උපදෙස්',
      
      // Step 1
      'step1Title': 'පියවර 1/5: රෝගියාගේ විස්තර',
      'whoIsAppointmentFor': 'මෙම වෙන්කරවා ගැනීම කා සඳහාද?',
      'chooseOptionBelow': 'රජයේ OPD සායන වෙන්කරවා ගැනීම සඳහා කරුණාකර පහතින් විකල්පයක් තෝරන්න.',
      'myself': 'මා වෙනුවෙන් වෙන්කරවා ගැනීම',
      'myselfDesc': 'මම සායනික උපදෙස් ලබාගන්නා ප්‍රධාන රෝගියා වෙමි.',
      'someoneElse': 'වෙනත් අයෙකු වෙනුවෙන් (භාරකරු)',
      'someoneElseDesc': 'මම මව්පියන්, දරුවන් හෝ යැපෙන්නෙකු වෙනුවෙන් වෙන්කරමි.',
      'patientFullName': 'රෝගියාගේ සම්පූර්ණ නම *',
      'nicOrBirthCert': 'ජාතික හැඳුනුම්පත් හෝ උප්පැන්න අංකය *',
      'relationship': 'රෝගියාට ඇති ඥාතිත්වය *',
      'specialPriority': 'විශේෂ ප්‍රමුඛතා කාණ්ඩය',
      'continueToHospital': 'රෝහල තේරීමට ඉදිරියට යන්න',
      'standardPriority': 'සාමාන්‍ය',
      'elderlyPriority': 'වැඩිහිටි (60+)',
      'wheelchairPriority': 'රෝද පුටු',
      'maternityPriority': 'මාතෘ',
      'savedDependents': 'සුරකින ලද පවුලේ සාමාජිකයන් (තේරීමට ඔබන්න)',
      
      // Step 2
      'step2Title': 'පියවර 2/5: රෝහල තේරීම',
      'chooseHospital': 'රජයේ රෝහල තෝරන්න',
      'chooseHospitalSubtitle': 'සායනය සඳහා ළඟම ඇති ජාතික හෝ ශික්ෂණ රෝහල තෝරන්න.',
      'searchHospital': 'රෝහලේ නම, නගරය හෝ දිස්ත්‍රික්කය සොයන්න...',
      'openToday': 'අද විවෘතයි',
      'clinicsCount': 'සායන',
      'nextClinic': 'ඊළඟ: සායනය තේරීම',
      
      // Step 3
      'step3Title': 'පියවර 3/5: OPD සායනය තේරීම',
      'availableDepartments': 'පවතින OPD සායන අංශ',
      'availableDepartmentsSubtitle': 'ඔබේ ප්‍රතිකාරයට අදාළ විශේෂඥ සායන අංශය තෝරන්න.',
      'selectedHospital': 'තෝරාගත් රෝහල',
      'nextDate': 'ඊළඟ: දිනය තේරීම',
      
      // Step 4
      'step4Title': 'පියවර 4/5: දිනය තේරීම',
      'chooseDate': 'සායන දිනය තෝරන්න',
      'chooseDateSubtitle': 'සායනය සඳහා පහසු දිනයක් දින දර්ශනයෙන් තෝරන්න.',
      'selectedDateHeader': 'තෝරාගත් සායන දිනය',
      'continueToSlots': 'වේලාව තේරීමට ඉදිරියට යන්න',
      'nextSlot': 'ඊළඟ: වේලාව තේරීම',
      
      // Step 5
      'step5Title': 'පියවර 5/5: වේලාව තේරීම',
      'morningSession': 'උදෑසන සැසිය',
      'afternoonSession': 'පස්වරු සැසිය',
      'spotsLeft': 'ඉතිරි ඉඩ',
      'slotCappingNotice': 'තදබදය අවම කිරීමට එක් සැසියකට රෝගීන් 25කට සීමා කර ඇත.',
      'reviewAppointment': 'තොරතුරු පරීක්ෂා කරන්න',
      'available': 'ඇබෑර්තු ඇත',
      'fillingFast': 'ඉක්මනින් පිරේ',
      'fullLocked': 'පිරී ඇත / අවහිරයි',
      'nextReview': 'ඊළඟ: තහවුරු කිරීම',
      
      // Review & Confirmation
      'reviewTitle': 'වෙන්කරවා ගැනීම පරීක්ෂා කිරීම',
      'ministryBanner': 'සෞඛ්‍ය අමාත්‍යාංශය - ශ්‍රී ලංකා',
      'ministryBannerDesc': 'අවසන් තහවුරු කිරීමට පෙර ඔබේ සායන තොරතුරු හොඳින් පරීක්ෂා කරන්න.',
      'patientInfo': 'රෝගියාගේ තොරතුරු',
      'hospitalDetails': 'රෝහල සහ සායන විස්තර',
      'arrivalGuidance': 'වැදගත් පැමිණීමේ උපදෙස්',
      'confirmAppointment': 'වෙන්කරවා ගැනීම තහවුරු කරන්න',
      'appointmentConfirmed': 'සායන වෙන්කරවා ගැනීම සාර්ථකයි!',
      'confirmedSubtitle': 'ඔබේ ඩිජිටල් OPD ටෝකනය සාර්ථකව පද්ධතියේ සටහන් විය.',
      'tokenPass': 'OPD පෝලිම් ටෝකනය',
      'activeStatus': '● සක්‍රියයි',
      'savePass': 'ටෝකනය සුරකින්න',
      'myProfile': 'මගේ පැතිකඩ',
      'backToHome': 'මුල් පිටුවට',
      
      // Profile
      'patientProfile': 'රෝගියාගේ පැතිකඩ',
      'editProfile': 'පැතිකඩ සංස්කරණය',
      'saveChanges': 'වෙනස්කම් සුරකින්න',
      'verifiedPatient': 'තහවුරු කළ රෝගියා',
      'addDependent': 'පවුලේ සාමාජිකයෙකු එක්කරන්න',
      'upcomingAppointments': 'ඉදිරි සායන',
      'pastAppointments': 'පසුගිය සායන',
      'viewTokenPass': 'ඩිජිටල් ටෝකන් පත බලන්න',
      'cancel': 'අවලංගු කරන්න',
      'changePhoto': 'ඡායාරූපය මාරු කරන්න',
    },
    
    // Tamil
    'ta': {
      'appName': 'MediQ',
      'navHome': 'முகப்பு',
      'navAppointments': 'OPD பதிவு',
      'navQueue': 'வரிசை',
      'navAlerts': 'எச்சரிக்கைகள்',
      'navProfile': 'சுயவிவரம்',
      
      // Accessibility
      'accessibility': 'அணுகல்தன்மை மற்றும் முதியோர் பயன்முறை',
      'settings': 'அமைப்புகள்',
      'language': 'பயன்பாட்டு மொழி',
      'selectLanguage': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'largeText': 'பெரிய உரை பயன்முறை',
      'largeTextDesc': 'முதியவர்கள் எளிதில் படிக்க உரைகளை பெரிதாக்குகிறது',
      'highContrast': 'இருண்ட தீம் (Dark Theme)',
      'highContrastDesc': 'கண்களுக்கு உகந்த அமைதியான இருண்ட தீம்',
      'simplifiedNav': 'எளிமைப்படுத்தப்பட்ட வழிசெலுத்தல்',
      'simplifiedNavDesc': '3 அத்தியாவசிய தாவல்களாக குறைக்கிறது',
      'voiceGuidance': 'குரல் வழிகாட்டுதல் (TTS)',
      'voiceGuidanceDesc': 'டோக்கன்கள் மற்றும் தகவல்களை குரல் மூலம் அறிவிக்கிறது',
      
      // Home
      'welcome': 'OPD சேவைக்கு வரவேற்கிறோம்',
      'bookNewOpd': 'புதிய OPD முன்பதிவு',
      'trackLiveQueue': 'நேரடி வரிசையைக் கண்காணிக்கவும்',
      'patientDependents': 'குடும்ப உறுப்பினர்கள்',
      'hospitalGuidelines': 'மருத்துவமனை வருகை வழிகாட்டுதல்கள்',
      
      // Step 1
      'step1Title': 'படி 1/5: நோயாளி விவரங்கள்',
      'whoIsAppointmentFor': 'இந்த முன்பதிவு யாருக்காக?',
      'chooseOptionBelow': 'அரசு OPD முன்பதிவுக்கு கீழே உள்ள விருப்பத்தைத் தேர்ந்தெடுக்கவும்.',
      'myself': 'எனக்கான முன்பதிவு',
      'myselfDesc': 'ஆலோசனை பெறும் முதன்மை நோயாளி நான்.',
      'someoneElse': 'வேறொருவருக்கு (பராமரிப்பாளர்)',
      'someoneElseDesc': 'பெற்றோர் அல்லது குழந்தைகளுக்காக நான் முன்பதிவு செய்கிறேன்.',
      'patientFullName': 'நோயாளியின் முழுப் பெயர் *',
      'nicOrBirthCert': 'அடையாள அட்டை அல்லது பிறப்புச் சான்றிதழ் *',
      'relationship': 'நோயாளிக்கான உறவுமுறை *',
      'specialPriority': 'சிறப்பு முன்னுரிமை பிரிவு',
      'continueToHospital': 'மருத்துவமனை தேர்வுக்கு தொடரவும்',
      'standardPriority': 'இயல்பான',
      'elderlyPriority': 'முதியோர் (60+)',
      'wheelchairPriority': 'சக்கர நாற்காலி',
      'maternityPriority': 'கர்ப்பிணி',
      'savedDependents': 'சேமிக்கப்பட்ட குடும்ப உறுப்பினர்கள்',
      
      // Step 2
      'step2Title': 'படி 2/5: மருத்துவமனை தேர்வு',
      'chooseHospital': 'OPD மருத்துவமனையைத் தேர்வுசெய்க',
      'chooseHospitalSubtitle': 'அருகிலுள்ள தேசிய அல்லது போதனா மருத்துவமனையைத் தேர்ந்தெடுக்கவும்.',
      'searchHospital': 'மருத்துவமனை பெயர் அல்லது நகரைத் தேடுங்கள்...',
      'openToday': 'இன்று திறந்துள்ளது',
      'clinicsCount': 'கிளினிக்குகள்',
      'nextClinic': 'அடுத்து: கிளினிக் தேர்வு',
      
      // Step 3
      'step3Title': 'படி 3/5: OPD கிளினிக் தேர்வு',
      'availableDepartments': 'கிடைக்கக்கூடிய OPD பிரிவுகள்',
      'availableDepartmentsSubtitle': 'உங்கள் சிகிச்சைக்கான சிறப்பு மருத்துவப் பிரிவைத் தேர்ந்தெடுக்கவும்.',
      'selectedHospital': 'தேர்ந்தெடுக்கப்பட்ட மருத்துவமனை',
      'nextDate': 'அடுத்து: தேதி தேர்வு',
      
      // Step 4
      'step4Title': 'படி 4/5: தேதி தேர்வு',
      'chooseDate': 'கிளினிக் தேதியைத் தேர்வுசெய்க',
      'chooseDateSubtitle': 'நாட்காட்டியில் இருந்து பொருத்தமான தேதியைத் தேர்ந்தெடுக்கவும்.',
      'selectedDateHeader': 'தேர்ந்தெடுக்கப்பட்ட கிளினிக் தேதி',
      'continueToSlots': 'நேர இடைவெளிக்குத் தொடரவும்',
      'nextSlot': 'அடுத்து: நேரம் தேர்வு',
      
      // Step 5
      'step5Title': 'படி 5/5: நேர இடைவெளி தேர்வு',
      'morningSession': 'காலை அமர்வு',
      'afternoonSession': 'மதிய அமர்வு',
      'spotsLeft': 'இடங்கள் உள்ளன',
      'slotCappingNotice': 'நெரிசலைத் தவிர்க்க ஒரு அமர்வுக்கு 25 நோயாளிகள் மட்டுமே.',
      'reviewAppointment': 'முன்பதிவை மதிப்பாய்வு செய்க',
      'available': 'கிடைக்கும்',
      'fillingFast': 'விரைவாக நிறைகிறது',
      'fullLocked': 'நிரம்பியது / மூடப்பட்டது',
      'nextReview': 'அடுத்து: உறுதிப்படுத்தல்',
      
      // Review & Confirmation
      'reviewTitle': 'முன்பதிவு மதிப்பாய்வு',
      'ministryBanner': 'சுகாதார அமைச்சு - இலங்கை',
      'ministryBannerDesc': 'இறுதி உறுதிப்படுத்தலுக்கு முன் உங்கள் விவரங்களை சரிபார்க்கவும்.',
      'patientInfo': 'நோயாளி தகவல்',
      'hospitalDetails': 'மருத்துவமனை மற்றும் கிளினிக் விவரங்கள்',
      'arrivalGuidance': 'முக்கியமான வருகை வழிகாட்டுதல்கள்',
      'confirmAppointment': 'முன்பதிவை உறுதிசெய்க',
      'appointmentConfirmed': 'முன்பதிவு உறுதி செய்யப்பட்டது!',
      'confirmedSubtitle': 'உங்கள் டிஜிட்டல் டோக்கன் வெற்றிகரமாக பதிவு செய்யப்பட்டது.',
      'tokenPass': 'OPD வரிசை டோக்கன்',
      'activeStatus': '● செயலில் உள்ளது',
      'savePass': 'டோக்கனை சேமிக்க',
      'myProfile': 'எனது சுயவிவரம்',
      'backToHome': 'முகப்புக்குத் திரும்பு',
      
      // Profile
      'patientProfile': 'நோயாளி சுயவிவரம்',
      'editProfile': 'சுயவிவரத்தைத் திருத்துக',
      'saveChanges': 'மாற்றங்களைச் சேமிக்கவும்',
      'verifiedPatient': 'சரிபார்க்கப்பட்ட நோயாளி',
      'addDependent': 'குடும்ப உறுப்பினரைச் சேர்க்க',
      'upcomingAppointments': 'வரவிருக்கும் கிளினிக்குகள்',
      'pastAppointments': 'கடந்த கால கிளினிக்குகள்',
      'viewTokenPass': 'டிஜிட்டல் டோக்கன் அட்டை',
      'cancel': 'ரத்துசெய்',
      'changePhoto': 'புகைப்படத்தை மாற்றுக',
    },
  };

  /// Get translation string for given key based on active language
  static String tr(String key) {
    final lang = AppAccessibility.currentLanguage.value;
    final dict = _translations[lang] ?? _translations['en']!;
    return dict[key] ?? _translations['en']![key] ?? key;
  }
}
