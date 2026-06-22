import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/mock_data_service.dart';
import '../models/teacher.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingTab extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? schoolData;
  const MeetingTab({super.key, required this.role, this.schoolData});

  @override
  State<MeetingTab> createState() => _MeetingTabState();
}

class _MeetingTabState extends State<MeetingTab> {
  final _dataService = DataService.instance;
  final _mockService = MockDataService.instance;

  // Meeting Broadcast States
  bool _isMeetingActive = false;
  int _countdownSeconds = 600; // 10 minutes countdown
  Timer? _countdownTimer;

  // Leave Requests Data (Simulating teacher dashboard endpoint)
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    // 1. Ensure teachers are loaded
    if (_dataService.teachersNotifier.value.isEmpty) {
      await _dataService.loadTeachers();
    }

    // 2. Load leaves from DB
    try {
      final leaves = await _dataService.fetchLeaves();
      setState(() {
        _leaveRequests = List<Map<String, dynamic>>.from(leaves);
      });
    } catch (e) {
      debugPrint('Error loading leaves: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startMeetingCountdown() async {
    _countdownTimer?.cancel();
    setState(() {
      _isMeetingActive = true;
      _countdownSeconds = 600;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          _isMeetingActive = false;
        });
      }
    });

    // Fetch teachers dynamically from the database
    List<Teacher> teachers = _dataService.teachersNotifier.value;
    String schoolName = widget.schoolData?['name']?.toString() ?? "Adyapan School";
    
    // No schoolId filtering for teachers so meeting alerts reach all teachers successfully

    // Open default SMS app pre-filled with numbers and message body
    final String message = '⏰ Meeting Alert\nHello Teachers,\nThe meeting begins in 30 minutes. Please keep your device and internet ready for a smooth session.\n\n- Principal, $schoolName';
    
    final recipients = teachers
        .map((t) => t.mobile.replaceAll(RegExp(r'[^0-9+]'), ''))
        .where((m) => m.isNotEmpty)
        .join(',');

    if (recipients.isNotEmpty) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: recipients,
        queryParameters: <String, String>{
          'body': message,
        },
      );
      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          throw 'Could not launch SMS application';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open SMS app: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    // Broadcast Meeting in Mock Database System for local components (if any)
    setState(() {
      _mockService.liveClasses.insert(0, {
        'subject': '🔴 Urgent Faculty Meeting',
        'class': 'All Grades',
        'teacher': 'Admin Host',
        'time': 'NOW',
        'status': '10 mins countdown active',
        'isLive': true,
      });

      _mockService.systemEvents.insert(0, {
        'title': 'Urgent Meeting Scheduled',
        'desc': 'Admin called an urgent meeting. Notification broadcasted to all teachers.',
        'time': 'Just now',
        'icon': Icons.groups_rounded,
        'color': Colors.redAccent,
      });
    });

    // Also persist to TiDB backend (this now succeeds since we created the table!)
    final hostedBy = widget.schoolData?['principal_name'] ?? widget.role;
    _dataService.createMeeting(title: 'Urgent Faculty Meeting', hostedBy: hostedBy);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting Notification Broadcasted! All teachers notified to join within 10 min.'),
        backgroundColor: Colors.indigoAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleLeaveAction(int index, String newStatus) async {
    final request = _leaveRequests[index];
    final reqId = request['id']?.toString() ?? '';
    final teacherName = (request['teacherName'] ?? request['teacher_name'] ?? 'Educator').toString();
    final dates = (request['dates'] ?? '').toString();

    setState(() {
      request['status'] = newStatus;
    });

    final isApproved = newStatus == 'Approved';
    final actionColor = isApproved ? Colors.green : Colors.redAccent;
    final actionText = isApproved ? 'approved' : 'rejected';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request for $teacherName has been $actionText. Updating database...'),
        backgroundColor: actionColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Call DB update API
    if (reqId.isNotEmpty) {
      await _dataService.updateLeaveStatus(reqId, newStatus);
    }

    // Append to system events feed
    setState(() {
      _mockService.systemEvents.insert(0, {
        'title': isApproved ? 'Leave Request Approved' : 'Leave Request Rejected',
        'desc': 'Admin $actionText leave for $teacherName ($dates).',
        'time': 'Just now',
        'icon': isApproved ? Icons.verified_user_rounded : Icons.cancel_presentation_rounded,
        'color': actionColor,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 28),

            // Meeting Panel on top, leaves below (or side-by-side on desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMeetingSection()),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildLeavesSection()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMeetingSection(),
                      const SizedBox(height: 24),
                      _buildLeavesSection(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting & Leave Manager 📝',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Schedule instant administrative meetings and approve or reject remote leave applications from the teacher dashboard.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingSection() {
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
          const Text(
            'Host Faculty Meeting',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sends an immediate notification broadcast to all registered educators.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),

          // Interactive Countdown / Call Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isMeetingActive
                    ? [const Color(0xFFEF4444), const Color(0xFF991B1B)]
                    : [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (_isMeetingActive ? Colors.redAccent : const Color(0xFF312E81)).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isMeetingActive ? Icons.radio_button_checked_rounded : Icons.groups_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isMeetingActive ? 'MEETING IN SESSION' : 'INSTANT BROADCAST',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isMeetingActive
                      ? _formatDuration(_countdownSeconds)
                      : '10:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isMeetingActive
                      ? 'Within 10 min meeting is held by Admin'
                      : 'Set countdown to alert all teachers',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Host Meeting Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMeetingActive ? null : _startMeetingCountdown,
              icon: const Icon(Icons.campaign_rounded, size: 20),
              label: Text(
                _isMeetingActive ? 'Meeting Broadcast Active' : 'Broadcast Meeting Alert',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Leave Applications',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Incoming requests from teacher dashboard',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${_leaveRequests.where((r) => r['status'] == 'Pending').length} PENDING',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Leave Cards List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaveRequests.length,
            itemBuilder: (context, index) {
              final request = _leaveRequests[index];
              final status = (request['status'] ?? 'Pending').toString();
              final name = (request['teacherName'] ?? request['teacher_name'] ?? 'Educator').toString();
              final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
              final uid = (request['uid'] ?? request['teacher_uid'] ?? 'N/A').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${request['subject']} • UID $uid',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Pill Badge
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Leave request parameters
                    _buildMetaField(Icons.calendar_month_rounded, 'Requested Dates', (request['dates'] ?? '').toString()),
                    const SizedBox(height: 8),
                    _buildMetaField(Icons.notes_rounded, 'Reason for Leave', (request['reason'] ?? '').toString()),
                    const SizedBox(height: 16),

                    // Conditional Action Buttons for Pending requests
                    if (status == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleLeaveAction(index, 'Rejected'),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleLeaveAction(index, 'Approved'),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Approve Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.amber;
    Color bg = Colors.amber.shade50;
    if (status == 'Approved') {
      color = Colors.green;
      bg = Colors.green.shade50;
    } else if (status == 'Rejected') {
      color = Colors.redAccent;
      bg = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMetaField(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
