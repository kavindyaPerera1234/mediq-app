import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../../patient_appointment_scheduling_module1/backend/services/profile_service.dart';
import 'appointment_details_screen.dart';
import '../../patient_appointment_scheduling_module1/screens/caregiver_setup_screen.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import 'digital_token_details_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
    const MyAppointmentsScreen({
        super.key,
        this.initialTab = 0,
    });
    final int initialTab;
    @override
    State<MyAppointmentsScreen> createState() =>
        _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
    int selectedTab = 0;
    final List<String> tabs = [
        "Upcoming",
        "Completed",
        "Cancelled",
    ];

    final AppointmentService _appointmentService = AppointmentService();
    List<AppointmentModel> appointments = [];
    bool isLoading = true;

    String get _currentPatientId {
      try {
        final profile = ProfileService.activeProfileNotifier.value;
        if (profile.nic.isNotEmpty && profile.nic != 'N/A') return profile.nic.trim();
        if (profile.patientId.isNotEmpty) return profile.patientId.trim();
      } catch (_) {}
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.nic != null && user.nic!.trim().isNotEmpty) return user.nic!.trim();
        if (user.phoneNumber.trim().isNotEmpty) return user.phoneNumber.trim();
        if (user.userId.isNotEmpty) return user.userId.trim();
      }
      return '200164801234';
    }

    @override
    void initState() {
        super.initState();  
        selectedTab = widget.initialTab;
        loadAppointments();
    }
    Future<void> loadAppointments() async {
        setState(() => isLoading = true);
        final data = await _appointmentService.getUpcomingAppointments(
            _currentPatientId,
        );
        debugPrint("UI received appointments: ${data.length}");
        if (!mounted) return;
        setState(() {
            appointments = data;
            isLoading = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            AppAccessibility.isHighContrastMode,
            AppAccessibility.currentLanguage,
          ]),
          builder: (context, _) {
            final isDark = AppAccessibility.isHighContrastMode.value;
            final lang = AppAccessibility.currentLanguage.value;

            final String pageTitle = lang == 'si'
                ? "මගේ සායන වෙන්කිරීම්"
                : (lang == 'ta' ? "எனது சந்திப்புகள்" : "My Appointments");
            final String pageSubtitle = lang == 'si'
                ? "ඔබගේ OPD සායන කළමනාකරණය"
                : (lang == 'ta' ? "உங்கள் OPD சந்திப்புகளை நிர்வகிக்கவும்" : "Manage your OPD visits");

            final List<String> tabTitles = [
              lang == 'si' ? "ඉදිරි සායන" : (lang == 'ta' ? "வரவிருக்கும்" : "Upcoming"),
              lang == 'si' ? "අවසන් වූ" : (lang == 'ta' ? "முடிந்தவை" : "Completed"),
              lang == 'si' ? "අවලංගු කළ" : (lang == 'ta' ? "ரத்துசெய்தவை" : "Cancelled"),
            ];

            final String bookBtnText = lang == 'si'
                ? "නව සායනයක් වෙන්කරවා ගැනීම"
                : (lang == 'ta' ? "புதிய சந்திப்பை பதிவு செய்யவும்" : "Book New Appointment");

            return Scaffold(
                backgroundColor: AppColors.pageBg,
                appBar: AppBar(
                    backgroundColor: AppColors.appBarBg,
                    foregroundColor: Colors.white,
                    elevation: isDark ? 1 : 0,
                    leading: Navigator.canPop(context) ? IconButton(
                        icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                        ),
                        onPressed: (){
                            Navigator.pop(context);
                        },
                    ) : null,

                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                pageTitle,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                ),
                            ),
                            Text(
                                pageSubtitle,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                ),
                            ),
                        ],
                    ),
                ),

                body: Column(
                    children: [
                        // Tabs
                        Container(
                            color: AppColors.cardSurface,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: List.generate(
                                    tabTitles.length,
                                    (index){
                                        bool active = selectedTab == index;
                                        return GestureDetector(
                                            onTap: (){
                                                setState((){
                                                    selectedTab = index;
                                                });
                                            },
                                            child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                decoration: BoxDecoration(
                                                    border: Border(
                                                        bottom: BorderSide(
                                                            color: active
                                                            ? AppColors.accentColor
                                                            : Colors.transparent,
                                                            width: 2.5,
                                                        ),
                                                    ),
                                                ),
                                                child: Text(
                                                    tabTitles[index],
                                                    style: TextStyle(
                                                        color: active
                                                        ? AppColors.accentColor
                                                        : AppColors.bodyText,
                                                        fontWeight: active
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    ),
                                                ),
                                            ),
                                        );
                                    },
                                ),
                            ),
                        ),
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    children: [
                                        Expanded(
                                            child: StreamBuilder<List<AppointmentModel>>(
                                                stream: _appointmentService.streamUpcomingAppointments(_currentPatientId),
                                                builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting && appointments.isEmpty) {
                                                        return const Center(child: CircularProgressIndicator());
                                                    }
                                                    final list = snapshot.data ?? appointments;
                                                    final filtered = list.where((appointment) {
                                                        final st = appointment.status.toLowerCase().trim();
                                                        if (selectedTab == 0) {
                                                            return st == "confirmed" ||
                                                                st == "rescheduled" ||
                                                                st == "waiting" ||
                                                                st == "scheduled" ||
                                                                st == "called" ||
                                                                st == "serving" ||
                                                                st == "in_consultation" ||
                                                                st == "arrived" ||
                                                                st == "on_hold";
                                                        }
                                                        if (selectedTab == 1) {
                                                            return st == "completed";
                                                        }
                                                        if (selectedTab == 2) {
                                                            return st == "cancelled";
                                                        }
                                                        return false;
                                                    }).toList();

                                                    if (filtered.isEmpty) {
                                                        final currentTabTitle = tabTitles[selectedTab];
                                                        return Center(
                                                            child: Padding(
                                                                padding: const EdgeInsets.all(32.0),
                                                                child: Column(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                        Icon(Icons.event_note_outlined, size: 64, color: isDark ? AppColors.accentColor : Colors.grey.shade400),
                                                                        const SizedBox(height: 16),
                                                                        Text(
                                                                            lang == 'si'
                                                                                ? "$currentTabTitle කිසිවක් නොමැත"
                                                                                : (lang == 'ta' ? "$currentTabTitle எதுவும் இல்லை" : "No $currentTabTitle appointments"),
                                                                            style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: AppColors.headingText,
                                                                            ),
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        Text(
                                                                            selectedTab == 0
                                                                                ? (lang == 'si'
                                                                                    ? "ඔබ මෙතෙක් කිසිදු ඉදිරි සායන වාරයක් වෙන්කර නොමැත."
                                                                                    : (lang == 'ta'
                                                                                        ? "நீங்கள் எந்த வரவிருக்கும் சந்திப்பையும் பதிவு செய்யவில்லை."
                                                                                        : "You do not have any upcoming visits booked."))
                                                                                : (lang == 'si'
                                                                                    ? "මෙම කාණ්ඩය සඳහා දත්ත හමු නොවීය."
                                                                                    : (lang == 'ta'
                                                                                        ? "பதிவுகள் எதுவும் கிடைக்கவில்லை."
                                                                                        : "No records found for your account.")),
                                                                            textAlign: TextAlign.center,
                                                                            style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                                                                        ),
                                                                        if (selectedTab == 0) ...[
                                                                            const SizedBox(height: 18),
                                                                            ElevatedButton.icon(
                                                                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                                                                label: Text(bookBtnText, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                                style: ElevatedButton.styleFrom(
                                                                                    backgroundColor: AppColors.primary,
                                                                                    foregroundColor: Colors.white,
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                                ),
                                                                                onPressed: () {
                                                                                    Navigator.push(
                                                                                        context,
                                                                                        MaterialPageRoute(
                                                                                            builder: (context) => const CaregiverSetupScreen(),
                                                                                        ),
                                                                                    );
                                                                                },
                                                                            ),
                                                                        ],
                                                                    ],
                                                                ),
                                                            ),
                                                        );
                                                    }

                                                    return ListView.builder(
                                                        itemCount: filtered.length,
                                                        itemBuilder: (context, i) {
                                                            final appointment = filtered[i];
                                                            return appointmentCard(
                                                                hospital: appointment.hospitalName,
                                                                clinic: appointment.departmentName,
                                                                time: appointment.timeSlot,
                                                                date: appointment.appointmentDate,
                                                                token: appointment.tokenCode,
                                                                status: appointment.status,
                                                                patientName: appointment.patientName,
                                                                appointmentId: appointment.id,
                                                                color: (appointment.status.toLowerCase() == "called" ||
                                                                        appointment.status.toLowerCase() == "serving" ||
                                                                        appointment.status.toLowerCase() == "confirmed")
                                                                    ? AppColors.statusGreen
                                                                    : AppColors.statusOrange,
                                                            );
                                                        },
                                                    );
                                                },
                                            ),
                                        ),

                                        const SizedBox(height: 15),
                                        SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: ElevatedButton.icon(
                                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                    ),
                                                ),
                                                onPressed: (){
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder:(context)=> const CaregiverSetupScreen(),
                                                        ),
                                                    );
                                                },
                                                label: Text(
                                                    bookBtnText,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                    ],
                ),
            );
          },
        );
    }

    Widget appointmentCard({
        required String hospital,
        required String clinic,
        required String date,
        required String time,
        required String token,
        required String status,
        required String patientName,
        required String appointmentId,
        required Color color,
    })
        {

            return GestureDetector(
                onTap: ()async 
                {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder:(context)=> AppointmentDetailsScreen(
                                appointmentId: appointmentId,
                                token: token,
                                patientName: patientName,
                                hospitalName: hospital,
                                clinic: clinic,
                                date: date,
                                time: time,
                                status: status,
                            ),
                        ),
                    );
                    // Get latest appointment data after returning.
                    await loadAppointments();
                },

                child: Container(
                    margin: const EdgeInsets.only(bottom:12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.cardBorder,
                        ),
                    ),

                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children:[
                                    Expanded(
                                        child: Text(
                                            hospital,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:13,
                                                color: AppColors.headingText,
                                            ),
                                        ),
                                    ),

                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:8,
                                            vertical:4,
                                        ),
                                        decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                                color:color,
                                                fontSize:10,
                                                fontWeight:FontWeight.bold,
                                            ),
                                        ),
                                    )
                                ],
                            ),

                            const SizedBox(height:5),
                            Text(
                                clinic,
                                style: TextStyle(
                                    color: AppColors.bodyText,
                                    fontSize:12,
                                ),
                            ),
                            Divider(color: AppColors.cardBorder),
                            Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children:[
                                    Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children:[
                                            Text(
                                                date,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:13,
                                                    color: AppColors.headingText,
                                                ),
                                            ),
                                            Text(
                                                time,
                                                style: TextStyle(
                                                    fontSize:12,
                                                    color: AppColors.bodyText,
                                                ),
                                            ),
                                        ],
                                    ),
                                    InkWell(
                                        onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) => DigitalTokenDetailsScreen(
                                                        appointmentId: appointmentId,
                                                    ),
                                                ),
                                            );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.accentColor),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        token.isEmpty ? "View Token" : "Token: $token",
                                                        style: TextStyle(
                                                            color: AppColors.accentColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),

                                ],

                            )

                        ],

                    ),

                ),

            );

        }
}
