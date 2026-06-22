import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/mock_data_service.dart';
import '../models/teacher.dart';

class TeachersTab extends StatefulWidget {
  final String role;
  /// For principals: their specific school data. Null for Admin.
  final Map<String, dynamic>? schoolData;
  const TeachersTab({super.key, required this.role, this.schoolData});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  final _dataService = DataService.instance;
  final _mockService = MockDataService.instance;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Behind Syllabus', 'Pending Doubts', 'High Attendance'
  List<Map<String, dynamic>> _schools = [];
  bool _isLoadingSchools = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSchools();
  }

  Future<void> _loadData() async {
    await _dataService.loadTeachers();
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

  void _showAddEditTeacherDialog([Teacher? teacher]) {
    final isEdit = teacher != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: teacher?.name ?? '');
    final uidController = TextEditingController(text: teacher?.uid ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final subjectController = TextEditingController(text: teacher?.subject ?? '');
    final mobileController = TextEditingController(text: teacher?.mobile ?? '');
    final syllabusController = TextEditingController(
      text: teacher != null ? teacher.syllabusCompletion.toString() : '0.0',
    );
    final attendanceController = TextEditingController(
      text: teacher != null ? teacher.classAttendance.toString() : '90.0',
    );
    final doubtsController = TextEditingController(
      text: teacher != null ? teacher.pendingDoubts.toString() : '0',
    );

    String? selectedSchoolId = teacher?.schoolId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        title: Text(
          isEdit ? 'Modify Teacher Profile' : 'Link New Educator',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormField(controller: nameController, label: 'Teacher Name', hint: 'e.g. Rahul'),
                const SizedBox(height: 12),
                if (widget.role != 'Principal') ...[
                  _buildFormField(
                    controller: uidController,
                    label: 'Teacher UID',
                    hint: 'e.g. 12341',
                    enabled: !isEdit,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildFormField(
                  controller: emailController,
                  label: 'Email Address',
                  hint: 'e.g. teacher@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildFormField(controller: subjectController, label: 'Subject Assigned', hint: 'e.g. Mathematics'),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: mobileController,
                  label: 'Mobile Number',
                  hint: 'e.g. +91 98765 43210',
                  keyboardType: TextInputType.phone,
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
                if (widget.role != 'Principal') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          controller: syllabusController,
                          label: 'Syllabus %',
                          hint: '0-100',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          controller: attendanceController,
                          label: 'Attendance %',
                          hint: '0-100',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    controller: doubtsController,
                    label: 'Pending Doubts Count',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ],
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

              final syllabus = double.tryParse(syllabusController.text) ?? 0.0;
              final attendance = double.tryParse(attendanceController.text) ?? 90.0;
              final doubts = int.tryParse(doubtsController.text) ?? 0;
              final mobile = mobileController.text.trim();

              if (isEdit) {
                final updated = teacher.copyWith(
                  name: nameController.text,
                  email: emailController.text,
                  subject: subjectController.text,
                  syllabusCompletion: syllabus,
                  classAttendance: attendance,
                  pendingDoubts: doubts,
                  mobile: mobile.isNotEmpty ? mobile : teacher.mobile,
                );
                _dataService.updateTeacher(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher profile updated successfully!'), behavior: SnackBarBehavior.floating),
                );
              } else {
                final uid = widget.role == 'Principal'
                    ? 't_uid_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                    : uidController.text;
                final newTeacher = Teacher(
                  id: 't_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  uid: uid,
                  email: emailController.text,
                  subject: subjectController.text,
                  syllabusCompletion: widget.role == 'Principal' ? 0.0 : syllabus,
                  classAttendance: widget.role == 'Principal' ? 95.0 : attendance,
                  pendingDoubts: widget.role == 'Principal' ? 0 : doubts,
                  mobile: mobile.isNotEmpty ? mobile : '+91 98765 43210',
                  schoolId: selectedSchoolId,
                );
                _dataService.addTeacher(newTeacher, schoolId: selectedSchoolId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Educator linked to database!'), behavior: SnackBarBehavior.floating),
                );
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Save Changes' : 'Link Educator'),
          ),
        ],
      ),
    );
  }


  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Field required';
        }
        return null;
      },
    );
  }

  void _handleDeleteTeacher(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Educator', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${teacher.name} from the school registry? This will unlink their ongoing roadmap modules.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.deleteTeacher(teacher.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${teacher.name} successfully deleted from registry.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'Admin';
    final isPrincipal = widget.role == 'Principal';
    final canManage = isAdmin; // Principal is view-only — no editing
    // Note: isPrincipal used to allow link teacher in previous version;
    //       now Principal is fully read-only

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<List<Teacher>>(
        valueListenable: _dataService.teachersNotifier,
        builder: (context, teachers, _) {
          List<Teacher> displayTeachers = teachers;

          // 1. Apply Search
          final query = _searchController.text.toLowerCase();
          var filteredList = displayTeachers.where((t) {
            return t.name.toLowerCase().contains(query) || t.subject.toLowerCase().contains(query);
          }).toList();

          // 2. Apply Custom Filters
          if (_selectedFilter == 'Behind Syllabus') {
            filteredList = filteredList.where((t) => t.syllabusCompletion < 75.0).toList();
          } else if (_selectedFilter == 'Pending Doubts') {
            filteredList = filteredList.where((t) => t.pendingDoubts > 0).toList();
          } else if (_selectedFilter == 'High Attendance') {
            filteredList = filteredList.where((t) => t.classAttendance > 94.0).toList();
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
                      color: const Color(0xFF8B5CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_rounded, color: Color(0xFF6D28D9), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View Only — You are viewing your school\'s educators directory',
                            style: TextStyle(color: Color(0xFF6D28D9), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildFilterBar(),
                const SizedBox(height: 24),

                // Responsive layout container
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
                                      child: _buildTeacherCard(filteredList[index], canManage, canDelete: isAdmin),
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
                                  childAspectRatio: 1.45,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildTeacherCard(filteredList[index], canManage, canDelete: isAdmin);
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
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditTeacherDialog(),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Link Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
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
                hintText: isNarrow ? 'Search educators...' : 'Search teachers by name or subject...',
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
                _buildFilterChip('Behind Syllabus'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending Doubts'),
                const SizedBox(width: 8),
                _buildFilterChip('High Attendance'),
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
        setState(() {
          if (isSelected) {
            _selectedFilter = 'All'; // toggle off back to 'All'
          } else {
            _selectedFilter = filterName;
          }
        });
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

  void _showTeacherDetailDialog(Teacher teacher) {
    // Attempt to find classes assigned from the schools data structure in MockDataService
    List<dynamic> classesList = [];
    for (var sch in _mockService.schools) {
      final list = sch['teachers'] as List<dynamic>? ?? [];
      for (var t in list) {
        if (t['name'] == teacher.name) {
          classesList = t['classes'] as List<dynamic>? ?? [];
          break;
        }
      }
      if (classesList.isNotEmpty) break;
    }
    
    // Fallback classes if not found in active ties
    if (classesList.isEmpty) {
      classesList = ['Class 10-A', 'Class 9-B'];
    }

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
                          'EDUCATOR PROFILE',
                          style: TextStyle(
                            color: Color(0xFF6D28D9),
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
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFEDE9FE),
                      child: Text(
                        (() {
                          final name = teacher.name;
                          final parts = name.split(' ');
                          return parts.length > 1
                              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                              : name.substring(0, 2).toUpperCase();
                        })(),
                        style: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher.degree,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Text(
                        teacher.subject,
                        style: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Mobile Number',
                      value: teacher.mobile,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Email Address',
                      value: teacher.email,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.bookmark_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Subject Taught',
                      value: teacher.subject,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CLASSES ASSIGNED',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: classesList.map((cls) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDCE3FA)),
                          ),
                          child: Text(
                            cls.toString(),
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
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
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard(Teacher teacher, bool isAdmin, {bool canDelete = true}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showTeacherDetailDialog(teacher),
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
            mainAxisSize: MainAxisSize.min, // Dynamic wrap spacing
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header of Teacher Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Avatar containing Teacher Initials
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Text(
                        teacher.name.split(' ').map((e) => e[0]).join().toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
    
                    // Detail Segment
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  teacher.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'UID ${teacher.uid}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.email,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teacher.subject,
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
    
                    // Edit Actions (Admin/Principal can edit, only Admin can delete)
                    if (isAdmin) ...[
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showAddEditTeacherDialog(teacher);
                          } else if (val == 'delete') {
                            _handleDeleteTeacher(teacher);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Profile'),
                              ],
                            ),
                          ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text('Remove Teacher'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
    
              const Divider(color: Color(0xFFF1F5F9), height: 1),
    
              // Statistics footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    // Syllabus Completion
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Syllabus Completion',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${teacher.syllabusCompletion}%',
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: teacher.syllabusCompletion / 100.0,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              teacher.syllabusCompletion < 70.0
                                  ? const Color(0xFF8B5CF6) // Purple
                                  : const Color(0xFF10B981), // Green
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
    
                    // Bottom Metrics (Attendance & Doubts)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            const Text(
                              'Attendance: ',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                            Text(
                              '${teacher.classAttendance}%',
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: teacher.pendingDoubts > 0
                                ? const Color(0xFFEF4444).withOpacity(0.08)
                                : const Color(0xFF10B981).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                teacher.pendingDoubts > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                                size: 12,
                                color: teacher.pendingDoubts > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                teacher.pendingDoubts > 0
                                    ? '${teacher.pendingDoubts} Doubts'
                                    : '0 Doubts',
                                style: TextStyle(
                                  color: teacher.pendingDoubts > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
            'No matching educators found',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your search criteria or filter chips.',
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
