import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/consultation.dart';

class DoctorRoomAllocation {
  final String id;
  String roomNumber;
  String doctorName;
  String doctorUid;
  String hospitalId;
  String hospitalName;
  String departmentId;
  String departmentName;
  String shiftTime;
  int maxPatients;
  bool isActive;
  String status; // 'active', 'on_break', 'closed'

  DoctorRoomAllocation({
    required this.id,
    required this.roomNumber,
    required this.doctorName,
    required this.doctorUid,
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
    required this.shiftTime,
    this.maxPatients = 25,
    this.isActive = true,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'doctorName': doctorName,
      'doctorUid': doctorUid,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'shiftTime': shiftTime,
      'maxPatients': maxPatients,
      'isActive': isActive,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DoctorRoomAllocation.fromMap(String id, Map<String, dynamic> data) {
    return DoctorRoomAllocation(
      id: id,
      roomNumber: data['roomNumber'] ?? 'Room 01',
      doctorName: data['doctorName'] ?? 'Dr. S. Perera',
      doctorUid: data['doctorUid'] ?? 'doc-silva-uid',
      hospitalId: data['hospitalId'] ?? 'nhsl',
      hospitalName: data['hospitalName'] ?? 'National Hospital of Sri Lanka',
      departmentId: data['departmentId'] ?? 'gen_med',
      departmentName: data['departmentName'] ?? 'General Medicine OPD',
      shiftTime: data['shiftTime'] ?? '08:00 AM - 12:00 PM',
      maxPatients: data['maxPatients'] ?? 25,
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? 'active',
    );
  }
}

class ClinicalTemplate {
  final String id;
  String title;
  String icdCode;
  String symptoms;
  String standardDiagnosis;
  String defaultPrescription;
  String dosageInstructions;
  String category;

  ClinicalTemplate({
    required this.id,
    required this.title,
    required this.icdCode,
    required this.symptoms,
    required this.standardDiagnosis,
    required this.defaultPrescription,
    required this.dosageInstructions,
    this.category = 'General OPD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icdCode': icdCode,
      'symptoms': symptoms,
      'standardDiagnosis': standardDiagnosis,
      'defaultPrescription': defaultPrescription,
      'dosageInstructions': dosageInstructions,
      'category': category,
    };
  }

  factory ClinicalTemplate.fromMap(String id, Map<String, dynamic> data) {
    return ClinicalTemplate(
      id: id,
      title: data['title'] ?? '',
      icdCode: data['icdCode'] ?? '',
      symptoms: data['symptoms'] ?? '',
      standardDiagnosis: data['standardDiagnosis'] ?? '',
      defaultPrescription: data['defaultPrescription'] ?? '',
      dosageInstructions: data['dosageInstructions'] ?? '',
      category: data['category'] ?? 'General OPD',
    );
  }
}

class ConsultationAdminService {
  static final ConsultationAdminService _instance = ConsultationAdminService._internal();
  factory ConsultationAdminService() => _instance;
  ConsultationAdminService._internal() {
    _initializeDemoData();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory persistent caches for offline demonstration and instant reactivity
  final List<Consultation> _fallbackConsultations = [];
  final List<DoctorRoomAllocation> _fallbackAllocations = [];
  final List<ClinicalTemplate> _fallbackTemplates = [];

  void _initializeDemoData() {
    final now = DateTime.now();

    _fallbackConsultations.addAll([
      Consultation(
        consultationId: 'CNS-pat-018',
        appointmentId: 'APT-pat-018',
        queueEntryId: 'QE-pat-018',
        patientId: 'pat-018',
        patientName: 'Nimal Perera',
        doctorId: 'doc-silva-uid',
        doctorName: 'Dr. S. Perera',
        tokenNumber: 'A-018',
        hospitalId: 'nhsl',
        departmentId: 'gen_med',
        status: 'completed',
        diagnosis: 'Acute Viral Upper Respiratory Infection (URTI)',
        prescription: 'Paracetamol 500mg TDS x 3 days\nChlorpheniramine 4mg nocte x 3 days\nSteam inhalation BD',
        notes: 'Patient presented with low-grade fever, sore throat and rhinorrhea for 2 days. Chest clear. Advised warm fluids and rest.',
        priority: 'normal',
        startedAt: now.subtract(const Duration(minutes: 45)),
        completedAt: now.subtract(const Duration(minutes: 32)),
        createdAt: now.subtract(const Duration(minutes: 50)),
      ),
      Consultation(
        consultationId: 'CNS-pat-019',
        appointmentId: 'APT-pat-019',
        queueEntryId: 'QE-pat-019',
        patientId: 'pat-019',
        patientName: 'Nimali Wijesekera',
        doctorId: 'doc-silva-uid',
        doctorName: 'Dr. S. Perera',
        tokenNumber: 'A-019',
        hospitalId: 'nhsl',
        departmentId: 'gen_med',
        status: 'in_progress',
        diagnosis: 'Essential Hypertension - Routine Follow-up',
        prescription: 'Losartan Potassium 50mg Mane Daily\nAtorvastatin 20mg Nocte Daily',
        notes: 'BP recorded at 138/86 mmHg. Compliance good. Advised low salt diet, lipid profile review in 3 months.',
        priority: 'normal',
        startedAt: now.subtract(const Duration(minutes: 8)),
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
      Consultation(
        consultationId: 'CNS-pat-025',
        appointmentId: 'APT-pat-025',
        queueEntryId: 'QE-pat-025',
        patientId: 'pat-025',
        patientName: 'Amal R.',
        doctorId: 'doc-silva-uid',
        doctorName: 'Dr. S. Perera',
        tokenNumber: 'A-025',
        hospitalId: 'nhsl',
        departmentId: 'gen_med',
        status: 'in_progress',
        diagnosis: 'Acute Bronchial Asthma Exacerbation',
        prescription: 'Salbutamol Nebulization stat\nPrednisolone 20mg mane x 5 days\nSalbutamol MDI 2 puffs PRN',
        notes: 'Bilateral expiratory wheezing noted. Emergency priority assigned. Oxygen saturation 96% on room air.',
        priority: 'emergency',
        startedAt: now.subtract(const Duration(minutes: 2)),
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      Consultation(
        consultationId: 'CNS-pat-kandy-001',
        appointmentId: 'APT-pat-kandy-001',
        queueEntryId: 'QE-pat-kandy-001',
        patientId: 'pat-kandy-001',
        patientName: 'Sanduni Perera',
        doctorId: 'doc-perera-uid',
        doctorName: 'Dr. Perera',
        tokenNumber: 'P-001',
        hospitalId: 'hosp_kandy',
        departmentId: 'dept_pediatrics',
        status: 'completed',
        diagnosis: 'Pediatric Acute Gastroenteritis with Mild Dehydration',
        prescription: 'Oral Rehydration Solution (ORS) 200ml after each loose stool\nZinc Sulphate 20mg OD x 14 days\nParacetamol syrup 5ml PRN',
        notes: 'Child tolerated oral fluids well in OPD clinic. Parents educated on red flag dehydration warning signs.',
        priority: 'normal',
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        createdAt: now.subtract(const Duration(hours: 2, minutes: 10)),
      ),
    ]);

    _fallbackAllocations.addAll([
      DoctorRoomAllocation(
        id: 'ALLOC-001',
        roomNumber: 'OPD Consultation Room 01',
        doctorName: 'Dr. S. Perera',
        doctorUid: 'doc-silva-uid',
        hospitalId: 'nhsl',
        hospitalName: 'National Hospital of Sri Lanka (NHSL)',
        departmentId: 'gen_med',
        departmentName: 'General Medicine OPD',
        shiftTime: '08:00 AM - 12:00 PM',
        maxPatients: 25,
        isActive: true,
        status: 'active',
      ),
      DoctorRoomAllocation(
        id: 'ALLOC-002',
        roomNumber: 'OPD Consultation Room 02',
        doctorName: 'Dr. K. Fernando',
        doctorUid: 'doc-fernando-uid',
        hospitalId: 'nhsl',
        hospitalName: 'National Hospital of Sri Lanka (NHSL)',
        departmentId: 'dept_cardiology',
        departmentName: 'Cardiology OPD',
        shiftTime: '08:30 AM - 01:30 PM',
        maxPatients: 20,
        isActive: true,
        status: 'active',
      ),
      DoctorRoomAllocation(
        id: 'ALLOC-003',
        roomNumber: 'Pediatrics Clinic Room A',
        doctorName: 'Dr. Perera',
        doctorUid: 'doc-perera-uid',
        hospitalId: 'hosp_kandy',
        hospitalName: 'Kandy General Hospital',
        departmentId: 'dept_pediatrics',
        departmentName: 'Pediatrics OPD',
        shiftTime: '08:00 AM - 12:30 PM',
        maxPatients: 25,
        isActive: true,
        status: 'active',
      ),
      DoctorRoomAllocation(
        id: 'ALLOC-004',
        roomNumber: 'ENT Clinic Examination Room',
        doctorName: 'Dr. Wijeratne',
        doctorUid: 'doc-wijeratne-uid',
        hospitalId: 'nhsl',
        hospitalName: 'National Hospital of Sri Lanka (NHSL)',
        departmentId: 'dept_ent',
        departmentName: 'ENT Clinic',
        shiftTime: '09:00 AM - 01:00 PM',
        maxPatients: 20,
        isActive: false,
        status: 'on_break',
      ),
    ]);

    _fallbackTemplates.addAll([
      ClinicalTemplate(
        id: 'TPL-001',
        title: 'Upper Respiratory Tract Infection (URTI)',
        icdCode: 'J06.9',
        symptoms: 'Rhinorrhea, sore throat, sneezing, low grade fever',
        standardDiagnosis: 'Acute Viral Upper Respiratory Tract Infection',
        defaultPrescription: 'Paracetamol 500mg TDS x 3 days\nChlorpheniramine 4mg nocte x 3 days\nVitamin C 500mg Daily',
        dosageInstructions: 'Take after meals. Adequate hydration and steam inhalation BD.',
        category: 'General OPD',
      ),
      ClinicalTemplate(
        id: 'TPL-002',
        title: 'Hypertension Routine Follow-up',
        icdCode: 'I10',
        symptoms: 'Asymptomatic follow-up, occasional occipital morning headache',
        standardDiagnosis: 'Primary / Essential Hypertension (Controlled)',
        defaultPrescription: 'Losartan Potassium 50mg Mane Daily\nAmlodipine 5mg Nocte Daily',
        dosageInstructions: 'Take consistently at the same time daily. Regular BP monitoring advised.',
        category: 'Cardiology',
      ),
      ClinicalTemplate(
        id: 'TPL-003',
        title: 'Type 2 Diabetes Mellitus Maintenance',
        icdCode: 'E11.9',
        symptoms: 'Polyuria, polydipsia, routine fasting blood glucose check',
        standardDiagnosis: 'Type 2 Diabetes Mellitus without complications',
        defaultPrescription: 'Metformin 500mg BD after meals\nGlimepiride 1mg Mane before breakfast',
        dosageInstructions: 'Do not skip meals after taking Glimepiride. HbA1c review every 3 months.',
        category: 'Endocrinology',
      ),
      ClinicalTemplate(
        id: 'TPL-004',
        title: 'Pediatric Acute Gastroenteritis',
        icdCode: 'A09',
        symptoms: 'Watery diarrhea 3-4 times, nausea, vomiting',
        standardDiagnosis: 'Acute Gastroenteritis without severe dehydration',
        defaultPrescription: 'Oral Rehydration Solution (ORS) 1 sachet per 1L boiled cooled water\nZinc Sulphate 20mg OD x 14 days\nDomperidone syrup 2.5ml TDS before feeds',
        dosageInstructions: 'Encourage frequent small sips of ORS. Seek immediate hospital admission if lethargic.',
        category: 'Pediatrics',
      ),
      ClinicalTemplate(
        id: 'TPL-005',
        title: 'Acute Bronchial Asthma Protocol',
        icdCode: 'J45.901',
        symptoms: 'Wheezing, breathlessness, nocturnal dry cough',
        standardDiagnosis: 'Acute Asthma Exacerbation (Mild-to-Moderate)',
        defaultPrescription: 'Salbutamol Inhaler 100mcg 2 puffs QDS PRN\nBeclomethasone 200mcg BD\nPrednisolone 25mg mane x 5 days',
        dosageInstructions: 'Use spacer device for inhaler. Rinse mouth with water after steroid inhaler.',
        category: 'Respiratory',
      ),
    ]);
  }

  // ==========================================
  // 1. CONSULTATIONS CRUD
  // ==========================================

  /// Stream consultations with real-time updates from Firestore or fallback
  Stream<List<Consultation>> streamConsultations({
    String? hospitalId,
    String? departmentId,
    String? statusFilter,
  }) {
    try {
      Query query = _db.collection(AppConstants.consultationsCollection);

      if (hospitalId != null && hospitalId.isNotEmpty && hospitalId != 'all') {
        query = query.where('hospitalId', isEqualTo: hospitalId);
      }
      if (departmentId != null && departmentId.isNotEmpty && departmentId != 'all') {
        query = query.where('departmentId', isEqualTo: departmentId);
      }
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        query = query.where('status', isEqualTo: statusFilter);
      }

      return query.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty && _fallbackConsultations.isNotEmpty) {
          return _filterFallbackConsultations(hospitalId, departmentId, statusFilter);
        }

        List<Consultation> list = [];
        for (var doc in snapshot.docs) {
          list.add(Consultation.fromFirestore(doc));
        }

        // Merge any local additions if Firestore doesn't have them
        for (var fb in _fallbackConsultations) {
          if (!list.any((c) => c.consultationId == fb.consultationId)) {
            list.add(fb);
          }
        }

        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });
    } catch (_) {
      return Stream.value(_filterFallbackConsultations(hospitalId, departmentId, statusFilter));
    }
  }

  List<Consultation> _filterFallbackConsultations(String? hId, String? dId, String? st) {
    return _fallbackConsultations.where((c) {
      if (hId != null && hId.isNotEmpty && hId != 'all' && c.hospitalId != hId) return false;
      if (dId != null && dId.isNotEmpty && dId != 'all' && c.departmentId != dId) return false;
      if (st != null && st.isNotEmpty && st != 'all' && c.status != st) return false;
      return true;
    }).toList();
  }

  /// CREATE a new Consultation record
  Future<bool> createConsultation(Consultation consultation) async {
    try {
      final docRef = consultation.consultationId.isNotEmpty
          ? _db.collection(AppConstants.consultationsCollection).doc(consultation.consultationId)
          : _db.collection(AppConstants.consultationsCollection).doc();

      final newConsultation = consultation.copyWith(
        consultationId: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newConsultation.toMap());

      // Update in-memory fallback list
      _fallbackConsultations.removeWhere((c) => c.consultationId == newConsultation.consultationId);
      _fallbackConsultations.insert(0, newConsultation);
      return true;
    } catch (e) {
      // Local fallback on network failure
      final fallbackId = consultation.consultationId.isNotEmpty ? consultation.consultationId : 'CNS-custom-${DateTime.now().millisecondsSinceEpoch}';
      final newConsultation = consultation.copyWith(
        consultationId: fallbackId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _fallbackConsultations.insert(0, newConsultation);
      return true;
    }
  }

  /// UPDATE an existing Consultation record
  Future<bool> updateConsultation(Consultation consultation) async {
    try {
      final docRef = _db.collection(AppConstants.consultationsCollection).doc(consultation.consultationId);
      final updatedData = consultation.copyWith(updatedAt: DateTime.now());

      await docRef.set(updatedData.toMap(), SetOptions(merge: true));

      final index = _fallbackConsultations.indexWhere((c) => c.consultationId == consultation.consultationId);
      if (index >= 0) {
        _fallbackConsultations[index] = updatedData;
      } else {
        _fallbackConsultations.insert(0, updatedData);
      }
      return true;
    } catch (e) {
      final index = _fallbackConsultations.indexWhere((c) => c.consultationId == consultation.consultationId);
      if (index >= 0) {
        _fallbackConsultations[index] = consultation;
      }
      return true;
    }
  }

  /// DELETE a Consultation record
  Future<bool> deleteConsultation(String consultationId) async {
    try {
      await _db.collection(AppConstants.consultationsCollection).doc(consultationId).delete();
      _fallbackConsultations.removeWhere((c) => c.consultationId == consultationId);
      return true;
    } catch (e) {
      _fallbackConsultations.removeWhere((c) => c.consultationId == consultationId);
      return true;
    }
  }

  // ==========================================
  // 2. DOCTOR ROOM ALLOCATIONS CRUD
  // ==========================================

  Stream<List<DoctorRoomAllocation>> streamDoctorAllocations() {
    try {
      return _db.collection('doctor_room_allocations').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return _fallbackAllocations;
        final list = snapshot.docs.map((doc) => DoctorRoomAllocation.fromMap(doc.id, doc.data())).toList();
        for (var fb in _fallbackAllocations) {
          if (!list.any((a) => a.id == fb.id)) list.add(fb);
        }
        return list;
      });
    } catch (_) {
      return Stream.value(_fallbackAllocations);
    }
  }

  Future<bool> createAllocation(DoctorRoomAllocation allocation) async {
    try {
      final docRef = _db.collection('doctor_room_allocations').doc(allocation.id.isNotEmpty ? allocation.id : 'ALLOC-${DateTime.now().millisecondsSinceEpoch}');
      await docRef.set(allocation.toMap());
      _fallbackAllocations.insert(0, allocation);
      return true;
    } catch (_) {
      _fallbackAllocations.insert(0, allocation);
      return true;
    }
  }

  Future<bool> updateAllocation(DoctorRoomAllocation allocation) async {
    try {
      await _db.collection('doctor_room_allocations').doc(allocation.id).set(allocation.toMap(), SetOptions(merge: true));
      final idx = _fallbackAllocations.indexWhere((a) => a.id == allocation.id);
      if (idx >= 0) _fallbackAllocations[idx] = allocation;
      return true;
    } catch (_) {
      final idx = _fallbackAllocations.indexWhere((a) => a.id == allocation.id);
      if (idx >= 0) _fallbackAllocations[idx] = allocation;
      return true;
    }
  }

  Future<bool> deleteAllocation(String allocationId) async {
    try {
      await _db.collection('doctor_room_allocations').doc(allocationId).delete();
      _fallbackAllocations.removeWhere((a) => a.id == allocationId);
      return true;
    } catch (_) {
      _fallbackAllocations.removeWhere((a) => a.id == allocationId);
      return true;
    }
  }

  // ==========================================
  // 3. CLINICAL TEMPLATES CRUD
  // ==========================================

  Stream<List<ClinicalTemplate>> streamClinicalTemplates() {
    try {
      return _db.collection('clinical_templates').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return _fallbackTemplates;
        final list = snapshot.docs.map((doc) => ClinicalTemplate.fromMap(doc.id, doc.data())).toList();
        for (var fb in _fallbackTemplates) {
          if (!list.any((t) => t.id == fb.id)) list.add(fb);
        }
        return list;
      });
    } catch (_) {
      return Stream.value(_fallbackTemplates);
    }
  }

  Future<bool> createTemplate(ClinicalTemplate template) async {
    try {
      final docRef = _db.collection('clinical_templates').doc(template.id.isNotEmpty ? template.id : 'TPL-${DateTime.now().millisecondsSinceEpoch}');
      await docRef.set(template.toMap());
      _fallbackTemplates.insert(0, template);
      return true;
    } catch (_) {
      _fallbackTemplates.insert(0, template);
      return true;
    }
  }

  Future<bool> updateTemplate(ClinicalTemplate template) async {
    try {
      await _db.collection('clinical_templates').doc(template.id).set(template.toMap(), SetOptions(merge: true));
      final idx = _fallbackTemplates.indexWhere((t) => t.id == template.id);
      if (idx >= 0) _fallbackTemplates[idx] = template;
      return true;
    } catch (_) {
      final idx = _fallbackTemplates.indexWhere((t) => t.id == template.id);
      if (idx >= 0) _fallbackTemplates[idx] = template;
      return true;
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _db.collection('clinical_templates').doc(templateId).delete();
      _fallbackTemplates.removeWhere((t) => t.id == templateId);
      return true;
    } catch (_) {
      _fallbackTemplates.removeWhere((t) => t.id == templateId);
      return true;
    }
  }
}
