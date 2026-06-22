class Student {
  final String id;
  final String name;
  final String gradeClass;
  final String rollNo;
  final int lessonsCompleted;
  final int questsCompleted;
  final String rank;
  final double attendancePercentage;
  final int homeworkDue;
  final double progressPercentChange;
  final String? schoolName;
  final String? schoolId;

  Student({
    required this.id,
    required this.name,
    required this.gradeClass,
    required this.rollNo,
    required this.lessonsCompleted,
    required this.questsCompleted,
    required this.rank,
    required this.attendancePercentage,
    required this.homeworkDue,
    required this.progressPercentChange,
    this.schoolName,
    this.schoolId,
  });

  Student copyWith({
    String? id,
    String? name,
    String? gradeClass,
    String? rollNo,
    int? lessonsCompleted,
    int? questsCompleted,
    String? rank,
    double? attendancePercentage,
    int? homeworkDue,
    double? progressPercentChange,
    String? schoolName,
    String? schoolId,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeClass: gradeClass ?? this.gradeClass,
      rollNo: rollNo ?? this.rollNo,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      rank: rank ?? this.rank,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      homeworkDue: homeworkDue ?? this.homeworkDue,
      progressPercentChange: progressPercentChange ?? this.progressPercentChange,
      schoolName: schoolName ?? this.schoolName,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
