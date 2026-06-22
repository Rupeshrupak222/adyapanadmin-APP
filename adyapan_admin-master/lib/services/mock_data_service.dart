import 'dart:math';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class MockDataService {
  // Private Constructor for Singleton
  MockDataService._internal() {
    _initializeData();
  }

  static final MockDataService instance = MockDataService._internal();

  // Reactive Data Lists
  final ValueNotifier<List<Student>> studentsNotifier = ValueNotifier<List<Student>>([]);
  final ValueNotifier<List<Teacher>> teachersNotifier = ValueNotifier<List<Teacher>>([]);

  // School Tie-up Data
  final List<Map<String, dynamic>> schools = [];

  // Live Class Roster (Mock)
  final List<Map<String, dynamic>> liveClasses = [
    {
      'subject': 'Mathematics',
      'class': 'Grade 10-A',
      'teacher': 'Rahul',
      'time': '10:30 AM',
      'status': 'Starts in 10 mins',
      'isLive': false,
    },
    {
      'subject': 'Science - Physics',
      'class': 'Grade 9-B',
      'teacher': 'Priya Patel',
      'time': '12:00 PM',
      'status': 'Scheduled',
      'isLive': false,
    },
    {
      'subject': 'Mathematics Doubt Room',
      'class': 'Grade 10-A & B',
      'teacher': 'Rahul & Amit',
      'time': 'LIVE',
      'status': '12 active students • 2 mentors',
      'isLive': true,
    },
    {
      'subject': 'English Grammar Masterclass',
      'class': 'Grade 8-C',
      'teacher': 'Amit Verma',
      'time': 'LIVE',
      'status': '24 active students • 1 mentor',
      'isLive': true,
    }
  ];

  // System Events Feed
  final List<Map<String, dynamic>> systemEvents = [
    {
      'title': 'New Material Uploaded',
      'desc': 'Rahul uploaded "Chapter 3 - Circles Notes.pdf" for Grade 10-A',
      'time': '5 mins ago',
      'icon': Icons.picture_as_pdf,
      'color': Colors.redAccent,
    },
    {
      'title': 'Quest Accomplished',
      'desc': 'Kapish Bagde achieved Rank #12 in "Algebra Quest"',
      'time': '12 mins ago',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
    {
      'title': 'Homework Assigned',
      'desc': 'Amit Verma assigned homework "Daily Quest #8" to Grade 9',
      'time': '45 mins ago',
      'icon': Icons.assignment,
      'color': Colors.blueAccent,
    },
    {
      'title': 'System Sync Successful',
      'desc': 'All databases synced with Live DB Cloud',
      'time': '1 hour ago',
      'icon': Icons.sync,
      'color': Colors.green,
    }
  ];

  // Principal login credentials — email: principal{N}@adyapan.com, password: 1234
  // schoolId maps to school index (0-based)
  static const Map<String, int> principalEmailToSchoolIndex = {
    'principal1@adyapan.com': 0,
    'bagdekapish0012@gmail.com': 0,
    'principal2@adyapan.com': 1,
    'principal3@adyapan.com': 2,
    'principal4@adyapan.com': 3,
    'principal5@adyapan.com': 4,
    'principal6@adyapan.com': 5,
    'principal7@adyapan.com': 6,
    'principal8@adyapan.com': 7,
    'principal9@adyapan.com': 8,
    'principal10@adyapan.com': 9,
  };

  static const String principalPassword = '1234';

  /// Returns the school map for a given principal email, or null if not found.
  Map<String, dynamic>? getSchoolForPrincipal(String email) {
    final index = principalEmailToSchoolIndex[email.trim().toLowerCase()];
    if (index == null || index >= schools.length) return null;
    return schools[index];
  }

  void _initializeData() {
    // Dynamic generation of 10 schools, each with 200 students & 10 teachers
    final List<String> schoolNames = [
      'Adyapan Public School',
      'St. Xavier\'s High School',
      'Delhi Public School',
      'Ryan International School',
      'Sharda Mandir High School',
      'Convent of Jesus & Mary',
      'Podar International School',
      'Army Public School',
      'Orchid The International School',
      'Singhania High School',
    ];

    final List<String> principals = [
      'Dr. Amit Sen',
      'Fr. Sebastian S.J.',
      'Mrs. Sudha Murthy',
      'Mr. Rajesh Sharma',
      'Dr. Sunita Patil',
      'Sr. Mary Joseph',
      'Mrs. Vandana Lulla',
      'Col. Ranbir Singh',
      'Mrs. Manju Balasubramanyam',
      'Rev. Bro. D\'Souza',
    ];

    final List<String> locations = [
      'Mumbai, Maharashtra',
      'South Mumbai',
      'New Delhi',
      'Pune, Maharashtra',
      'Ahmedabad, Gujarat',
      'Dehradun, Uttarakhand',
      'Bangalore, Karnataka',
      'Kolkata, West Bengal',
      'Hyderabad, Telangana',
      'Thane, Maharashtra',
    ];

    final List<String> firstNames = [
      'Kapish', 'Aarav', 'Diya', 'Rohan', 'Ananya', 'Ryan', 'Sarah', 'Kunal', 'Neil', 'Alia',
      'Ranbir', 'Ishita', 'Gaurav', 'Sneha', 'Virat', 'Dhoni', 'Sachin', 'Priyanjali', 'Aditya', 'Tanisha',
      'Amitabh', 'ShahRukh', 'Abhishek', 'Aishwarya', 'Hrithik', 'Katrina', 'Deepika', 'Ranveer', 'Sidharth', 'Kiara'
    ];

    final List<String> lastNames = [
      'Bagde', 'Mehta', 'Sharma', 'Gupta', 'Iyer', 'D\'Souza', 'Fernandes', 'Kamra', 'Nitin', 'Bhatt',
      'Kapoor', 'Patel', 'Reddy', 'Kohli', 'Tendulkar', 'Roy', 'Birla', 'Mukherjee', 'Bachchan', 'Khan',
      'Roshan', 'Kaif', 'Padukone', 'Singh', 'Malhotra', 'Advani', 'Sen', 'Murthy', 'Rao', 'Varma'
    ];

    final List<String> fatherFirstNames = [
      'Rajesh', 'Suresh', 'Ramesh', 'Anil', 'Sunil', 'Amit', 'Vijay', 'Sanjay', 'Ajay', 'Manoj',
      'Deepak', 'Rakesh', 'Dinesh', 'Mahesh', 'Vinod', 'Arvind', 'Ashok', 'Prakash', 'Harish', 'Kishore'
    ];

    final List<String> teachers = [
      'Mrs. Sharma', 'Mr. Verma', 'Mrs. Rao', 'Mr. Patil', 'Ms. Iyer', 
      'Mr. Sen', 'Mrs. Gupta', 'Mr. Mehta', 'Ms. Reddy', 'Mrs. Birla'
    ];

    final List<String> futureSkills = [
      'AI & Machine Learning',
      'Robotics & IoT',
      'Mobile App Development',
      'UI/UX Product Design',
      'Financial Literacy',
      'Game Development (Unity)',
      'Cybersecurity & Ethics',
      'Public Speaking & Leadership'
    ];

    final List<String> classesList = [];
    for (int c = 1; c <= 10; c++) {
      classesList.add('Class $c-A');
      classesList.add('Class $c-B');
    }

    schools.clear();
    for (int i = 0; i < 10; i++) {
      final List<Map<String, dynamic>> schoolStudents = [];
      
      // Generate exactly 10 students in each class (20 classes total * 10 = 200 students per school)
      for (int cIndex = 0; cIndex < classesList.length; cIndex++) {
        final gradeClass = classesList[cIndex];
        
        for (int sVal = 0; sVal < 10; sVal++) {
          final studentId = cIndex * 10 + sVal;
          final fName = firstNames[(i * 200 + studentId) % firstNames.length];
          final lName = lastNames[(i * 173 + studentId * 7) % lastNames.length];
          
          final fatherFName = fatherFirstNames[(i * 13 + studentId * 11) % fatherFirstNames.length];
          final teacherName = teachers[(i + cIndex) % teachers.length];
          final email = '${fName.toLowerCase()}.${lName.toLowerCase()}$studentId@example.com';
          final mobileVal = 980000000 + (i * 123456 + studentId * 78901) % 19999999;
          final mobile = '+91 $mobileVal';
          final percentage = '${72 + (i * 5 + studentId * 11) % 26}.${(i * 3 + studentId * 7) % 10}%';
          
          final fSkill = futureSkills[(i * 5 + studentId * 13) % futureSkills.length];
          final skillAtt = '${84 + (i * 3 + studentId * 7) % 15}%';

          final hasDoubt = (sVal + i) % 4 == 0; // ~25% have doubts
          final isDoubtSolved = hasDoubt && ((sVal + i) % 3 == 0); // Some doubts are already solved
          final questions = ['Explain quadratic equations', 'What is thermodynamics?', 'Doubt in essay format', 'Help with trigonometry', 'Explain Newton\'s third law'];

          schoolStudents.add({
            'name': '$fName $lName',
            'class': gradeClass,
            'fatherName': 'Mr. $fatherFName $lName',
            'classTeacher': teacherName,
            'email': email,
            'mobile': mobile,
            'percentage': percentage,
            'futureSkill': fSkill,
            'skillAttendance': skillAtt,
            'hasDoubt': hasDoubt,
            'isDoubtSolved': isDoubtSolved,
            'doubtQuestion': questions[(i + sVal) % questions.length],
          });
        }
      }
      
      final List<Map<String, dynamic>> schoolTeachers = [];
      schoolTeachers.add({
        'name': 'Rupesh Rupak',
        'mobile': '8292244709',
        'email': 'rupesh@adyapan.com',
        'subject': 'Computer Science',
        'classes': ['Class 10-A', 'Class 10-B'],
        'degree': 'M.Tech (Computer Science)',
      });
      schoolTeachers.add({
        'name': 'Gulshan Kumar',
        'mobile': '7654253873',
        'email': 'gulshan@adyapan.com',
        'subject': 'Physics',
        'classes': ['Class 12-A'],
        'degree': 'M.Sc (Physics)',
      });
      
      schools.add({
        'id': 'sch_${i + 1}',
        'name': schoolNames[i],
        'principal': principals[i],
        'location': locations[i],
        'students': schoolStudents,
        'teachers': schoolTeachers,
        'studentAttendance': 85.0 + (i % 10) * 1.2,
        'teacherAttendance': 90.0 + (i % 8) * 1.1,
      });
    }

    final List<Student> allStudentsList = [];
    final List<Teacher> allTeachersList = [];
    for (var sch in schools) {
      final studentsList = sch['students'] as List<dynamic>? ?? [];
      for (var s in studentsList) {
        final percentageStr = s['percentage'].toString().replaceAll('%', '');
        final progressVal = 10.0 + (s['name'].hashCode % 10);
        allStudentsList.add(Student(
          id: s['email'].toString(),
          name: s['name'].toString(),
          gradeClass: s['class'].toString(),
          rollNo: (s['name'].hashCode % 50 + 1).toString(),
          lessonsCompleted: 30 + (s['name'].hashCode % 20),
          questsCompleted: 2 + (s['name'].hashCode % 8),
          rank: '#${(s['name'].hashCode % 100 + 1)}',
          attendancePercentage: double.tryParse(percentageStr) ?? 94.0,
          homeworkDue: s['name'].hashCode % 4,
          progressPercentChange: progressVal,
          schoolName: sch['name'].toString(),
        ));
      }
      
      final teachersList = sch['teachers'] as List<dynamic>? ?? [];
      for (var t in teachersList) {
        final email = t['email'].toString();
        // Prevent duplicate educators across schools in the global list
        if (!allTeachersList.any((teacher) => teacher.email == email)) {
          final attendanceVal = 90.0 + (t['name'].hashCode % 10);
          final syllabusVal = 60.0 + (t['name'].hashCode % 40);
          final doubtsCount = t['name'].hashCode % 5;
          allTeachersList.add(Teacher(
            id: email,
            name: t['name'].toString(),
            uid: '12${t['name'].hashCode % 1000}',
            email: email,
            subject: t['subject'].toString(),
            syllabusCompletion: syllabusVal,
            classAttendance: attendanceVal,
            pendingDoubts: doubtsCount,
            mobile: t['mobile'].toString(),
            degree: t['degree']?.toString() ?? getDegreeForSubject(t['subject'].toString()),
          ));
        }
      }
    }

    if (allStudentsList.isNotEmpty) {
      allStudentsList.shuffle(Random(42));
    }
    if (allTeachersList.isNotEmpty) {
      allTeachersList.shuffle(Random(42));
    }

    studentsNotifier.value = allStudentsList.isNotEmpty ? allStudentsList : [
      Student(
        id: 'st_1',
        name: 'Kapish Bagde',
        gradeClass: 'Grade 10-A',
        rollNo: '24',
        lessonsCompleted: 42,
        questsCompleted: 8,
        rank: '#12',
        attendancePercentage: 94.0,
        homeworkDue: 3,
        progressPercentChange: 12.0,
      ),
      Student(
        id: 'st_2',
        name: 'Aarav Mehta',
        gradeClass: 'Grade 10-A',
        rollNo: '01',
        lessonsCompleted: 38,
        questsCompleted: 6,
        rank: '#28',
        attendancePercentage: 91.5,
        homeworkDue: 1,
        progressPercentChange: 8.5,
      ),
      Student(
        id: 'st_3',
        name: 'Diya Sharma',
        gradeClass: 'Grade 9-B',
        rollNo: '12',
        lessonsCompleted: 45,
        questsCompleted: 10,
        rank: '#5',
        attendancePercentage: 96.2,
        homeworkDue: 0,
        progressPercentChange: 15.0,
      ),
      Student(
        id: 'st_4',
        name: 'Rohan Gupta',
        gradeClass: 'Grade 10-B',
        rollNo: '18',
        lessonsCompleted: 30,
        questsCompleted: 4,
        rank: '#45',
        attendancePercentage: 88.0,
        homeworkDue: 5,
        progressPercentChange: 4.8,
      ),
      Student(
        id: 'st_5',
        name: 'Ananya Iyer',
        gradeClass: 'Grade 9-A',
        rollNo: '07',
        lessonsCompleted: 41,
        questsCompleted: 7,
        rank: '#18',
        attendancePercentage: 93.4,
        homeworkDue: 2,
        progressPercentChange: 10.2,
      ),
    ];

    teachersNotifier.value = allTeachersList.isNotEmpty ? allTeachersList : [
      Teacher(
        id: 't_1',
        name: 'Rahul',
        uid: '12341',
        email: 'teacher@gmail.com',
        subject: 'Mathematics',
        syllabusCompletion: 72.5,
        classAttendance: 94.2,
        pendingDoubts: 1,
      ),
      Teacher(
        id: 't_2',
        name: 'Priya Patel',
        uid: '12342',
        email: 'priya@gmail.com',
        subject: 'Science - Physics',
        syllabusCompletion: 85.0,
        classAttendance: 95.5,
        pendingDoubts: 0,
      ),
      Teacher(
        id: 't_3',
        name: 'Amit Verma',
        uid: '12343',
        email: 'amit@gmail.com',
        subject: 'English',
        syllabusCompletion: 60.0,
        classAttendance: 91.0,
        pendingDoubts: 3,
      ),
      Teacher(
        id: 't_4',
        name: 'Sneha Rao',
        uid: '12344',
        email: 'sneha@gmail.com',
        subject: 'History',
        syllabusCompletion: 90.0,
        classAttendance: 96.8,
        pendingDoubts: 0,
      ),
    ];
  }

  // --- STUDENT OPERATIONS ---
  void addStudent(Student student) {
    final updatedList = List<Student>.from(studentsNotifier.value)..add(student);
    studentsNotifier.value = updatedList;
  }

  void updateStudent(Student updatedStudent) {
    final updatedList = studentsNotifier.value.map((student) {
      return student.id == updatedStudent.id ? updatedStudent : student;
    }).toList();
    studentsNotifier.value = updatedList;
  }

  void deleteStudent(String id) {
    final updatedList = studentsNotifier.value.where((student) => student.id != id).toList();
    studentsNotifier.value = updatedList;
  }

  // --- TEACHER OPERATIONS ---
  void addTeacher(Teacher teacher) {
    final updatedList = List<Teacher>.from(teachersNotifier.value)..add(teacher);
    teachersNotifier.value = updatedList;
  }

  void updateTeacher(Teacher updatedTeacher) {
    final updatedList = teachersNotifier.value.map((teacher) {
      return teacher.id == updatedTeacher.id ? updatedTeacher : teacher;
    }).toList();
    teachersNotifier.value = updatedList;
  }

  void deleteTeacher(String id) {
    final updatedList = teachersNotifier.value.where((teacher) => teacher.id != id).toList();
    teachersNotifier.value = updatedList;
  }

  // --- STATS COMPUTATION ---
  double getAverageStudentAttendance() {
    if (studentsNotifier.value.isEmpty) return 0.0;
    final total = studentsNotifier.value.fold<double>(0.0, (sum, st) => sum + st.attendancePercentage);
    return double.parse((total / studentsNotifier.value.length).toStringAsFixed(1));
  }

  double getAverageTeacherAttendance() {
    if (teachersNotifier.value.isEmpty) return 0.0;
    final total = teachersNotifier.value.fold<double>(0.0, (sum, t) => sum + t.classAttendance);
    return double.parse((total / teachersNotifier.value.length).toStringAsFixed(1));
  }

  double getAverageSyllabusCompletion() {
    if (teachersNotifier.value.isEmpty) return 0.0;
    final total = teachersNotifier.value.fold<double>(0.0, (sum, t) => sum + t.syllabusCompletion);
    return double.parse((total / teachersNotifier.value.length).toStringAsFixed(1));
  }

  int getTotalPendingDoubts() {
    return teachersNotifier.value.fold<int>(0, (sum, t) => sum + t.pendingDoubts);
  }

  static String getDegreeForSubject(String subject) {
    switch (subject) {
      case 'Mathematics':
        return 'Ph.D., M.Sc. (Mathematics)';
      case 'Physics':
        return 'M.Sc., Ph.D. (Physics)';
      case 'Chemistry':
        return 'M.Sc., Ph.D. (Chemistry)';
      case 'Biology':
        return 'M.Sc., B.Ed. (Biology)';
      case 'English':
        return 'M.A., B.Ed. (English Literature)';
      case 'History':
        return 'M.A., Ph.D. (History)';
      case 'Geography':
        return 'M.Sc., B.Ed. (Geography)';
      case 'Computer Science':
        return 'M.Tech, B.Tech (Computer Science)';
      case 'Civics':
        return 'M.A., B.Ed. (Civics)';
      case 'Environmental Studies':
        return 'M.Sc., B.Ed. (EVS)';
      default:
        return 'M.Sc., B.Ed.';
    }
  }
}
