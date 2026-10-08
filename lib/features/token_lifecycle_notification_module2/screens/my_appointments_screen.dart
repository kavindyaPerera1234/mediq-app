import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import 'appointment_details_screen.dart';
import '../../patient_appointment_scheduling_module1/screens/caregiver_setup_screen.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import 'digital_token_details_screen.dart';
import 'qr_scanner_screen.dart';

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
        print("UI received appointments: ${data.length}");
        if (!mounted) return;
        setState(() {
            appointments = data;
            isLoading = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Navigator.canPop(context) ? IconButton(
                    icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                    ),
                    onPressed: (){
                        Navigator.pop(context);
                    },
                ) : null,

                title: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                        Text(
                            "My Appointments",
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize:18,
                            ),
                        ),

                        Text(
                            "Manage your OPD visits",
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize:12,
                            ),
                        ),

                    ],
                ),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Hospital Check-in QR Code',
                        onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const QrScannerScreen(),
                                ),
                            );
                        },
                    ),
                ],
            ),

            body: Column(
                children: [
                    // Tabs
                    Container(
                        color: Colors.white,
                        child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: List.generate(
                                tabs.length,
                                (index){
                                    bool active =
                                    selectedTab == index;
                                    return GestureDetector(
                                        onTap: (){
                                            setState((){
                                                selectedTab = index;
                                            });
                                        },
                                        child: Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                                vertical:14,
                                            ),
                                            decoration: BoxDecoration(
                                                border: Border(
                                                    bottom: BorderSide(
                                                        color: active
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                        width:2,
                                                    ),
                                                ),
                                            ),
                                            child: Text(
                                                tabs[index],
                                                style: TextStyle(
                                                    color: active
                                                    ? AppColors.primary
                                                    : Colors.grey,
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
                            padding:
                            const EdgeInsets.all(16),
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
                                                    if (selectedTab == 0) {
                                                        return appointment.status == "confirmed" ||
                                                            appointment.status == "rescheduled" ||
                                                            appointment.status == "waiting" ||
                                                            appointment.status == "scheduled";
                                                    }
                                                    if (selectedTab == 1) {
                                                        return appointment.status == "completed";
                                                    }
                                                    if (selectedTab == 2) {
                                                        return appointment.status == "cancelled";
                                                    }
                                                    return false;
                                                }).toList();

                                                if (filtered.isEmpty) {
                                                    final tabName = tabs[selectedTab].toLowerCase();
                                                    return Center(
                                                        child: Padding(
                                                            padding: const EdgeInsets.all(32.0),
                                                            child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                    Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade400),
                                                                    const SizedBox(height: 16),
                                                                    Text(
                                                                        "No $tabName appointments",
                                                                        style: const TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: AppColors.textPrimary,
                                                                        ),
                                                                    ),
                                                                    const SizedBox(height: 8),
                                                                    Text(
                                                                        selectedTab == 0
                                                                            ? "You do not have any upcoming visits booked."
                                                                            : "No $tabName records found for your account.",
                                                                        textAlign: TextAlign.center,
                                                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                                                    ),
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
                                                            color: appointment.status == "confirmed"
                                                                ? Colors.green
                                                                : Colors.orange,
                                                        );
                                                    },
                                                );
                                            },
                                        ),
                                    ),

                                    const SizedBox(height:15),
                                    SizedBox(
                                        width: double.infinity,
                                        height:52,
                                        child: ElevatedButton(
                                            style:
                                            ElevatedButton.styleFrom(
                                                backgroundColor:
                                                AppColors.primary,
                                                shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
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

                                            child: const Text(
                                                "Book New Appointment",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:15,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade200,
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
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:13,
                                            ),
                                        ),
                                    ),

                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:8,
                                            vertical:4,
                                        ),
                                        decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
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
                                    color: AppColors.textSecondary,
                                    fontSize:12,
                                ),
                            ),
                            const Divider(),
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
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:13,
                                                ),
                                            ),
                                            Text(
                                                time,
                                                style: const TextStyle(
                                                    fontSize:12,
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
                                                    const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        token.isEmpty ? "View Token" : "Token: $token",
                                                        style: const TextStyle(
                                                            color: AppColors.primary,
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
