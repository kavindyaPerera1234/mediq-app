# MediQ Module 1 - Patient Appointment Booking & Scheduling Backend
**Student:** Sandeepani Perera (IT23653672)  
**Group:** WD_01  
**Course:** IT3060 Human-Computer Interaction (HCI) - Year 3, Semester 2 (2026)  
**Package:** Package 2 - Patient Appointment Booking, Profile, Caregiver Management & Slot Capping  

---

## 📁 Backend Folder Structure

```
backend/
├── backend.dart                         # Master export file (one-line import for screens)
├── README_BACKEND.md                    # This architecture and viva guide
├── models/                              # Data Models (Firestore Mapping & Serialization)
│   ├── appointment_model.dart           # Appointment entity with tokenCode, triage priority & status
│   ├── caregiver_model.dart             # Caregiver dependent entity (relationship, priority)
│   ├── hospital_model.dart              # Government hospital, district & OPD clinic entity
│   └── patient_profile_model.dart       # Patient demographic, blood group & accessibility profile
└── services/                            # Business Logic & Firestore Services
    ├── appointment_service.dart         # Atomic booking, token generator, real-time stream & cancellation
    ├── caregiver_service.dart           # Add, stream & delete family dependents
    ├── hospital_admin_service.dart      # Hospital, clinic configuration & 25-patient slot capping
    └── profile_service.dart             # Fetch/update patient profile & toggle Senior Mode
```

---

## 🗄️ Cloud Firestore Collections Schema

### 1. `appointments` (Patient OPD Bookings)
- `id`: Document ID
- `patientNic`: e.g. `'200164801234'`
- `patientName`: e.g. `'Sandeepani Perera'`
- `tokenCode`: e.g. `'A-032'`
- `hospitalName`: e.g. `'National Hospital of Sri Lanka (NHSL)'`
- `departmentName`: e.g. `'General Medicine'`
- `roomNumber`: e.g. `'OPD Room 01'`
- `appointmentDate`: e.g. `'2026-10-05'`
- `timeSlot`: e.g. `'08:30 AM - 09:00 AM'`
- `priority`: `'normal'` | `'elderly'` | `'disabled'` | `'pregnant'`
- `status`: `'confirmed'` | `'cancelled'` | `'completed'`
- `isCaregiverBooking`: `true` | `false`
- `relationship`: `'Self'` | `'Father'` | `'Mother'` | `'Child'` | `'Spouse'`
- `createdAt`: Firestore Timestamp

### 2. `caregiver_patients` (Registered Family Dependents)
- `id`: Document ID
- `caregiverUserId`: Caregiver account ID (`'user_200164801234'`)
- `patientName`: Dependent's full name
- `patientNic`: Dependent's NIC or Birth Certificate number
- `relationship`: `'Father'`, `'Mother'`, `'Child'`, `'Spouse'`, `'Other'`
- `priority`: `'normal'`, `'elderly'`, `'wheelchair'`, `'maternity'`
- `createdAt`: Firestore Timestamp

### 3. `patient_profiles` (Patient Medical & Accessibility Details)
- `nic`: Patient NIC (`'200164801234'`)
- `fullName`: Patient Name
- `phone`: Mobile phone number for SMS alerts
- `bloodGroup`: `'A+'`, `'B+'`, `'O+'`, etc.
- `gender`: Gender
- `dateOfBirth`: Date of birth
- `emergencyContactName`: Emergency contact person
- `emergencyContactPhone`: Emergency contact phone
- `isSeniorModeEnabled`: Boolean toggle for accessibility
- `updatedAt`: Firestore Timestamp

### 4. `appointment_slots` (25-Patient Capping & Emergency Status)
- `slotId`: Unique slot ID (e.g. `'slot_1'`)
- `slotRange`: `'08:00 AM - 08:30 AM'`
- `date`: `'2026-10-05'`
- `clinic`: Clinic name
- `capacity`: Maximum allowed capacity (Default: `25`)
- `bookedCount`: Number of confirmed appointments
- `isClosed`: Emergency closure boolean (Doctor absence/holiday)
- `closureReason`: e.g. `'Doctor Leave / Emergency'`
- `updatedAt`: Firestore Timestamp

---

## 🚀 How to Import Backend in Any Screen
Instead of multiple scattered imports, you can import everything with:
```dart
import '../backend/backend.dart';
```
Or relative to admin screens:
```dart
import '../../backend/backend.dart';
```
