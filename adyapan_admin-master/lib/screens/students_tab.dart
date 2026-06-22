import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/mock_data_service.dart';
import '../models/student.dart';

class StudentsTab extends StatefulWidget {
  final String role;
  /// For principals: their specific school data. Null for Admin.
  final Map<String, dynamic>? schoolData;
  const StudentsTab({super.key, required this.role, this.schoolData});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _dataService = DataService.instance;
  final _mockService = MockDataService.instance;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Top Performers', 'Low Attendance', 'Pending Homework'
  List<Map<String, dynamic>> _schools = [];
  bool _isLoadingSchools = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSchools();
  }

  Future<void> _loadData() async {
    if (widget.schoolData != null) {
      await _dataService.loadStudents(schoolId: widget.schoolData!['id']?.toString());
    } else {
      await _dataService.loadStudents();
    }
  }

  Future<void> _loadSchools() async {
    if (widget.role == 'Admin') {
      setState(() {
        _isLoadingSchools = true;
      });
      try {
        final list = await _dataService.fetchSchools();
        setState(() {
          _schools = list;
        });
      } catch (e) {
        debugPrint('Error loading schools: $e');
      } finally {
        setState(() {
          _isLoadingSchools = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditStudentDialog([Student? student]) {
    final isEdit = student != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: student?.name ?? '');
    final gradeController = TextEditingController(text: student?.gradeClass ?? 'Grade 10-A');
    final rollController = TextEditingController(text: student?.rollNo ?? '');
    final lessonsController = TextEditingController(text: student != null ? student.lessonsCompleted.toString() : '0');
    final questsController = TextEditingController(text: student != null ? student.questsCompleted.toString() : '0');
    final rankController = TextEditingController(text: student?.rank ?? '#--');
    final attendanceController = TextEditingController(
      text: student != null ? student.attendancePercentage.toString() : '95.0',
    );
    final homeworkController = TextEditingController(text: student != null ? student.homeworkDue.toString() : '0');
    final progressController = TextEditingController(
      text: student != null ? student.progressPercentChange.toString() : '0.0',
    );

    String? selectedSchoolId = student?.schoolId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          isEdit ? 'Modify Student File' : 'Enroll New Student',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormField(controller: nameController, label: 'Student Full Name', hint: 'e.g. Kapish Bagde'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(controller: gradeController, label: 'Grade/Class', hint: 'e.g. Grade 10-A'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(controller: rollController, label: 'Roll Number', hint: 'e.g. 24'),
                    ),
                  ],
                ),
                if (widget.role == 'Admin' && !isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSchoolId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Select School',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                    items: _schools.map((school) {
                      return DropdownMenuItem<String>(
                        value: school['id']?.toString(),
                        child: Text(
                          school['name']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      selectedSchoolId = val;
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select a school';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: lessonsController,
                        label: 'Lessons Done',
                        hint: 'e.g. 42',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: questsController,
                        label: 'Quests Done',
                        hint: 'e.g. 8',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(controller: rankController, label: 'Roster Rank', hint: 'e.g. #12'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: homeworkController,
                        label: 'Homework Due',
                        hint: 'e.g. 3',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: attendanceController,
                        label: 'Attendance %',
                        hint: 'e.g. 94.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: progressController,
                        label: 'Progress +/- %',
                        hint: 'e.g. 12.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final lessons = int.tryParse(lessonsController.text) ?? 0;
              final quests = int.tryParse(questsController.text) ?? 0;
              final attendance = double.tryParse(attendanceController.text) ?? 95.0;
              final homework = int.tryParse(homeworkController.text) ?? 0;
              final progress = double.tryParse(progressController.text) ?? 0.0;

              if (isEdit) {
                final updated = student.copyWith(
                  name: nameController.text,
                  gradeClass: gradeController.text,
                  rollNo: rollController.text,
                  lessonsCompleted: lessons,
                  questsCompleted: quests,
                  rank: rankController.text,
                  attendancePercentage: attendance,
                  homeworkDue: homework,
                  progressPercentChange: progress,
                );
                _dataService.updateStudent(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student file updated!'), behavior: SnackBarBehavior.floating),
                );
              } else {
                final newStudent = Student(
                  id: 'st_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  gradeClass: gradeController.text,
                  rollNo: rollController.text,
                  lessonsCompleted: lessons,
                  questsCompleted: quests,
                  rank: rankController.text,
                  attendancePercentage: attendance,
                  homeworkDue: homework,
                  progressPercentChange: progress,
                  schoolId: selectedSchoolId,
                );
                _dataService.addStudent(newStudent, schoolId: selectedSchoolId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student enrolled successfully!'), behavior: SnackBarBehavior.floating),
                );
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Save Changes' : 'Enroll Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  void _handleDeleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Disenroll Student', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to disenroll ${student.name} (Roll ${student.rollNo}) from the school registrar?',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.deleteStudent(student.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} successfully disenrolled.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disenroll'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'Admin';
    final isPrincipal = widget.role == 'Principal';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<List<Student>>(
        valueListenable: _dataService.studentsNotifier,
        builder: (context, students, _) {
          List<Student> displayStudents = students;
          if (widget.schoolData != null) {
            final schoolId = widget.schoolData!['id']?.toString();
            displayStudents = students.where((s) => s.schoolId == schoolId).toList();
          }

          // 1. Search Query
          final query = _searchController.text.toLowerCase();
          var filteredList = displayStudents.where((st) {
            return st.name.toLowerCase().contains(query) || 
                   st.gradeClass.toLowerCase().contains(query) ||
                   (st.schoolName?.toLowerCase().contains(query) ?? false);
          }).toList();

          // 2. Custom Filter
          if (_selectedFilter == 'Top Performers') {
            filteredList = filteredList.where((st) {
              final rankNum = int.tryParse(st.rank.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;
              return rankNum <= 15;
            }).toList();
          } else if (_selectedFilter == 'Low Attendance') {
            filteredList = filteredList.where((st) => st.attendancePercentage < 92.5).toList();
          } else if (_selectedFilter == 'Pending Homework') {
            filteredList = filteredList.where((st) => st.homeworkDue > 0).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View-only banner for Principal
                if (isPrincipal) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_rounded, color: Color(0xFF1D4ED8), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View Only — You are viewing your school\'s students directory',
                            style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildFilterBar(),
                const SizedBox(height: 24),

                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      await Future.wait([
                        _loadData(),
                        _loadSchools(),
                      ]);
                    },
                    child: filteredList.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 300,
                              child: _buildEmptyState(),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth > 750 ? 2 : 1;

                              if (cols == 1) {
                                return ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: _buildStudentCard(filteredList[index], isAdmin),
                                    );
                                  },
                                );
                              }

                              return GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.35,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildStudentCard(filteredList[index], isAdmin);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditStudentDialog(),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Enroll Student', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final searchField = SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                hintText: isNarrow ? 'Search students...' : 'Search students by name or class...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );

          final filterRow = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Top Performers'),
                const SizedBox(width: 8),
                _buildFilterChip('Low Attendance'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending Homework'),
              ],
            ),
          );

          return isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    filterRow,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: searchField,
                    ),
                    const SizedBox(width: 16),
                    filterRow,
                  ],
                );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = _selectedFilter == filterName;
    return ChoiceChip(
      label: Text(
        filterName,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = filterName;
          });
        }
      },
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      showCheckmark: false,
    );
  }

  void _showStudentDetailDialog(Student student) {
    // Attempt to find full student metadata from active schools list
    Map<String, dynamic>? studentMeta;
    
    for (var sch in _mockService.schools) {
      final list = sch['students'] as List<dynamic>? ?? [];
      for (var st in list) {
        if (st['name'] == student.name) {
          studentMeta = Map<String, dynamic>.from(st as Map);
          break;
        }
      }
      if (studentMeta != null) break;
    }

    final fatherName = studentMeta?['fatherName'] ?? 'Mr. Rajesh ${student.name.split(' ').last}';
    final classTeacher = studentMeta?['classTeacher'] ?? 'Mrs. Sharma';
    final email = studentMeta?['email'] ?? '${student.name.toLowerCase().replaceAll(' ', '.')}@example.com';
    final mobile = studentMeta?['mobile'] ?? '+91 98000 12345';
    final lastExamPercentage = studentMeta?['percentage'] ?? '85.4%';
    final futureSkill = studentMeta?['futureSkill'] ?? 'AI & Machine Learning';
    final skillAttendance = studentMeta?['skillAttendance'] ?? '94%';

    showDialog(
      context: context,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Dialog(
          backgroundColor: isMobile ? Colors.white : Colors.transparent,
          insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Container(
            constraints: isMobile
                ? BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: MediaQuery.of(context).size.height)
                : const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
              border: isMobile ? null : Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: isMobile
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Premium Gradient Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STUDENT PROFILE',
                          style: TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF475569), size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Large circular initials avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        (() {
                          final name = student.name;
                          final parts = name.split(' ');
                          return parts.length > 1
                              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                              : name.substring(0, 2).toUpperCase();
                        })(),
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    
                    // Class pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        student.gradeClass,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.face_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Father\'s Name',
                      value: fatherName,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      label: 'Class Teacher',
                      value: classTeacher,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Email Address',
                      value: email,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Parents Mobile',
                      value: mobile,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.percent_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Last Exam Score',
                      value: lastExamPercentage,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.rocket_launch_rounded,
                      iconColor: const Color(0xFF8B5CF6), // Purple
                      label: 'Future Skill',
                      value: futureSkill,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.verified_rounded,
                      iconColor: const Color(0xFF10B981), // Green
                      label: 'Skills Attendance',
                      value: skillAttendance,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? iconColor : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student, bool isAdmin) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showStudentDetailDialog(student),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Natural wrapping
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Segment
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                          child: Text(
                            student.name.split(' ').map((e) => e[0]).join().toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
    
                        // Name, roll
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student.name,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (student.schoolName != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
                                      ),
                                      child: Text(
                                        student.schoolName!,
                                        style: const TextStyle(
                                          color: Color(0xFF4F46E5),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    student.gradeClass,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.circle, size: 4, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Roll ${student.rollNo}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
    
                        // Popups (Admin edit/delete options)
                        if (isAdmin) ...[
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddEditStudentDialog(student);
                              } else if (val == 'delete') {
                                _handleDeleteStudent(student);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                                      SizedBox(width: 8),
                                    Text('Edit File'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Disenroll Student'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
    
                    // Milestones Grid (Lessons, Quests, Rank)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMilestoneTag(
                          label: 'LESSONS',
                          value: student.lessonsCompleted.toString(),
                          icon: '📚',
                        ),
                        _buildMilestoneTag(
                          label: 'QUESTS',
                          value: student.questsCompleted.toString(),
                          icon: '🎯',
                        ),
                        _buildMilestoneTag(
                          label: 'RANK',
                          value: student.rank,
                          icon: '🏆',
                          isGolden: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    
              const Divider(color: Color(0xFFF1F5F9), height: 1),
    
              // Footers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Attendance Ratio
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ATTENDANCE',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${student.attendancePercentage}%',
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
    
                    // Homework Due status
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions_rounded,
                          size: 14,
                          color: student.homeworkDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'HOMEWORK',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              student.homeworkDue > 0 ? '${student.homeworkDue} due' : 'All clear',
                              style: TextStyle(
                                color: student.homeworkDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
    
                    // Progress Tier
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${student.progressPercentChange}% Progress',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneTag({
    required String label,
    required String value,
    required String icon,
    bool isGolden = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isGolden ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGolden ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isGolden ? const Color(0xFFB45309) : const Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isGolden ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching students found',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try resetting your search query or change filter categories.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
