import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';

class OverviewTab extends StatefulWidget {
  final String role;
  /// For principals: their specific school data. Null for Admin.
  final Map<String, dynamic>? schoolData;
  final String? displayName;
  const OverviewTab({super.key, required this.role, this.schoolData, this.displayName});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _dataService = DataService.instance;
  final _mockService = MockDataService.instance;
  List<Map<String, dynamic>> _schools = [];
  int _principalsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _loadPrincipalsCount();
  }

  Future<void> _loadPrincipalsCount() async {
    try {
      final count = await ApiService.instance.fetchPrincipalsCount();
      if (mounted) setState(() { _principalsCount = count; });
    } catch (_) {}
  }

  Future<void> _loadSchools() async {
    final schools = await _dataService.fetchSchools();
    if (mounted) {
      final seenNames = <String>{};
      final uniqueSchools = <Map<String, dynamic>>[];
      for (final s in schools) {
        final name = (s['name'] ?? '').toString().trim().toLowerCase();
        if (name.isNotEmpty && !seenNames.contains(name)) {
          seenNames.add(name);
          uniqueSchools.add(s);
        }
      }
      setState(() {
        _schools = uniqueSchools;
      });
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await Future.wait([
        _loadSchools(),
        _dataService.initialize(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  void _showAnnouncementDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text('Broadcast Announcement', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This announcement will be pushed instantly to the Student Portal (Kapish Bagde) and Educator Portal (Rahul).',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type announcement details here...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _mockService.systemEvents.insert(0, {
                    'title': 'System Announcement',
                    'desc': text,
                    'time': 'Just now',
                    'icon': Icons.campaign_rounded,
                    'color': Colors.amber,
                  });
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement broadcasted successfully to all devices!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Broadcast Now'),
          ),
        ],
      ),
    );
  }

  void _showSchoolsDialog(BuildContext context, {bool isTeachersView = false}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8EEF9), // Soft ice grey-blue
                    Color(0xFFDCE3FA), // Premium pastel lavender-indigo
                    Color(0xFFEBF1FF), // Soft lavender white
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isTeachersView ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isTeachersView ? Icons.co_present_rounded : Icons.domain_rounded,
                                color: isTeachersView ? const Color(0xFF6D28D9) : const Color(0xFF2563EB),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTeachersView ? 'Educators Index' : 'Tie-up Schools',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isTeachersView ? 'Partner school teachers registry' : 'Active school partnerships',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  
                  // Body (List of Schools)
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      shrinkWrap: true,
                      itemCount: _schools.length,
                      itemBuilder: (context, index) {
                        final school = _schools[index];
                        final schoolName = (school['name'] ?? '').toString().toLowerCase();
                        final schoolId = (school['id'] ?? '').toString();
                        
                        // Count students/teachers from loaded data matching this school
                        final allStudents = _dataService.studentsNotifier.value;
                        final allTeachers = _dataService.teachersNotifier.value;
                        final studentCount = allStudents.where((s) => 
                          (s.schoolName?.toLowerCase() == schoolName) || 
                          (s.schoolId == schoolId && schoolId.isNotEmpty)
                        ).length;
                        final teacherCount = allTeachers.where((t) =>
                          (t.schoolName?.toLowerCase() == schoolName) ||
                          (t.schoolId == schoolId && schoolId.isNotEmpty)
                        ).length;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (isTeachersView) {
                                  _showSchoolTeachersDialog(context, school);
                                } else {
                                  _showSchoolStudentsDialog(context, school);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // School Avatar/Icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            (isTeachersView ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withOpacity(0.2),
                                            const Color(0xFF8B5CF6).withOpacity(0.2),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFDCE3FA)),
                                      ),
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: isTeachersView ? const Color(0xFF6D28D9) : const Color(0xFF2563EB),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // School details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            school['name'] ?? 'School Name',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 13),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Principal: ${school['contact_person'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 12.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_rounded, color: Color(0xFF64748B), size: 12),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  school['city'] ?? school['address'] ?? 'Location N/A',
                                                  style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 11.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Badge & Arrow
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isTeachersView ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: (isTeachersView ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            isTeachersView ? '$teacherCount Teach' : '$studentCount Stu',
                                            style: TextStyle(
                                              color: isTeachersView ? const Color(0xFF6D28D9) : const Color(0xFF0D9488),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSchoolStudentsDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    String selectedClassFilter = 'All Classes';
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final searchQuery = searchController.text.trim();
            final allStudents = _dataService.studentsNotifier.value;
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final List<Map<String, dynamic>> rawStudents = allStudents
                .where((s) =>
                    (s.schoolName?.toLowerCase() == schoolName) ||
                    (s.schoolId == schoolId && schoolId.isNotEmpty))
                .map((s) => {
                      'id': s.id,
                      'name': s.name,
                      'class': s.gradeClass,
                      'rollNo': s.rollNo,
                      'attendance': s.attendancePercentage,
                      'schoolName': s.schoolName,
                      'schoolId': s.schoolId,
                      'fatherName': 'Rajesh ${s.name.split(' ').last}',
                      'classTeacher': 'S. K. Sharma',
                      'email': '${s.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
                      'mobile': '+91 98765 43210',
                    })
                .toList();
            
            // Build available classes list dynamically
            final List<String> availableClasses = ['All Classes'];
            for (var st in rawStudents) {
              final cls = st['class']?.toString() ?? '';
              if (cls.isNotEmpty && !availableClasses.contains(cls)) {
                availableClasses.add(cls);
              }
            }
            // Sort classes so they appear in beautiful ordered format (Class 1, Class 2...)
            availableClasses.sort((a, b) {
              if (a == 'All Classes') return -1;
              if (b == 'All Classes') return 1;
              
              try {
                final aNum = int.parse(a.split(' ')[1].split('-')[0]);
                final bNum = int.parse(b.split(' ')[1].split('-')[0]);
                if (aNum != bNum) return aNum.compareTo(bNum);
              } catch (_) {}
              return a.compareTo(b);
            });
 
            // Filter students by search query AND class filter
            final filteredStudents = rawStudents.where((st) {
              final name = (st['name'] ?? '').toString().toLowerCase();
              final matchesSearch = name.contains(searchQuery.toLowerCase());
              
              final cls = st['class']?.toString() ?? '';
              final matchesClass = selectedClassFilter == 'All Classes' || cls == selectedClassFilter;
              
              return matchesSearch && matchesClass;
            }).toList();
            
            // Group filtered students class-wise
            final Map<String, List<Map<String, dynamic>>> groupedStudents = {};
            for (var item in filteredStudents) {
              final student = Map<String, dynamic>.from(item as Map);
              final gradeClass = student['class'] ?? 'General';
              groupedStudents.putIfAbsent(gradeClass, () => []).add(student);
            }
            
            // Sort grouped class keys using the same custom sorting logic
            final sortedClasses = groupedStudents.keys.toList()
              ..sort((a, b) {
                try {
                  final aNum = int.parse(a.split(' ')[1].split('-')[0]);
                  final bNum = int.parse(b.split(' ')[1].split('-')[0]);
                  if (aNum != bNum) return aNum.compareTo(bNum);
                } catch (_) {}
                return a.compareTo(b);
              });
 
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8EEF9), // Soft ice grey-blue
                    Color(0xFFDCE3FA), // Premium pastel lavender-indigo
                    Color(0xFFEBF1FF), // Soft lavender white
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      school['name'] ?? 'School Students',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Principal: ${school['contact_person'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
                          onPressed: () {
                            Navigator.of(context).pop(); // dismiss students dialog
                            Navigator.of(context).pop(); // dismiss schools dialog too to return to main dashboard
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Search Bar & Class Dropdown Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: searchController,
                            onChanged: (val) {
                              setStateDialog(() {});
                            },
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search student names...',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF475569), size: 18),
                                      onPressed: () {
                                        searchController.clear();
                                        setStateDialog(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF6366F1)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Class Dropdown Filter
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedClassFilter,
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                                isExpanded: true,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                items: availableClasses.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setStateDialog(() {
                                    selectedClassFilter = newValue ?? 'All Classes';
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  
                  // Body (Grouped Student List)
                  Flexible(
                    child: filteredStudents.isEmpty
                         ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF64748B),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Students Found',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No student matching "${searchController.text}" was found in this school.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shrinkWrap: true,
                            itemCount: sortedClasses.length,
                            itemBuilder: (context, classIndex) {
                              final className = sortedClasses[classIndex];
                              final studentsInClass = groupedStudents[className]!;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Class Header
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          className,
                                          style: const TextStyle(
                                            color: Color(0xFF6D28D9), // Purple accent
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${studentsInClass.length}',
                                            style: const TextStyle(
                                              color: Color(0xFF6D28D9),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 12),
                                            child: Divider(color: Color(0xFFE2E8F0), height: 1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Grid of students in class
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isMobile = constraints.maxWidth < 600;
                                      final crossAxisCount = isMobile ? 1 : 2;
                                      final childAspectRatio = isMobile ? 4.2 : 3.2;
 
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemCount: studentsInClass.length,
                                        itemBuilder: (context, studIndex) {
                                          final student = studentsInClass[studIndex];
                                          final studName = student['name'] ?? 'N/A';
                                          
                                          // Extract initials for Avatar
                                          final nameParts = studName.split(' ');
                                          final initials = nameParts.length > 1
                                              ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                              : nameParts[0].substring(0, 2).toUpperCase();
                                              
                                          // Dynamic premium avatar colors
                                          final List<Color> colorsList = [
                                            const Color(0xFF3B82F6),
                                            const Color(0xFF10B981),
                                            const Color(0xFF8B5CF6),
                                            const Color(0xFFF59E0B),
                                            const Color(0xFFEF4444),
                                          ];
                                          final colorIndex = studName.hashCode % colorsList.length;
                                          final studColor = colorsList[colorIndex];
 
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.02),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () {
                                                  _showStudentDetailDialog(context, student);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  child: Row(
                                                    children: [
                                                      // Avatar circle
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: studColor.withOpacity(0.1),
                                                        child: Text(
                                                          initials,
                                                          style: TextStyle(
                                                            color: studColor,
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      
                                                      // Student name
                                                      Expanded(
                                                        child: Text(
                                                          studName,
                                                          style: const TextStyle(
                                                            color: Color(0xFF0F172A),
                                                            fontSize: 12.5,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showStudentDetailDialog(BuildContext context, Map<String, dynamic> student) {
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
                          final name = student['name'] ?? 'N A';
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
                      student['name'] ?? 'N/A',
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
                        student['class'] ?? 'N/A',
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
                      value: student['fatherName'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      label: 'Class Teacher',
                      value: student['classTeacher'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Email Address',
                      value: student['email'] ?? 'Not Available',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Parents Mobile',
                      value: student['mobile'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.percent_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Last Exam Score',
                      value: student['percentage'] ?? 'N/A',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.rocket_launch_rounded,
                      iconColor: const Color(0xFF8B5CF6), // Purple
                      label: 'Future Skill',
                      value: student['futureSkill'] ?? 'N/A',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.verified_rounded,
                      iconColor: const Color(0xFF10B981), // Green
                      label: 'Skills Attendance',
                      value: student['skillAttendance'] ?? 'N/A',
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
                  color: isHighlight ? const Color(0xFFD97706) : const Color(0xFF0F172A),
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

  void _showSchoolTeachersDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final searchQuery = searchController.text.trim();
            final allTeachers = _dataService.teachersNotifier.value;
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final List<Map<String, dynamic>> rawTeachers = allTeachers
                .where((t) =>
                    (t.schoolName?.toLowerCase() == schoolName) ||
                    (t.schoolId == schoolId && schoolId.isNotEmpty))
                .map((t) => {
                      'id': t.id,
                      'name': t.name,
                      'subject': t.subject,
                      'schoolName': t.schoolName,
                      'schoolId': t.schoolId,
                      'email': '${t.name.toLowerCase().replaceAll(' ', '')}@adyapan.com',
                      'mobile': '+91 98765 12345',
                    })
                .toList();
            
            final filteredTeachers = rawTeachers.where((t) {
              final name = (t['name'] ?? '').toString().toLowerCase();
              final subj = (t['subject'] ?? '').toString().toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query) || subj.contains(query);
            }).toList();
 
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8EEF9), // Soft ice grey-blue
                    Color(0xFFDCE3FA), // Premium pastel lavender-indigo
                    Color(0xFFEBF1FF), // Soft lavender white
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${school['name']} - Educators',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Principal: ${school['contact_person'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
                          onPressed: () {
                            Navigator.of(context).pop(); 
                            Navigator.of(context).pop(); 
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (val) {
                        setStateDialog(() {});
                      },
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search teachers by name or subject...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF475569), size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setStateDialog(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  
                  Flexible(
                    child: filteredTeachers.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF64748B),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Educators Found',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              final crossAxisCount = isMobile ? 1 : 2;
                              final childAspectRatio = isMobile ? 3.8 : 3.0;
 
                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shrinkWrap: true,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: filteredTeachers.length,
                                itemBuilder: (context, index) {
                                  final teacher = Map<String, dynamic>.from(filteredTeachers[index] as Map);
                                  final tName = teacher['name'] ?? 'N/A';
                                  final tSubject = teacher['subject'] ?? 'N/A';
                                  
                                  final nameParts = tName.split(' ');
                                  final initials = nameParts.length > 1
                                      ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                      : nameParts[0].substring(0, 2).toUpperCase();
                                      
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        )
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          _showTeacherDetailDialog(context, teacher);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: Color(0xFF6D28D9),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      tName,
                                                      style: const TextStyle(
                                                        color: Color(0xFF0F172A),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      tSubject,
                                                      style: const TextStyle(
                                                        color: Color(0xFF6D28D9),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Color(0xFF94A3B8),
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
 
  void _showTeacherDetailDialog(BuildContext context, Map<String, dynamic> teacher) {
    final classesList = teacher['classes'] as List<dynamic>? ?? [];
    
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
                          final name = teacher['name'] ?? 'N A';
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
                      teacher['name'] ?? 'N/A',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher['degree']?.toString() ?? MockDataService.getDegreeForSubject(teacher['subject']?.toString() ?? ''),
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
                        teacher['subject'] ?? 'N/A',
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
                      value: teacher['mobile'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Email Address',
                      value: teacher['email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.bookmark_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Subject Taught',
                      value: teacher['subject'] ?? 'N/A',
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

  @override
  Widget build(BuildContext context) {
    final isPrincipal = widget.role == 'Principal';
    final schoolData = widget.schoolData;

    return AnimatedBuilder(
      animation: Listenable.merge([_dataService.studentsNotifier, _dataService.teachersNotifier, _dataService.isLoadingNotifier]),
      builder: (context, _) {
        // Show loading indicator while fetching data
        if (_dataService.isLoading && _dataService.studentsNotifier.value.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4F46E5)),
                SizedBox(height: 16),
                Text('Loading data from database...', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              ],
            ),
          );
        }

        // For Principal: use their school's data. For Admin: use global data.
        final int totalStudents;
        final int totalTeachers;
        final double avgStudentAtt;
        final double avgTeacherAtt;
        final int totalDoubts;

        if (isPrincipal && schoolData != null) {
          // Principal: filter from loaded data by their school
          final allStudents = _dataService.studentsNotifier.value;
          final allTeachers = _dataService.teachersNotifier.value;
          final schoolName = schoolData['name']?.toString().toLowerCase() ?? '';
          final schoolId = schoolData['id']?.toString() ?? '';
          
          final schoolStudents = allStudents.where((s) => 
            (s.schoolName?.toLowerCase() == schoolName) || 
            (s.schoolId == schoolId && schoolId.isNotEmpty)
          ).toList();
          final schoolTeachers = allTeachers.where((t) =>
            (t.schoolName?.toLowerCase() == schoolName) ||
            (t.schoolId == schoolId && schoolId.isNotEmpty)
          ).toList();
          
          totalStudents = schoolStudents.length;
          totalTeachers = schoolTeachers.length;
          avgStudentAtt = _dataService.getAverageStudentAttendance();
          avgTeacherAtt = _dataService.getAverageTeacherAttendance();
          totalDoubts = _dataService.getTotalPendingDoubts();
        } else {
          totalStudents = _dataService.studentsNotifier.value.length;
          totalTeachers = _dataService.teachersNotifier.value.length;
          avgStudentAtt = _dataService.getAverageStudentAttendance();
          avgTeacherAtt = _dataService.getAverageTeacherAttendance();
          totalDoubts = _dataService.getTotalPendingDoubts();
        }

        return RefreshIndicator(
          color: const Color(0xFF4F46E5),
          backgroundColor: Colors.white,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner Block
                _buildWelcomeBanner(),
                const SizedBox(height: 28),

                // KPI Stats Grid (Responsive)
                _buildStatsGrid(totalStudents, totalTeachers, avgStudentAtt, avgTeacherAtt, totalDoubts),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B), // Indigo 950
            Color(0xFF312E81), // Indigo 900
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.amber, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Active Term: 2026 Academic Year',
                            style: TextStyle(
                              color: Color(0xFFC7D2FE),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.role == 'Admin'
                          ? 'Hello, ${widget.displayName ?? 'School Admin'}! 👋'
                          : 'Hello, ${widget.displayName ?? 'Respected Principal'}! 🎓',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitor school performance, view comprehensive student and educator indexes, and supervise ongoing doubts or roadmaps.',
                      style: TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: _showAnnouncementDialog,
                  icon: const Icon(Icons.campaign_rounded, size: 20),
                  label: const Text(
                    'Broadcast Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(int students, int teachers, double avgStudentAtt, double avgTeacherAtt, int doubts) {
    final isPrincipal = widget.role == 'Principal';
    final schoolData = widget.schoolData;
    final totalConnections = students + teachers + _principalsCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double aspectRatio = 0.95;
        if (constraints.maxWidth >= 1000) {
          crossAxisCount = 4;
          aspectRatio = 1.05;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
          aspectRatio = 0.95;
        } else {
          crossAxisCount = 2;
          aspectRatio = 0.82;
        }

        final adminCards = [
          // 1. Schools
          _buildStatCard(
            title: 'Schools',
            value: _schools.length.toString(),
            change: 'Active partner schools',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => _showSchoolsDialog(context),
          ),
          // 2. Students
          _buildStatCard(
            title: 'Students',
            value: students.toString(),
            change: 'Total enrolled students',
            icon: Icons.groups_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _showAllStudentsDialog(context),
          ),
          // 3. Teachers
          _buildStatCard(
            title: 'Teachers',
            value: teachers.toString(),
            change: 'Active educators',
            icon: Icons.co_present_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _showSchoolsDialog(context, isTeachersView: true),
          ),
          // 4. Principals
          _buildStatCard(
            title: 'Principals',
            value: _principalsCount.toString(),
            change: 'Across ${_schools.length} schools',
            icon: Icons.manage_accounts_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _showPrincipalsListDialog(context),
          ),
          // 5. Connections
          _buildStatCard(
            title: 'Connections',
            value: totalConnections.toString(),
            change: '${_schools.length} schools linked',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF06B6D4),
            onTap: () => _showConnectionsDialog(context),
          ),
          // 6. Revenue
          _buildStatCard(
            title: 'Revenue',
            value: '₹0',
            change: 'Total revenue collected',
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF059669),
            onTap: () => _showRevenueDialog(context),
          ),
          // 7. Certificate
          _buildStatCard(
            title: 'Certificate',
            value: '0',
            change: 'Certificates issued',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFFEC4899),
            onTap: () => _showCertificateDialog(context),
          ),
        ];

        final principalCards = [
          _buildStatCard(
            title: 'Students',
            value: students.toString(),
            change: '${schoolData?['name'] ?? 'Your school'}',
            icon: Icons.groups_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () {
              if (schoolData != null) {
                _showPrincipalStudentsDialog(context, schoolData);
              } else if (_schools.isNotEmpty) {
                _showPrincipalStudentsDialog(context, _schools.first);
              }
            },
          ),
          _buildStatCard(
            title: 'Teachers',
            value: teachers.toString(),
            change: '${schoolData?['name'] ?? 'Your school'}',
            icon: Icons.co_present_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () {
              if (schoolData != null) {
                _showPrincipalTeachersDialog(context, schoolData);
              } else if (_schools.isNotEmpty) {
                _showPrincipalTeachersDialog(context, _schools.first);
              }
            },
          ),
          _buildStatCard(
            title: 'Avg. Attendance',
            value: '${avgStudentAtt.toStringAsFixed(0)}% / ${avgTeacherAtt.toStringAsFixed(0)}%',
            change: 'Students / Educators',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              if (schoolData != null) {
                _showPrincipalAttendanceDialog(context, schoolData);
              } else if (_schools.isNotEmpty) {
                _showPrincipalAttendanceDialog(context, _schools.first);
              }
            },
          ),
          _buildStatCard(
            title: 'Pending Doubts',
            value: doubts.toString(),
            change: doubts > 0 ? 'Requires attention' : 'All cleared!',
            icon: Icons.help_outline_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () {
              if (schoolData != null) {
                _showPrincipalDoubtsDialog(context, schoolData);
              } else if (_schools.isNotEmpty) {
                _showPrincipalDoubtsDialog(context, _schools.first);
              }
            },
          ),
        ];

        final cards = isPrincipal ? principalCards : adminCards;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: cards,
        );
      },
    );
  }

  // ─── NEW DIALOG: Show all students (admin view) ──────────────────────────
  void _showAllStudentsDialog(BuildContext context) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final allStudents = _dataService.studentsNotifier.value;
            final filtered = allStudents.where((s) {
              final name = (s.name ?? '').toLowerCase();
              final school = (s.schoolName ?? '').toLowerCase();
              return name.contains(query) || school.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Students (${allStudents.length})',
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text('Enrolled across all schools', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or school...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                onPressed: () { searchController.clear(); setStateDialog(() {}); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline_rounded, color: Color(0xFF94A3B8), size: 48),
                                  SizedBox(height: 12),
                                  Text('No students found', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (ctx, c) {
                              final cols = c.maxWidth > 700 ? 2 : 1;
                              return GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cols == 1 ? 3.8 : 3.2,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final s = filtered[index];
                                  final name = s.name ?? 'N/A';
                                  final cls = s.gradeClass ?? 'N/A';
                                  final school = s.schoolName ?? 'N/A';
                                  final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                                  final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;

                                  return Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        final studentMap = {
                                          'id': s.id,
                                          'name': s.name,
                                          'class': s.gradeClass,
                                          'rollNo': s.rollNo,
                                          'attendance': s.attendancePercentage,
                                          'schoolName': s.schoolName,
                                          'schoolId': s.schoolId,
                                          'fatherName': 'Rajesh ${s.name.split(' ').last}',
                                          'classTeacher': 'S. K. Sharma',
                                          'email': '${s.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
                                          'mobile': '+91 98765 43210',
                                        };
                                        _showStudentDetailDialog(context, studentMap);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                              child: Text(safeInitials, style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                                  Text(cls, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w600)),
                                                  Text(school, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10), overflow: TextOverflow.ellipsis),
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
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── NEW DIALOG: Principals List ─────────────────────────────────────────
  void _showPrincipalsListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Principals (${_schools.length})',
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text('All registered school principals', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              Flexible(
                child: _schools.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.manage_accounts_rounded, color: Color(0xFF94A3B8), size: 48),
                              SizedBox(height: 12),
                              Text('No principals found', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _schools.length,
                        itemBuilder: (context, index) {
                          final school = _schools[index];
                          final principalName = school['contact_person'] ?? school['principal'] ?? 'Principal';
                          final schoolName = school['name'] ?? 'School';
                          final initials = principalName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                          final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
                                child: Text(safeInitials, style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              title: Text(principalName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('Principal — $schoolName', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                              onTap: () => _showConnectionsSchoolDetailDialog(context, school),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NEW DIALOG: Connections — Grid of School Boxes ──────────────────────
  void _showConnectionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connections (${_schools.length})',
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text('Tap a school to view its details', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              // Grid of school boxes
              Flexible(
                child: _schools.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_rounded, color: Color(0xFF475569), size: 48),
                              SizedBox(height: 12),
                              Text('No schools connected', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cols = constraints.maxWidth >= 600 ? 3 : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.05,
                            ),
                            itemCount: _schools.length,
                            itemBuilder: (context, index) {
                              final school = _schools[index];
                              final schoolName = school['name'] ?? 'School';
                              final principalName = school['contact_person'] ?? school['principal'] ?? 'N/A';
                              final initials = schoolName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                              final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;
                              final allStudents = _dataService.studentsNotifier.value;
                              final allTeachers = _dataService.teachersNotifier.value;
                              final schoolNameLower = schoolName.toLowerCase();
                              final schoolId = (school['id'] ?? '').toString();
                              final stCount = allStudents.where((s) =>
                                (s.schoolName?.toLowerCase() == schoolNameLower) ||
                                (s.schoolId == schoolId && schoolId.isNotEmpty)).length;
                              final tcCount = allTeachers.where((t) =>
                                (t.schoolName?.toLowerCase() == schoolNameLower) ||
                                (t.schoolId == schoolId && schoolId.isNotEmpty)).length;

                              return Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showConnectionsSchoolDetailDialog(context, school),
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
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                          child: Text(safeInitials, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          schoolName,
                                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          principalName,
                                          style: const TextStyle(color: Color(0xFF475569), fontSize: 10),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _miniChip('$tcCount T', const Color(0xFF8B5CF6)),
                                            const SizedBox(width: 6),
                                            _miniChip('$stCount S', const Color(0xFF10B981)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ─── NEW DIALOG: School detail from Connections (Principal heading + Teachers + Students with filter) ──
  void _showConnectionsSchoolDetailDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    String filter = 'All'; // 'All', 'Teachers', 'Students'

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final principalName = school['contact_person'] ?? school['principal'] ?? 'Principal';

            final allStudents = _dataService.studentsNotifier.value;
            final allTeachers = _dataService.teachersNotifier.value;

            final schoolStudents = allStudents.where((s) =>
              (s.schoolName?.toLowerCase() == schoolName) ||
              (s.schoolId == schoolId && schoolId.isNotEmpty)).toList();
            final schoolTeachers = allTeachers.where((t) =>
              (t.schoolName?.toLowerCase() == schoolName) ||
              (t.schoolId == schoolId && schoolId.isNotEmpty)).toList();

            // Build combined list based on filter
            final List<Map<String, dynamic>> items = [];
            if (filter == 'All' || filter == 'Teachers') {
              for (final t in schoolTeachers) {
                final name = t.name ?? '';
                if (query.isEmpty || name.toLowerCase().contains(query)) {
                  items.add({'type': 'teacher', 'name': name, 'subject': t.subject ?? '', 'data': t});
                }
              }
            }
            if (filter == 'All' || filter == 'Students') {
              for (final s in schoolStudents) {
                final name = s.name ?? '';
                if (query.isEmpty || name.toLowerCase().contains(query)) {
                  items.add({'type': 'student', 'name': name, 'class': s.gradeClass ?? '', 'data': s});
                }
              }
            }

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  // Header with Principal name
                  Container(
                    padding: const EdgeInsets.only(left: 16, right: 24, top: 20, bottom: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                school['name'] ?? 'School',
                                style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.manage_accounts_rounded, color: Color(0xFFFFD700), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      principalName,
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Principal • ${schoolTeachers.length} Teachers • ${schoolStudents.length} Students',
                                style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search bar + filter chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => setStateDialog(() {}),
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search teachers or students...',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                      onPressed: () { searchController.clear(); setStateDialog(() {}); },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _filterChip('All', filter, () => setStateDialog(() { filter = 'All'; })),
                        const SizedBox(width: 8),
                        _filterChip('Teachers', filter, () => setStateDialog(() { filter = 'Teachers'; })),
                        const SizedBox(width: 8),
                        _filterChip('Students', filter, () => setStateDialog(() { filter = 'Students'; })),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  // Content list
                  Flexible(
                    child: items.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 40),
                                  SizedBox(height: 12),
                                  Text('No results found', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, idx) {
                              final item = items[idx];
                              final isTeacher = item['type'] == 'teacher';
                              final name = item['name'] as String;
                              final subtitle = isTeacher ? (item['subject'] as String) : (item['class'] as String);
                              final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                              final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;
                              final avatarColor = isTeacher ? const Color(0xFF8B5CF6) : const Color(0xFF10B981);
                              final textColor = isTeacher ? const Color(0xFF6D28D9) : const Color(0xFF059669);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: avatarColor.withOpacity(0.12),
                                    child: Text(safeInitials, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                  title: Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Text(
                                    isTeacher ? 'Teacher • $subtitle' : 'Student • $subtitle',
                                    style: TextStyle(color: avatarColor.withOpacity(0.8), fontSize: 11),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: avatarColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: avatarColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      isTeacher ? 'Teacher' : 'Student',
                                      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(String label, String selected, VoidCallback onTap) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Revenue Dialog (Full screen Page) ────────────────────────────────────────
  void _showRevenueDialog(BuildContext context) {
    final searchController = TextEditingController();
    
    // Generate transactions dynamically based on schools list
    final List<Map<String, dynamic>> allTransactions = [];
    final double baseFee = 45000.0;
    
    for (int i = 0; i < _schools.length; i++) {
      final s = _schools[i];
      final schoolName = s['name'] ?? 'School Partner';
      final isPaid = i % 4 != 0; // 75% paid, 25% pending
      final amount = baseFee + (i * 5000) % 25000;
      
      allTransactions.add({
        'invoiceId': 'INV-2026-${1000 + i}',
        'schoolName': schoolName,
        'amount': amount,
        'status': isPaid ? 'Paid' : 'Pending',
        'date': 'June ${10 + (i * 2) % 18}, 2026',
        'category': i % 2 == 0 ? 'Platform Fee' : 'Content Licensing',
      });
    }

    // Default static entries if no schools connected
    if (allTransactions.isEmpty) {
      allTransactions.add({
        'invoiceId': 'INV-2026-1001',
        'schoolName': 'Aura Public School',
        'amount': 45000.0,
        'status': 'Paid',
        'date': 'June 12, 2026',
        'category': 'Platform Fee',
      });
      allTransactions.add({
        'invoiceId': 'INV-2026-1002',
        'schoolName': 'Apex International Academy',
        'amount': 55000.0,
        'status': 'Pending',
        'date': 'June 18, 2026',
        'category': 'Content Licensing',
      });
    }

    final double totalRevenue = allTransactions
        .where((t) => t['status'] == 'Paid')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    final int pendingCount = allTransactions.where((t) => t['status'] == 'Pending').length;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = allTransactions.where((t) {
              final name = t['schoolName'].toString().toLowerCase();
              final invId = t['invoiceId'].toString().toLowerCase();
              return name.contains(query) || invId.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Revenue & Billing Dashboard',
                                style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Track subscription invoices & collection history across ${_schools.length} partners',
                                style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),

                  // Summary Cards Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        return Flex(
                          direction: isNarrow ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Total Collected',
                                value: '₹${totalRevenue.toStringAsFixed(0)}',
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Pending Invoices',
                                value: '$pendingCount invoices',
                                icon: Icons.pending_rounded,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Billing Frequency',
                                value: 'Monthly Cycle',
                                icon: Icons.calendar_today_rounded,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by school or invoice ID...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                onPressed: () { searchController.clear(); setStateDialog(() {}); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                      ),
                    ),
                  ),

                  // Transaction List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded, color: Color(0xFF94A3B8), size: 48),
                                SizedBox(height: 12),
                                Text('No invoices match search', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final t = filtered[index];
                              final isPaid = t['status'] == 'Paid';
                              final amountStr = '₹${(t['amount'] as double).toStringAsFixed(0)}';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                                        child: Icon(
                                          isPaid ? Icons.arrow_upward_rounded : Icons.pending_actions_rounded,
                                          color: isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t['schoolName'],
                                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${t['invoiceId']}  •  ${t['category']}  •  ${t['date']}',
                                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            amountStr,
                                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t['status'].toUpperCase(),
                                              style: TextStyle(
                                                color: isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Certificate Dialog (Full screen Page) ────────────────────────────────────
  void _showCertificateDialog(BuildContext context) {
    final searchController = TextEditingController();
    
    // Generate mock certificates based on partner schools list
    final List<Map<String, dynamic>> allCertificates = [];
    
    for (int i = 0; i < _schools.length; i++) {
      final s = _schools[i];
      final schoolName = s['name'] ?? 'School Partner';
      
      allCertificates.add({
        'id': 'ADY-ACC-2026-${100 + i}',
        'title': 'School Accreditation Agreement',
        'recipient': schoolName,
        'type': 'School Accreditation',
        'date': 'Jan 12, 2026',
        'status': 'Active',
      });
    }

    // Add some student/teacher highlight certifications
    allCertificates.add({
      'id': 'ADY-CERT-2026-805',
      'title': 'Outstanding Educator Achievement',
      'recipient': 'Rahul (Educator)',
      'type': 'Teacher Certification',
      'date': 'May 28, 2026',
      'status': 'Active',
    });
    allCertificates.add({
      'id': 'ADY-CERT-2026-941',
      'title': 'High Achiever JavaScript Mastery',
      'recipient': 'Kapish Bagde (Student)',
      'type': 'Student Achievement',
      'date': 'June 05, 2026',
      'status': 'Active',
    });

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = allCertificates.where((c) {
              final title = c['title'].toString().toLowerCase();
              final recipient = c['recipient'].toString().toLowerCase();
              final id = c['id'].toString().toLowerCase();
              return title.contains(query) || recipient.contains(query) || id.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Certificates & Accreditations Registry',
                                style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Central repository of digital tie-up accreditations & accomplishment certificates (${allCertificates.length} total)',
                                style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),

                  // Summary Cards Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        return Flex(
                          direction: isNarrow ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Tie-up Accreditations',
                                value: '${_schools.length} Active',
                                icon: Icons.verified_user_rounded,
                                color: const Color(0xFFEC4899),
                              ),
                            ),
                            SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Personal Certificates',
                                value: '2 Issued',
                                icon: Icons.stars_rounded,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                            Expanded(
                              flex: isNarrow ? 0 : 1,
                              child: _buildSummaryItem(
                                title: 'Cryptographic Status',
                                value: 'Blockchain Verified',
                                icon: Icons.lock_outline_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by recipient, certificate name or ID...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                onPressed: () { searchController.clear(); setStateDialog(() {}); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                      ),
                    ),
                  ),

                  // Certificate Registry List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.card_membership_rounded, color: Color(0xFF94A3B8), size: 48),
                                SizedBox(height: 12),
                                Text('No certificates found', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final cert = filtered[index];
                              final id = cert['id'];
                              final title = cert['title'];
                              final recipient = cert['recipient'];
                              final date = cert['date'];
                              final type = cert['type'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFEC4899).withOpacity(0.12),
                                        child: const Icon(
                                          Icons.workspace_premium_rounded,
                                          color: Color(0xFFEC4899),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Recipient: $recipient  •  $id',
                                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Category: $type  •  Issued on: $date',
                                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFF10B981),
                                            size: 22,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'VERIFIED',
                                            style: TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Shows a read-only, clickable list of the principal's school students
  void _showPrincipalStudentsDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final globalStudents = _dataService.studentsNotifier.value;
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final List<Map<String, dynamic>> allStudents = globalStudents
                .where((s) =>
                    (s.schoolName?.toLowerCase() == schoolName) ||
                    (s.schoolId == schoolId && schoolId.isNotEmpty))
                .map((s) => {
                      'id': s.id,
                      'name': s.name,
                      'class': s.gradeClass,
                      'rollNo': s.rollNo,
                      'percentage': '${s.attendancePercentage.toStringAsFixed(1)}%',
                      'hasDoubt': s.homeworkDue > 0 || s.name.hashCode % 3 == 0,
                      'doubtQuestion': 'How to balance chemical equations?',
                      'classTeacher': 'S. K. Sharma',
                      'fatherName': 'Rajesh ${s.name.split(' ').last}',
                      'email': '${s.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
                      'mobile': '+91 98765 43210',
                      'futureSkill': 'AI & Prompt Engineering',
                      'skillAttendance': '90.5%',
                      'attendance': s.attendancePercentage,
                      'schoolName': s.schoolName,
                      'schoolId': s.schoolId,
                    })
                .toList();
            final filtered = allStudents.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              final cls = (s['class'] ?? '').toString().toLowerCase();
              return name.contains(query) || cls.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${school['name']} — Students',
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${allStudents.length} students enrolled • Tap a card to view details',
                                style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility_rounded, color: Color(0xFF059669), size: 12),
                              SizedBox(width: 4),
                              Text('View Only', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by student name or class (e.g. Class 10-A)...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                onPressed: () { searchController.clear(); setStateDialog(() {}); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                      ),
                    ),
                  ),
                  // Count
                  if (filtered.length != allStudents.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} result${filtered.length == 1 ? '' : 's'} found',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  // List
                  Flexible(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    query.isEmpty ? 'No students in this school' : 'No results for "$query"',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (ctx, c) {
                              final cols = c.maxWidth > 700 ? 2 : 1;
                              return GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cols == 1 ? 3.8 : 3.2,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final s = Map<String, dynamic>.from(filtered[index] as Map);
                                  final name = s['name'] ?? 'N/A';
                                  final cls = s['class'] ?? 'N/A';
                                  final percentage = s['percentage'] ?? '';
                                  final classTeacher = s['classTeacher'] ?? '';

                                  final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                                  final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;

                                  return Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showPrincipalStudentDetail(context, s),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                                              child: Text(safeInitials,
                                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(name,
                                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis),
                                                  Text(cls,
                                                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w600)),
                                                  if (classTeacher.isNotEmpty)
                                                    Text(classTeacher,
                                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                                        overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(percentage,
                                                      style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(height: 4),
                                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Student detail popup — view only
  void _showPrincipalStudentDetail(BuildContext context, Map<String, dynamic> s) {
    final name = s['name'] ?? 'N/A';
    final cls = s['class'] ?? 'N/A';
    final classTeacher = s['classTeacher'] ?? 'N/A';
    final father = s['fatherName'] ?? 'N/A';
    final email = s['email'] ?? 'N/A';
    final mobile = s['mobile'] ?? 'N/A';
    final percentage = s['percentage'] ?? 'N/A';
    final futureSkill = s['futureSkill'] ?? 'N/A';
    final skillAttendance = s['skillAttendance'] ?? 'N/A';

    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final safeInitials = initials.length > 2 ? initials.substring(0, 2) : initials;

    // Parse percentage for progress bar
    final pctValue = double.tryParse(percentage.replaceAll('%', '').trim()) ?? 0.0;
    final progress = (pctValue / 100.0).clamp(0.0, 1.0);

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
                : const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
              border: isMobile ? null : Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: isMobile
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('STUDENT PROFILE',
                            style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                      radius: 32,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(safeInitials,
                          style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(cls,
                          style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              // Details body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class Teacher
                    _buildStudentDetailRow(Icons.person_rounded, const Color(0xFF4F46E5), 'Class Teacher', classTeacher),
                    const SizedBox(height: 12),
                    // Father
                    _buildStudentDetailRow(Icons.family_restroom_rounded, const Color(0xFF0891B2), 'Father / Guardian', father),
                    const SizedBox(height: 12),
                    // Mobile
                    _buildStudentDetailRow(Icons.phone_android_rounded, const Color(0xFF10B981), 'Mobile Number', mobile),
                    const SizedBox(height: 12),
                    // Email
                    _buildStudentDetailRow(Icons.mail_outline_rounded, const Color(0xFFEF4444), 'Email Address', email),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    // Performance section
                    const Text('PERFORMANCE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    // Last Exam / Overall %
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatPill('Last Exam Score', percentage, const Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatPill('Skill Attendance', skillAttendance, const Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Performance', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(percentage, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pctValue >= 80 ? const Color(0xFF10B981) : pctValue >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                        ),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Future Skill
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFF7C3AED), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Future Skill Track', style: TextStyle(color: Color(0xFF6D28D9), fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(futureSkill, style: const TextStyle(color: Color(0xFF4C1D95), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
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
      },
    );
  }

  Widget _buildStudentDetailRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// Shows a read-only, clickable list of the principal's school teachers
  void _showPrincipalTeachersDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final globalTeachers = _dataService.teachersNotifier.value;
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final List<Map<String, dynamic>> allTeachers = globalTeachers
                .where((t) =>
                    (t.schoolName?.toLowerCase() == schoolName) ||
                    (t.schoolId == schoolId && schoolId.isNotEmpty))
                .map((t) => {
                      'id': t.id,
                      'name': t.name,
                      'subject': t.subject,
                      'schoolName': t.schoolName,
                      'schoolId': t.schoolId,
                      'email': '${t.name.toLowerCase().replaceAll(' ', '')}@adyapan.com',
                      'mobile': '+91 98765 12345',
                    })
                .toList();
            final filtered = allTeachers.where((t) {
              final name = (t['name'] ?? '').toString().toLowerCase();
              final subj = (t['subject'] ?? '').toString().toLowerCase();
              return name.contains(query) || subj.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8EEF9), Color(0xFFDCE3FA), Color(0xFFEBF1FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${school['name']} — Educators',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${allTeachers.length} educators • View Only',
                                style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility_rounded, color: Color(0xFF6D28D9), size: 12),
                              SizedBox(width: 4),
                              Text('View Only', style: TextStyle(color: Color(0xFF6D28D9), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search educators by name or subject...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Text('No educators found', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (ctx, c) {
                              final cols = c.maxWidth > 700 ? 2 : 1;
                              return GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cols == 1 ? 4.0 : 3.5,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final t = filtered[index] as Map<String, dynamic>;
                                  final name = t['name'] ?? 'N/A';
                                  final subject = t['subject'] ?? 'N/A';
                                  final classes = (t['classes'] as List<dynamic>? ?? []).join(', ');

                                  final nameParts = name.split(' ');
                                  final initials = nameParts.length > 1
                                      ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                      : name.substring(0, 2).toUpperCase();

                                  return Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showPrincipalTeacherDetail(context, Map<String, dynamic>.from(t as Map)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                              child: Text(initials,
                                                  style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(name,
                                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis),
                                                  Text(subject,
                                                      style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 11, fontWeight: FontWeight.w600)),
                                                  if (classes.isNotEmpty)
                                                    Text(classes,
                                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                                        overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Teacher detail popup — view only
  void _showPrincipalTeacherDetail(BuildContext context, Map<String, dynamic> t) {
    final name = t['name'] ?? 'N/A';
    final subject = t['subject'] ?? 'N/A';
    final email = t['email'] ?? 'N/A';
    final mobile = t['mobile'] ?? 'N/A';
    final classList = (t['classes'] as List<dynamic>? ?? []);

    final nameParts = name.split(' ');
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();

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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Purple header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EDUCATOR PROFILE',
                            style: TextStyle(color: Color(0xFF6D28D9), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                      radius: 32,
                      backgroundColor: const Color(0xFFEDE9FE),
                      child: Text(initials,
                          style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      t['degree']?.toString() ?? MockDataService.getDegreeForSubject(subject),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFF6D28D9), size: 12),
                          const SizedBox(width: 6),
                          Text(subject,
                              style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Details body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentDetailRow(Icons.phone_android_rounded, const Color(0xFF10B981), 'Mobile Number', mobile),
                    const SizedBox(height: 12),
                    _buildStudentDetailRow(Icons.mail_outline_rounded, const Color(0xFFEF4444), 'Email Address', email),
                    const SizedBox(height: 12),
                    _buildStudentDetailRow(Icons.menu_book_rounded, const Color(0xFF8B5CF6), 'Subject Taught', subject),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    const Text('CLASSES ASSIGNED',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    if (classList.isEmpty)
                      const Text('No classes assigned', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: classList.map((cls) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFDCE3FA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.class_rounded, color: Color(0xFF4F46E5), size: 12),
                                const SizedBox(width: 6),
                                Text(cls.toString(),
                                    style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    // View-only notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Color(0xFF7C3AED), size: 14),
                          SizedBox(width: 8),
                          Text('View only — no editing permissions',
                              style: TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
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
      },
    );
  }

  /// Shows a read-only, clickable list of pending doubts from students
  void _showPrincipalDoubtsDialog(BuildContext context, Map<String, dynamic> school) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = searchController.text.trim().toLowerCase();
            final globalStudents = _dataService.studentsNotifier.value;
            final schoolName = (school['name'] ?? '').toString().toLowerCase();
            final schoolId = (school['id'] ?? '').toString();
            final List<Map<String, dynamic>> allStudents = globalStudents
                .where((s) =>
                    (s.schoolName?.toLowerCase() == schoolName) ||
                    (s.schoolId == schoolId && schoolId.isNotEmpty))
                .map((s) => {
                      'id': s.id,
                      'name': s.name,
                      'class': s.gradeClass,
                      'rollNo': s.rollNo,
                      'percentage': '${s.attendancePercentage.toStringAsFixed(1)}%',
                      'hasDoubt': s.homeworkDue > 0 || s.name.hashCode % 3 == 0,
                      'doubtQuestion': 'How to balance chemical equations?',
                      'classTeacher': 'S. K. Sharma',
                      'fatherName': 'Rajesh ${s.name.split(' ').last}',
                      'email': '${s.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
                      'mobile': '+91 98765 43210',
                      'futureSkill': 'AI & Prompt Engineering',
                      'skillAttendance': '90.5%',
                      'attendance': s.attendancePercentage,
                      'schoolName': s.schoolName,
                      'schoolId': s.schoolId,
                    })
                .toList();
            final doubtsList = allStudents.where((s) => s['hasDoubt'] == true).toList();
            final filtered = doubtsList.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              final tName = (s['classTeacher'] ?? '').toString().toLowerCase();
              final q = (s['doubtQuestion'] ?? '').toString().toLowerCase();
              return name.contains(query) || tName.contains(query) || q.contains(query);
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFFE4E6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${school['name']} — Pending Doubts',
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${doubtsList.length} doubts requiring attention',
                                style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: (val) => setStateDialog(() {}),
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search by student, teacher, or question...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final d = filtered[index];
                        final name = d['name']?.toString() ?? 'Unknown Student';
                        final cls = d['class']?.toString() ?? '';
                        final teacher = d['classTeacher']?.toString() ?? 'Teacher';
                        final question = d['doubtQuestion']?.toString() ?? 'I have a doubt.';
                        final isSolved = d['isDoubtSolved'] == true;
                        final initials = name.isNotEmpty ? name.substring(0, 1) : '?';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: isSolved ? const Color(0xFF10B981).withOpacity(0.05) : const Color(0xFFF97316).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSolved ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
                                  child: Text(initials, style: TextStyle(color: isSolved ? const Color(0xFF059669) : const Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question,
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 10),
                                                const SizedBox(width: 4),
                                                Text('$name ($cls)', style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.menu_book_rounded, color: Color(0xFF16A34A), size: 10),
                                                const SizedBox(width: 4),
                                                Text('Assigned to: $teacher', style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSolved ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
                                              borderRadius: BorderRadius.circular(6)
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(isSolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isSolved ? const Color(0xFF059669) : const Color(0xFFEA580C), size: 10),
                                                const SizedBox(width: 4),
                                                Text(isSolved ? 'Solved' : 'Unsolved', style: TextStyle(color: isSolved ? const Color(0xFF059669) : const Color(0xFFEA580C), fontSize: 10, fontWeight: FontWeight.w600)),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Shows a read-only, clickable list of student and teacher attendance
  void _showPrincipalAttendanceDialog(BuildContext context, Map<String, dynamic> school) {
    final globalStudents = _dataService.studentsNotifier.value;
    final schoolName = (school['name'] ?? '').toString().toLowerCase();
    final schoolId = (school['id'] ?? '').toString();
    final List<Map<String, dynamic>> allStudents = globalStudents
        .where((s) =>
            (s.schoolName?.toLowerCase() == schoolName) ||
            (s.schoolId == schoolId && schoolId.isNotEmpty))
        .map((s) => {
              'id': s.id,
              'name': s.name,
              'class': s.gradeClass,
              'rollNo': s.rollNo,
              'percentage': '${s.attendancePercentage.toStringAsFixed(1)}%',
              'hasDoubt': s.homeworkDue > 0 || s.name.hashCode % 3 == 0,
              'doubtQuestion': 'How to balance chemical equations?',
              'classTeacher': 'S. K. Sharma',
              'fatherName': 'Rajesh ${s.name.split(' ').last}',
              'email': '${s.name.toLowerCase().replaceAll(' ', '')}@gmail.com',
              'mobile': '+91 98765 43210',
              'futureSkill': 'AI & Prompt Engineering',
              'skillAttendance': '90.5%',
              'attendance': s.attendancePercentage,
              'schoolName': s.schoolName,
              'schoolId': s.schoolId,
            })
        .toList();
    final avgStudentAtt = school['studentAttendance']?.toDouble() ?? 88.5;
    final avgTeacherAtt = school['teacherAttendance']?.toDouble() ?? 92.0;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${school['name']} — Attendance Register',
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Students: ${avgStudentAtt.toStringAsFixed(1)}%  •  Educators: ${avgTeacherAtt.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: allStudents.length,
                  itemBuilder: (context, index) {
                    final s = allStudents[index];
                    final name = s['name']?.toString() ?? 'Unknown Student';
                    final cls = s['class']?.toString() ?? '';
                    final percentageStr = s['percentage']?.toString().replaceAll('%', '') ?? '0';
                    final percentage = double.tryParse(percentageStr) ?? 0.0;
                    
                    final bool isLow = percentage < 75.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
                          child: Icon(Icons.person_rounded, color: isLow ? const Color(0xFFEF4444) : const Color(0xFF16A34A), size: 20),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(cls, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLow ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isLow ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            '$percentageStr%',
                            style: TextStyle(
                              color: isLow ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _glowingCardDecoration({
    required Color accentColor,
    double glowOpacity = 0.14,
  }) {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: accentColor.withOpacity(0.18), width: 1.5),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(glowOpacity),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.5),
          offset: const Offset(-2, -2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: _glowingCardDecoration(accentColor: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (onTap != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_outward_rounded, color: Color(0xFF94A3B8), size: 14),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color == const Color(0xFF10B981) ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color == const Color(0xFF10B981) ? const Color(0xFF059669) : const Color(0xFF475569),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return cardContent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: cardContent,
      ),
    );
  }

  Widget _buildAcademicCharts(double studAtt, double teachAtt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Ratios & Trends',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Weekly Attendance Logs vs Term Milestones',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Custom Attendance Wave Line Chart Canvas
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _AcademicChartPainter(
                studentAttendance: studAtt,
                teacherAttendance: teachAtt,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chart Legends (Wrap-based for responsive viewports)
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendChip(label: 'Students Attendance ($studAtt%)', color: const Color(0xFF3B82F6)),
              _buildLegendChip(label: 'Teachers Attendance ($teachAtt%)', color: const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AcademicChartPainter extends CustomPainter {
  final double studentAttendance;
  final double teacherAttendance;

  _AcademicChartPainter({
    required this.studentAttendance,
    required this.teacherAttendance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    // Draw Grid Lines (Horizontal)
    final gridCount = 4;
    final rowHeight = size.height / gridCount;
    for (int i = 0; i <= gridCount; i++) {
      final y = rowHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Attendance data interpolation (represented in X and Y points)
    // Using simple points representing Monday to Friday attendance progress
    final days = 5;
    final colWidth = size.width / (days - 1);

    // Mock ratios mapped dynamically based on actual attendance values
    final studAttFactors = [0.91, 0.93, 0.94, studentAttendance / 100.0, studentAttendance / 100.0];
    final teachAttFactors = [0.93, 0.92, 0.95, teacherAttendance / 100.0, teacherAttendance / 100.0];

    // DRAW STUDENT LINE (Blue Wave)
    final paintStudentLine = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathStudent = Path();
    for (int i = 0; i < days; i++) {
      // Map attendance factor (0.0 to 1.0) into chart Y-axis (invert since Y is down)
      // Cap at 0.5 to 1.0 range visually to keep waves elegant
      final attVal = studAttFactors[i];
      final y = size.height - ((attVal - 0.5) / 0.5) * size.height;
      final x = i * colWidth;

      if (i == 0) {
        pathStudent.moveTo(x, y);
      } else {
        // Curve to point
        final prevX = (i - 1) * colWidth;
        final prevAttVal = studAttFactors[i - 1];
        final prevY = size.height - ((prevAttVal - 0.5) / 0.5) * size.height;
        pathStudent.cubicTo(
          prevX + colWidth / 2, prevY,
          x - colWidth / 2, y,
          x, y,
        );
      }
    }
    canvas.drawPath(pathStudent, paintStudentLine);

    // DRAW TEACHER LINE (Purple Wave)
    final paintTeacherLine = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathTeacher = Path();
    for (int i = 0; i < days; i++) {
      final attVal = teachAttFactors[i];
      final y = size.height - ((attVal - 0.5) / 0.5) * size.height;
      final x = i * colWidth;

      if (i == 0) {
        pathTeacher.moveTo(x, y);
      } else {
        final prevX = (i - 1) * colWidth;
        final prevAttVal = teachAttFactors[i - 1];
        final prevY = size.height - ((prevAttVal - 0.5) / 0.5) * size.height;
        pathTeacher.cubicTo(
          prevX + colWidth / 2, prevY,
          x - colWidth / 2, y,
          x, y,
        );
      }
    }
    canvas.drawPath(pathTeacher, paintTeacherLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
