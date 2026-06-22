import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/teacher.dart';
import 'auth_service.dart';

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  // Point to the deployed backend (same as website and mobile app)
  // All 3 projects share the same backend and database
  static const String baseUrl = 'https://preschool-wzjj.onrender.com/api/v1';
  // To use local backend server, uncomment below:
  // static const String baseUrl = 'http://localhost:4000/api/v1';

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Dart/Flutter (Adyapan Admin App)',
    };
    final token = AuthService.instance.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── ADMIN KEY ────────────────────────────────────────────────

  /// Fetch the active admin access key from backend
  Future<String?> fetchAdminKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin-key'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['key']?.toString();
      }
    } catch (e) {
      print('ApiService Error (fetchAdminKey): $e');
    }
    return null;
  }

  // ─── STUDENTS ─────────────────────────────────────────────────

  Future<List<Student>> fetchStudents({String? search, String? filter, String? schoolId}) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (filter != null && filter.isNotEmpty) params['filter'] = filter;
      if (schoolId != null) params['schoolId'] = schoolId;

      final uri = Uri.parse('$baseUrl/students').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((j) => _deserializeStudent(j)).toList();
      } else {
        throw Exception('Failed to fetch students. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchStudents): $e');
      rethrow;
    }
  }

  Future<Student> addStudent(Student student, {String? schoolId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
        body: json.encode(_serializeStudent(student, schoolId: schoolId)),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _deserializeStudent(json.decode(response.body));
      } else {
        throw Exception('Failed to add student. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (addStudent): $e');
      rethrow;
    }
  }

  Future<Student> updateStudent(Student student) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/${student.id}'),
        headers: _headers,
        body: json.encode(_serializeStudent(student)),
      );

      if (response.statusCode == 200) {
        return _deserializeStudent(json.decode(response.body));
      } else {
        throw Exception('Failed to update student. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (updateStudent): $e');
      rethrow;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/students/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService Error (deleteStudent): $e');
      return false;
    }
  }

  // ─── TEACHERS ─────────────────────────────────────────────────

  Future<List<Teacher>> fetchTeachers({String? search, String? filter, String? schoolId}) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (filter != null && filter.isNotEmpty) params['filter'] = filter;
      if (schoolId != null) params['schoolId'] = schoolId;

      final uri = Uri.parse('$baseUrl/teachers').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((j) => _deserializeTeacher(j)).toList();
      } else {
        throw Exception('Failed to fetch teachers. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchTeachers): $e');
      rethrow;
    }
  }

  Future<Teacher> addTeacher(Teacher teacher, {String? schoolId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teachers'),
        headers: _headers,
        body: json.encode(_serializeTeacher(teacher, schoolId: schoolId)),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _deserializeTeacher(json.decode(response.body));
      } else {
        throw Exception('Failed to add teacher. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (addTeacher): $e');
      rethrow;
    }
  }

  Future<Teacher> updateTeacher(Teacher teacher) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teachers/${teacher.id}'),
        headers: _headers,
        body: json.encode(_serializeTeacher(teacher)),
      );

      if (response.statusCode == 200) {
        return _deserializeTeacher(json.decode(response.body));
      } else {
        throw Exception('Failed to update teacher. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (updateTeacher): $e');
      rethrow;
    }
  }

  Future<bool> deleteTeacher(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService Error (deleteTeacher): $e');
      return false;
    }
  }

  // ─── SCHOOLS ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSchools() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schools'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch schools. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchSchools): $e');
      rethrow;
    }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schools/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService Error (deleteSchool): $e');
      return false;
    }
  }

  // ─── LIVE CLASSES ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLiveClasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/live-classes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch live classes. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchLiveClasses): $e');
      rethrow;
    }
  }

  // ─── SYSTEM EVENTS ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchEvents({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch events. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchEvents): $e');
      rethrow;
    }
  }

  Future<void> createEvent(String title, String desc) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/events'),
        headers: _headers,
        body: json.encode({'title': title, 'desc': desc, 'time': 'Just now'}),
      );
    } catch (e) {
      print('ApiService Error (createEvent): $e');
    }
  }

  // ─── LEAVE REQUESTS ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLeaves({String? status}) async {
    try {
      final uri = status != null
          ? Uri.parse('$baseUrl/leaves?status=$status')
          : Uri.parse('$baseUrl/leaves');

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch leaves. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (fetchLeaves): $e');
      rethrow;
    }
  }

  Future<void> updateLeaveStatus(String id, String status) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/leaves/$id'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
    } catch (e) {
      print('ApiService Error (updateLeaveStatus): $e');
    }
  }

  // ─── MEETINGS ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> createMeeting({String? title, String? hostedBy}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meetings'),
        headers: _headers,
        body: json.encode({
          'title': title ?? 'Urgent Faculty Meeting',
          'hostedBy': hostedBy ?? 'Admin',
          'duration': 600,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to create meeting. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error (createMeeting): $e');
      rethrow;
    }
  }

  // ─── SERIALIZATION HELPERS ────────────────────────────────────

  Student _deserializeStudent(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'N/A',
      gradeClass: json['class_level']?.toString() ?? json['class_name']?.toString() ?? json['gradeClass']?.toString() ?? 'N/A',
      rollNo: json['rollNo']?.toString() ?? json['roll_no']?.toString() ?? '0',
      lessonsCompleted: _toInt(json['lessonsCompleted'] ?? json['lessons_completed']),
      questsCompleted: _toInt(json['questsCompleted'] ?? json['quests_completed']),
      rank: json['rank']?.toString() ?? '#--',
      attendancePercentage: _toDouble(json['attendancePercentage'] ?? json['attendance_percentage']),
      homeworkDue: _toInt(json['homeworkDue'] ?? json['homework_due']),
      progressPercentChange: _toDouble(json['progressPercentChange'] ?? json['progress_percent_change']),
      schoolName: json['school_name']?.toString() ?? json['school']?.toString() ?? json['schoolName']?.toString(),
      schoolId: json['school_id']?.toString() ?? json['schoolId']?.toString(),
    );
  }

  Teacher _deserializeTeacher(Map<String, dynamic> json) {
    return Teacher(
      id: json['id']?.toString() ?? '',
      name: json['teacher_name']?.toString() ?? json['name']?.toString() ?? 'N/A',
      uid: json['uid']?.toString() ?? json['id']?.toString() ?? 'N/A',
      email: json['email']?.toString() ?? 'N/A',
      subject: json['subject']?.toString() ?? 'N/A',
      syllabusCompletion: _toDouble(json['syllabusCompletion'] ?? json['syllabus_completion']),
      classAttendance: _toDouble(json['classAttendance'] ?? json['class_attendance']),
      pendingDoubts: _toInt(json['pendingDoubts'] ?? json['pending_doubts']),
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? 'N/A',
      degree: json['degree']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? json['schoolId']?.toString(),
      schoolName: json['school_name']?.toString() ?? json['schoolName']?.toString(),
    );
  }

  Map<String, dynamic> _serializeStudent(Student student, {String? schoolId}) {
    return {
      'name': student.name,
      'gradeClass': student.gradeClass,
      'rollNo': student.rollNo,
      'lessonsCompleted': student.lessonsCompleted,
      'questsCompleted': student.questsCompleted,
      'rank': student.rank,
      'attendancePercentage': student.attendancePercentage,
      'homeworkDue': student.homeworkDue,
      'progressPercentChange': student.progressPercentChange,
      'schoolId': schoolId ?? student.schoolId,
    };
  }

  Map<String, dynamic> _serializeTeacher(Teacher teacher, {String? schoolId}) {
    return {
      'name': teacher.name,
      'uid': teacher.uid,
      'email': teacher.email,
      'subject': teacher.subject,
      'syllabusCompletion': teacher.syllabusCompletion,
      'classAttendance': teacher.classAttendance,
      'pendingDoubts': teacher.pendingDoubts,
      'mobile': teacher.mobile,
      'schoolId': schoolId ?? teacher.schoolId,
    };
  }

  // ─── PRINCIPALS COUNT ──────────────────────────────────────────

  Future<int> fetchPrincipalsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dashData = data['data'] ?? data;
        // Admin dashboard returns totalUsers which includes principals
        // Use a dedicated count or estimate from schools
        return _toInt(dashData['totalPrincipals'] ?? dashData['totalSchools'] ?? 0);
      }
    } catch (e) {
      print('ApiService Error (fetchPrincipalsCount): $e');
    }
    return 0;
  }


  // ─── FCM TOKEN ────────────────────────────────────────────────

  /// Register or refresh the FCM device token for the logged-in principal.
  /// Called after login and on token refresh.
  Future<void> saveFcmToken(String token) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/admin-messages/fcm-token'),
        headers: _headers,
        body: json.encode({'fcm_token': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('ApiService Error (saveFcmToken): $e');
    }
  }

  // ─── ADMIN MESSAGES ───────────────────────────────────────────
  /// Send a message from admin to one/multiple/all school principals.
  /// On success, also stores the notification via /api/v1/admin-messages
  Future<void> sendAdminMessage({
    required String message,
    required List<String> schoolIds,
    required bool sendToAll,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-messages'),
      headers: _headers,
      body: json.encode({
        'message': message,
        'schoolIds': schoolIds,
        'sendToAll': sendToAll,
        'sentAt': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errMsg = 'Failed to send admin message';
      try {
        final data = json.decode(response.body);
        errMsg = data['message'] ?? data['error'] ?? errMsg;
      } catch (_) {}
      throw Exception('$errMsg (Status ${response.statusCode})');
    }
  }

  /// Fetch admin messages for a given schoolId (principal notifications).
  Future<List<Map<String, dynamic>>> fetchAdminMessages({String? schoolId}) async {
    try {
      final queryParam = schoolId != null ? '?schoolId=$schoolId' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/admin-messages$queryParam'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('ApiService Error (fetchAdminMessages): $e');
    }
    return [];
  }

  /// Mark a specific admin message as read on the server.
  Future<void> markAdminMessageRead(String id) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/admin-messages/$id/read'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('ApiService Error (markAdminMessageRead): $e');
    }
  }

  /// Principal sends a reply / message back to the admin.
  Future<Map<String, dynamic>> sendPrincipalReply(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-messages/reply'),
      headers: _headers,
      body: json.encode({'message': message}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? data);
    }

    String errMsg = 'Failed to send reply';
    try {
      final data = json.decode(response.body);
      errMsg = data['message'] ?? data['error'] ?? errMsg;
    } catch (_) {}
    throw Exception('$errMsg (Status ${response.statusCode})');
  }

  /// Admin fetches all replies sent by principals.
  Future<List<Map<String, dynamic>>> fetchPrincipalReplies({String? schoolId}) async {
    try {
      final queryParam = schoolId != null ? '?schoolId=$schoolId' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/admin-messages/replies$queryParam'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('ApiService Error (fetchPrincipalReplies): $e');
    }
    return [];
  }

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
  double _toDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
}
