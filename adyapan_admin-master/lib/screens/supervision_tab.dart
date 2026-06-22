import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';

class SupervisionTab extends StatefulWidget {
  final String role;
  const SupervisionTab({super.key, required this.role});

  @override
  State<SupervisionTab> createState() => _SupervisionTabState();
}

class _SupervisionTabState extends State<SupervisionTab> {
  final _mockService = MockDataService.instance;
  String _activeSubjectPath = 'Mathematics'; // 'Mathematics', 'Science', 'History'

  // Mock Roadmap levels
  final Map<String, List<Map<String, dynamic>>> _roadmaps = {
    'Mathematics': [
      {'level': '1', 'title': 'Number Systems', 'status': 'completed'},
      {'level': '2', 'title': 'Polynomials', 'status': 'completed'},
      {'level': '3', 'title': 'Linear Equations', 'status': 'completed'},
      {'level': '4', 'title': 'Quadratic Form', 'status': 'completed'},
      {'level': '5', 'title': 'Coordinate Geometry', 'status': 'active'},
      {'level': '6', 'title': 'Trigonometry Intro', 'status': 'locked'},
      {'level': '7', 'title': 'Circles & Theorems', 'status': 'locked'},
      {'level': '8', 'title': 'Statistics & Odds', 'status': 'locked'},
    ],
    'Science': [
      {'level': '1', 'title': 'Chemical Reactions', 'status': 'completed'},
      {'level': '2', 'title': 'Acids, Bases & Salts', 'status': 'completed'},
      {'level': '3', 'title': 'Metals & Non-Metals', 'status': 'completed'},
      {'level': '4', 'title': 'Carbon Chemistry', 'status': 'completed'},
      {'level': '5', 'title': 'Life Processes', 'status': 'completed'},
      {'level': '6', 'title': 'Control & Sync', 'status': 'active'},
      {'level': '7', 'title': 'Light Reflection', 'status': 'locked'},
      {'level': '8', 'title': 'Electricity Master', 'status': 'locked'},
    ],
    'History': [
      {'level': '1', 'title': 'Rise of Nationalism', 'status': 'completed'},
      {'level': '2', 'title': 'Nationalism in India', 'status': 'completed'},
      {'level': '3', 'title': 'Global World Making', 'status': 'completed'},
      {'level': '4', 'title': 'Age of Industrialisation', 'status': 'active'},
      {'level': '5', 'title': 'Print Culture', 'status': 'locked'},
      {'level': '6', 'title': 'Resource Planning', 'status': 'locked'},
      {'level': '7', 'title': 'Forest & Wildlife', 'status': 'locked'},
      {'level': '8', 'title': 'Water Resources', 'status': 'locked'},
    ]
  };

  void _handleJoinRoom(String roomName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Principal credentials approved. Connecting to live doubt room: "$roomName"...'),
        backgroundColor: const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final double paddingVal = isMobile ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(paddingVal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supervision Description card
          _buildInfoBanner(),
          SizedBox(height: isMobile ? 20 : 28),

          // Double panel layout: Live Roster on Left, Syllabus timeline on Right
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: _buildLiveRoomsFeed(screenWidth, isMobile)),
                    const SizedBox(width: 24),
                    Expanded(flex: 10, child: _buildRoadmapsViewer(screenWidth, isMobile)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildLiveRoomsFeed(screenWidth, isMobile),
                    SizedBox(height: isMobile ? 20 : 28),
                    _buildRoadmapsViewer(screenWidth, isMobile),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
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
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supervision Dashboard 💻',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Access real-time student updates, roadmaps, and ongoing classroom sessions below.',
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

  Widget _buildLiveRoomsFeed(double screenWidth, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Live Classes & Doubts",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time lecture and tutoring portal supervision',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ListView for classrooms (No bounded height, uses natural wrap)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockService.liveClasses.length,
            itemBuilder: (context, index) {
              final room = _mockService.liveClasses[index];
              final isLive = room['isLive'] as bool;
              final isCardNarrow = screenWidth < 520;

              if (isCardNarrow) {
                // Fully responsive Column-based card layout for narrow mobile screens
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Icon status
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLive ? const Color(0xFF4F46E5).withOpacity(0.1) : const Color(0xFF94A3B8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isLive ? Icons.videocam_rounded : Icons.videocam_outlined,
                              color: isLive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Information Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room['subject'] as String,
                                        style: TextStyle(
                                          color: isLive ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isLive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${room['class']} • ${room['teacher']}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${room['time']} (${room['status']})',
                                        style: TextStyle(
                                          color: isLive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleJoinRoom(room['subject'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLive ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isLive ? 'Connect to Live Classroom' : 'Join Classroom',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Standard horizontal Row layout for tablet and desktop
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // Class Icon status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLive ? const Color(0xFF4F46E5).withOpacity(0.1) : const Color(0xFF94A3B8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLive ? Icons.videocam_rounded : Icons.videocam_outlined,
                        color: isLive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Information Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Explicitly constrained title text
                              Expanded(
                                child: Text(
                                  room['subject'] as String,
                                  style: TextStyle(
                                    color: isLive ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isLive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${room['class']} • Educator: ${room['teacher']}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${room['time']} (${room['status']})',
                                  style: TextStyle(
                                    color: isLive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
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

                    // Connect button
                    ElevatedButton(
                      onPressed: () => _handleJoinRoom(room['subject'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLive ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isLive ? 'Connect' : 'Join',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildRoadmapsViewer(double screenWidth, bool isMobile) {
    final activeLevels = _roadmaps[_activeSubjectPath]!;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      'Syllabus Pathways',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Interactive Roadmaps (Levels 1-8)',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Subject selectors
              DropdownButton<String>(
                value: _activeSubjectPath,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                underline: const SizedBox(),
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _activeSubjectPath = val;
                    });
                  }
                },
                items: ['Mathematics', 'Science', 'History'].map((subj) {
                  return DropdownMenuItem(value: subj, child: Text(subj));
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Custom Timeline Timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeLevels.length,
            itemBuilder: (context, index) {
              final lvl = activeLevels[index];
              final status = lvl['status'] as String;

              Color accentColor = Colors.grey;
              IconData nodeIcon = Icons.lock_outline_rounded;
              if (status == 'completed') {
                accentColor = const Color(0xFF10B981); // Emerald
                nodeIcon = Icons.check_circle_rounded;
              } else if (status == 'active') {
                accentColor = const Color(0xFF3B82F6); // Blue
                nodeIcon = Icons.stars_rounded;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node Line & Circle
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2),
                        ),
                        child: Icon(nodeIcon, color: accentColor, size: 16),
                      ),
                      if (index != activeLevels.length - 1)
                        Container(
                          width: 2,
                          height: 48,
                          color: status == 'completed'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Node content card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Level ${lvl['level']}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lvl['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
