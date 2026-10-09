# 🏥 MediQ - Smart OPD Appointment Scheduling & Live Queue Management System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.24%2B-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.5%2B-0175C2.svg?logo=dart)](https://dart.dev)
[![Firebase Backend](https://img.shields.io/badge/Firebase-Cloud%20Firestore-FFA000.svg?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows-lightgrey.svg)](https://flutter.dev)
[![WCAG Accessibility](https://img.shields.io/badge/Accessibility-WCAG%202.1%20AA-success.svg)](https://www.w3.org/WAI/standards-guidelines/wcag/)

> **MediQ** is a cross-platform mobile and web application engineered to eliminate severe outpatient crowding, reduce patient waiting times, and provide real-time queue visibility for Sri Lankan public tertiary hospitals (such as National Hospital of Sri Lanka Colombo, Kandy General Hospital, and Karapitiya Teaching Hospital).

---

## 📑 Table of Contents
1. [Project Overview & Key Objectives](#-project-overview--key-objectives)
2. [Key Features & System Modules](#-key-features--system-modules)
3. [System Architecture & Tech Stack](#-system-architecture--tech-stack)
4. [Prerequisites & System Requirements](#-prerequisites--system-requirements)
5. [Step-by-Step Installation & Setup](#-step-by-step-installation--setup)
6. [How to Run the Application](#-how-to-run-the-application)
7. [Demo Accounts & Test Credentials](#-demo-accounts--test-credentials)
8. [Building the Release APK](#-building-the-release-apk)
9. [Running Automated Tests & Code Quality](#-running-automated-tests--code-quality)
10. [Project Directory Layout](#-project-directory-layout)
11. [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## 🌟 Project Overview & Key Objectives

In public healthcare facilities across developing nations, Outpatient Departments (OPD) process thousands of patients daily on a physical walk-in basis, causing long physical queues, crowded waiting lobbies, and high administrative stress.

**MediQ** solves this challenge through:
- **Remote Slot Booking:** Patients reserve OPD appointment slots and receive unique digital queue tokens with verifiable QR codes.
- **Zero-Latency Live Queue Tracking:** Real-time synchronization powered by Cloud Firestore allows patients to track their position and estimated wait time remotely.
- **Doctor & Staff Queuing Console:** Healthcare staff can seamlessly call patients, view waiting lists, manage consultation states, and skip absent patients.
- **Inclusive Accessibility:** Built-in Text-to-Speech (TTS) voice announcements with hospital attention chimes, high-contrast mode, and dynamic text scaling (WCAG 2.1 AA compliant) for elderly and low-literacy users.

---

## 🚀 Key Features & System Modules

### 1. Patient Appointment Scheduling (Module 1)
- Multi-hospital selection (NHSL Colombo, Kandy General, Karapitiya, Jaffna).
- Multi-OPD clinic selection (General Medicine, Pediatrics, Cardiology, ENT, etc.).
- Calendar date picker and session slot allocation.
- Digital token generator with QR code export.

### 2. Live Queue Tracking & Audio Guidance (Module 2)
- Reactive queue counters: *Current Token Being Served*, *Your Token Number*, *Estimated Wait Time*.
- Real-time Firestore snapshot listeners with zero manual refresh required.
- Voice announcements with chime alerting patients when their token is called.

### 3. Role-Based Authentication & User Profiles (Module 3)
- Multi-role support: **Patient**, **Hospital Staff / Receptionist**, and **Doctor**.
- Persistent user sessions via `shared_preferences` and Firebase Auth.
- Secure token delegation for caregivers booking on behalf of family members.

### 4. Staff & Doctor Queue Console (Module 4)
- Live OPD waiting list across all hospitals and departments.
- One-tap "Call Next Patient" workflow with instant broadcast to the patient app.
- "Consultation in Progress" status indicator and "Mark Completed".
- Skip confirmation dialog for absentee handling without disrupting queue ordering.

---

## 🛠️ System Architecture & Tech Stack

| Layer | Technologies Used | Description |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter 3.24+ (Dart 3.5+)** | Cross-platform UI for Android, Web, and Windows desktop |
| **Backend & Database** | **Google Cloud Firestore** | NoSQL document database with reactive real-time streams |
| **Authentication** | **Firebase Auth** | Role-based authentication and secure session tokens |
| **Typography & UI** | **Google Fonts (Outfit / Inter)** | Clear medical-grade typography and Material 3 design |
| **QR Code Engine** | **qr_flutter & mobile_scanner** | QR token generation and camera barcode scanning |
| **Accessibility Engine** | **Custom TextScaler & TTS** | Voice guidance, chime audio, and WCAG high-contrast themes |

---

## 💻 Prerequisites & System Requirements

Ensure the following tools are installed on your workstation:

1. **Flutter SDK:** Version `3.24.x` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
2. **Dart SDK:** Version `3.5.x` or later (bundled with Flutter)
3. **Java Development Kit (JDK):** JDK 17 (recommended for Gradle build tools)
4. **Android Studio / Android SDK:** API Level 34 platform tools and Android Emulator (or a physical device with USB debugging enabled)
5. **Google Chrome / Microsoft Edge:** For local web testing
6. **Git:** For source code management

Verify your installation by running:
```bash
flutter doctor
```
Ensure there are no blocking issues with Flutter and your chosen target platform (Android or Chrome).

---

## 📥 Step-by-Step Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/mediq-app.git
cd mediq-app
```

### 2. Install Project Dependencies
Fetch all required packages declared in `pubspec.yaml`:
```bash
flutter pub get
```

### 3. Firebase Configuration
The project is configured with Cloud Firestore (`mediq-opd`). Firebase options are provided in `lib/firebase_options.dart`.
- The database is configured to automatically seed sample hospitals, OPD clinics, doctor profiles, and mock queue records upon first launch via `SeedDataService`.

---

## 🖥️ How to Run the Application

### Option A: Run on Google Chrome (Recommended for quick testing)
```bash
flutter run -d chrome
```

### Option B: Run on Local Web Server (Custom Port)
```bash
flutter run -d web-server --web-port=5000
```
Open your browser and navigate to: `http://localhost:5000`

### Option C: Run on a Physical Android Phone / Emulator
1. Connect your Android device via USB and enable **USB Debugging** (or launch an Android Emulator).
2. Check that your device is detected:
   ```bash
   flutter devices
   ```
3. Run the application:
   ```bash
   flutter run -d <DEVICE_ID>
   ```

### Option D: Run on Windows Desktop
```bash
flutter run -d windows
```

---

## 🔑 Demo Accounts & Test Credentials

For evaluation, grading, and demonstration purposes, pre-configured accounts are seeded automatically:

| Role | Email / Username | Default Access / Permissions |
| :--- | :--- | :--- |
| **Doctor** | `doctor@mediq.lk` | Calls next patient, views clinical notes, completes consultation |
| **Staff / Nurse** | `staff@mediq.lk` | Manages OPD lobby, checks in patients, skips absent tokens |
| **Patient / Guest** | *Guest / Direct Login* | Books appointment slots, tracks live queue, views digital QR token |

---

## 📦 Building the Release APK

To generate a standalone, optimized Android APK for installation on physical Android devices:

```bash
flutter build apk --release
```

Once compilation completes, the release binary is located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Installing the APK directly to an Android phone:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
*(Alternatively, copy `app-release.apk` directly to the phone storage and tap to install).*

---

## 🧪 Running Automated Tests & Code Quality

### Run Unit and Widget Tests
Execute all automated test suites:
```bash
flutter test
```

### Run Static Code Analysis
Ensure the codebase adheres to Flutter best practices with zero fatal lint warnings:
```bash
flutter analyze
```

---

## 📂 Project Directory Layout

```text
mediq-app/
├── android/                 # Native Android Gradle configuration and manifest
├── assets/
│   └── images/              # Hospital branding, logos, and UI illustration assets
├── lib/
│   ├── core/
│   │   ├── constants/       # Color palettes, theme styles, and accessibility tokens
│   │   └── utils/           # Formatting, date utilities, and queue helpers
│   ├── features/
│   │   ├── auth_live_queue_module3/                 # Authentication, splash & live queue tracking
│   │   └── patient_appointment_scheduling_module1/  # OPD booking, hospital selection & slot reservation
│   ├── screens/             # Staff queue dashboard, patient queue screens & call workflows
│   ├── services/            # Firestore service, Auth service, Queue service & Seed service
│   ├── firebase_options.dart# Firebase configuration across platforms
│   └── main.dart            # Main application entry point & root accessibility wrapper
├── test/
│   └── widget_test.dart     # Smoke tests & widget tests
├── pubspec.yaml             # Project dependencies and asset definitions
└── README.md                # Project documentation and setup guide
```

---

## ❓ Troubleshooting & FAQs

- **Issue: `FirebaseException: [cloud_firestore/permission-denied]`**
  - **Resolution:** Verify your network connectivity. The project uses Firebase Firestore rules allowing read/write operations for authorized OPD sessions.
- **Issue: Web audio chime / TTS not playing automatically**
  - **Resolution:** Modern browsers block autoplay audio until user interaction. Click anywhere on the web page to grant audio permissions.
- **Issue: Gradle build fails with Android SDK error**
  - **Resolution:** Ensure Java JDK 17 is set in your `JAVA_HOME` environment variable and run `flutter clean && flutter pub get` prior to building.

---

## 📜 Academic Integrity & License
This project was designed, implemented, and submitted as an academic software engineering capstone for the **Application Frameworks / Mobile Healthcare Systems** module. All intellectual rights reserved.
