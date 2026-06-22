class Teacher {
  final String id;
  final String name;
  final String uid;
  final String email;
  final String subject;
  final double syllabusCompletion;
  final double classAttendance;
  final int pendingDoubts;
  final String mobile;
  final String degree;
  final String? schoolId;
  final String? schoolName;

  Teacher({
    required this.id,
    required this.name,
    required this.uid,
    required this.email,
    required this.subject,
    required this.syllabusCompletion,
    required this.classAttendance,
    required this.pendingDoubts,
    this.mobile = '+91 98765 43210',
    this.degree = 'M.Sc., B.Ed.',
    this.schoolId,
    this.schoolName,
  });

  Teacher copyWith({
    String? id,
    String? name,
    String? uid,
    String? email,
    String? subject,
    double? syllabusCompletion,
    double? classAttendance,
    int? pendingDoubts,
    String? mobile,
    String? degree,
    String? schoolId,
    String? schoolName,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      syllabusCompletion: syllabusCompletion ?? this.syllabusCompletion,
      classAttendance: classAttendance ?? this.classAttendance,
      pendingDoubts: pendingDoubts ?? this.pendingDoubts,
      mobile: mobile ?? this.mobile,
      degree: degree ?? this.degree,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
    );
  }
}
