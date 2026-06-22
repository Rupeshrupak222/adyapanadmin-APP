import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

/// Unified Data Service that fetches from TiDB backend (via ApiService).
/// Falls back to MockDataService if backend is unreachable.
class DataService {
  DataService._internal();
  static final DataService instance = DataService._internal();

  final _api = ApiService.instance;
  final _mock = MockDataService.instance;

  // Reactive notifiers (same interface as MockDataService)
  final ValueNotifier<List<Student>> studentsNotifier = ValueNotifier<List<Student>>([]);
  final ValueNotifier<List<Teacher>> teachersNotifier = ValueNotifier<List<Teacher>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  bool _isBackendAvailable = true;

  bool get isBackendAvailable => _isBackendAvailable;
  bool get isLoading => isLoadingNotifier.value;

  // ─── INITIALIZATION ─────────────────────────────────────────────

  /// Call this on app start to load data from backend
  Future<void> initialize() async {
    isLoadingNotifier.value = true;
    await Future.wait([
      loadStudents(),
      loadTeachers(),
    ]);
    isLoadingNotifier.value = false;
  }

  // ─── STUDENTS ───────────────────────────────────────────────────

  Future<void> loadStudents({String? search, String? filter, String? schoolId}) async {
    try {
      final students = await _api.fetchStudents(
        search: search,
        filter: filter,
        schoolId: schoolId,
      );
      studentsNotifier.value = students;
      _isBackendAvailable = true;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for students: $e');
      _isBackendAvailable = false;
      studentsNotifier.value = []; // No fake data — show empty
    }
  }

  Future<void> addStudent(Student student, {String? schoolId}) async {
    try {
      final created = await _api.addStudent(student, schoolId: schoolId);
      final list = List<Student>.from(studentsNotifier.value)..insert(0, created);
      studentsNotifier.value = list;
    } catch (e) {
      debugPrint('⚠️ Backend error on addStudent, using mock: $e');
      _mock.addStudent(student);
      studentsNotifier.value = _mock.studentsNotifier.value;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      final updated = await _api.updateStudent(student);
      final list = studentsNotifier.value.map((s) => s.id == updated.id ? updated : s).toList();
      studentsNotifier.value = list;
    } catch (e) {
      debugPrint('⚠️ Backend error on updateStudent, using mock: $e');
      _mock.updateStudent(student);
      studentsNotifier.value = _mock.studentsNotifier.value;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final success = await _api.deleteStudent(id);
      if (success) {
        final list = studentsNotifier.value.where((s) => s.id != id).toList();
        studentsNotifier.value = list;
      }
    } catch (e) {
      debugPrint('⚠️ Backend error on deleteStudent, using mock: $e');
      _mock.deleteStudent(id);
      studentsNotifier.value = _mock.studentsNotifier.value;
    }
  }

  // ─── TEACHERS ───────────────────────────────────────────────────

  Future<void> loadTeachers({String? search, String? filter, String? schoolId}) async {
    try {
      final teachers = await _api.fetchTeachers(
        search: search,
        filter: filter,
        schoolId: schoolId,
      );
      teachersNotifier.value = teachers;
      _isBackendAvailable = true;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for teachers: $e');
      _isBackendAvailable = false;
      teachersNotifier.value = []; // No fake data — show empty
    }
  }

  Future<void> addTeacher(Teacher teacher, {String? schoolId}) async {
    try {
      final created = await _api.addTeacher(teacher, schoolId: schoolId);
      final list = List<Teacher>.from(teachersNotifier.value)..insert(0, created);
      teachersNotifier.value = list;
    } catch (e) {
      debugPrint('⚠️ Backend error on addTeacher, using mock: $e');
      _mock.addTeacher(teacher);
      teachersNotifier.value = _mock.teachersNotifier.value;
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      final updated = await _api.updateTeacher(teacher);
      final list = teachersNotifier.value.map((t) => t.id == updated.id ? updated : t).toList();
      teachersNotifier.value = list;
    } catch (e) {
      debugPrint('⚠️ Backend error on updateTeacher, using mock: $e');
      _mock.updateTeacher(teacher);
      teachersNotifier.value = _mock.teachersNotifier.value;
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      final success = await _api.deleteTeacher(id);
      if (success) {
        final list = teachersNotifier.value.where((t) => t.id != id).toList();
        teachersNotifier.value = list;
      }
    } catch (e) {
      debugPrint('⚠️ Backend error on deleteTeacher, using mock: $e');
      _mock.deleteTeacher(id);
      teachersNotifier.value = _mock.teachersNotifier.value;
    }
  }

  // ─── SCHOOLS ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSchools() async {
    try {
      final schools = await _api.fetchSchools();
      _isBackendAvailable = true;
      return schools;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for schools: $e');
      _isBackendAvailable = false;
      return []; // No fake data
    }
  }

  Future<void> deleteSchool(String id) async {
    try {
      await _api.deleteSchool(id);
    } catch (e) {
      debugPrint('⚠️ Backend error on deleteSchool: $e');
    }
  }

  // ─── LIVE CLASSES ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLiveClasses() async {
    try {
      final classes = await _api.fetchLiveClasses();
      _isBackendAvailable = true;
      return classes;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for live classes: $e');
      _isBackendAvailable = false;
      return [];
    }
  }

  // ─── SYSTEM EVENTS ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchEvents({int limit = 50}) async {
    try {
      final events = await _api.fetchEvents(limit: limit);
      _isBackendAvailable = true;
      return events;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for events: $e');
      _isBackendAvailable = false;
      return [];
    }
  }

  Future<void> createEvent(String title, String desc) async {
    try {
      await _api.createEvent(title, desc);
    } catch (e) {
      debugPrint('⚠️ Backend error on createEvent: $e');
      _mock.systemEvents.insert(0, {
        'title': title,
        'desc': desc,
        'time': 'Just now',
        'icon': Icons.info,
        'color': Colors.blue,
      });
    }
  }

  // ─── LEAVE REQUESTS ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLeaves({String? status}) async {
    try {
      final leaves = await _api.fetchLeaves(status: status);
      _isBackendAvailable = true;
      return leaves;
    } catch (e) {
      debugPrint('⚠️ Backend unreachable for leaves: $e');
      _isBackendAvailable = false;
      return [];
    }
  }

  Future<void> updateLeaveStatus(String id, String status) async {
    try {
      await _api.updateLeaveStatus(id, status);
    } catch (e) {
      debugPrint('⚠️ Backend error on updateLeaveStatus: $e');
    }
  }

  // ─── MEETINGS ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> createMeeting({String? title, String? hostedBy}) async {
    try {
      final meeting = await _api.createMeeting(title: title, hostedBy: hostedBy);
      _isBackendAvailable = true;
      return meeting;
    } catch (e) {
      debugPrint('⚠️ Backend error on createMeeting: $e');
      _isBackendAvailable = false;
      return null;
    }
  }

  // ─── STATS (computed from loaded data) ──────────────────────────

  double getAverageStudentAttendance() {
    final students = studentsNotifier.value;
    if (students.isEmpty) return 0.0;
    final total = students.fold<double>(0.0, (sum, st) => sum + st.attendancePercentage);
    return double.parse((total / students.length).toStringAsFixed(1));
  }

  double getAverageTeacherAttendance() {
    final teachers = teachersNotifier.value;
    if (teachers.isEmpty) return 0.0;
    final total = teachers.fold<double>(0.0, (sum, t) => sum + t.classAttendance);
    return double.parse((total / teachers.length).toStringAsFixed(1));
  }

  double getAverageSyllabusCompletion() {
    final teachers = teachersNotifier.value;
    if (teachers.isEmpty) return 0.0;
    final total = teachers.fold<double>(0.0, (sum, t) => sum + t.syllabusCompletion);
    return double.parse((total / teachers.length).toStringAsFixed(1));
  }

  int getTotalPendingDoubts() {
    return teachersNotifier.value.fold<int>(0, (sum, t) => sum + t.pendingDoubts);
  }
}
