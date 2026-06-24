import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'overview_tab.dart';
import 'teachers_tab.dart';
import 'students_tab.dart';
import 'supervision_tab.dart';
import 'meeting_tab.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class MainLayout extends StatefulWidget {
  final String role;
  final String displayName;
  final String email;
  /// For principals: the school map they are assigned to (from MockDataService).
  /// Null for Admin.
  final Map<String, dynamic>? schoolData;

  const MainLayout({
    super.key,
    required this.role,
    required this.displayName,
    required this.email,
    this.schoolData,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final List<Widget> _tabs;
  late final List<Map<String, dynamic>> _navigationItems;

  List<Map<String, dynamic>> _adminMessages = [];
  Set<String> _readMessageIds = {};
  Timer? _messageTimer;
  List<Map<String, dynamic>> _principalReplies = [];

  Future<void> _loadReadMessageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('read_admin_message_ids') ?? [];
      if (mounted) {
        setState(() {
          _readMessageIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    if (widget.role != 'Principal' && widget.role != 'Teacher') return;
    final schoolId = widget.schoolData?['id']?.toString();
    if (schoolId == null) return;
    try {
      final messages = await ApiService.instance.fetchAdminMessages(schoolId: schoolId);
      if (mounted) {
        setState(() {
          _adminMessages = messages;
        });
      }
    } catch (e) {
      print('Error fetching admin messages: $e');
    }
  }

  Future<void> _fetchReplies() async {
    if (widget.role != 'Admin') return;
    try {
      final replies = await ApiService.instance.fetchPrincipalReplies();
      if (mounted) {
        setState(() {
          _principalReplies = replies;
        });
      }
    } catch (e) {
      print('Error fetching principal replies: $e');
    }
  }

  Future<void> _markAllMessagesAsRead() async {
    final unreadMessages = _adminMessages
        .where((m) => !_readMessageIds.contains(m['id']?.toString() ?? ''))
        .toList();
    final newIds = unreadMessages
        .map((m) => m['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (newIds.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _readMessageIds.addAll(newIds);
      await prefs.setStringList('read_admin_message_ids', _readMessageIds.toList());
      if (mounted) setState(() {});
      // Also mark as read on the server (fire-and-forget)
      for (final id in newIds) {
        ApiService.instance.markAdminMessageRead(id);
      }
    } catch (_) {}
  }

  void _showNotificationInbox(BuildContext context) {
    _markAllMessagesAsRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, color: Color(0xFF3B82F6), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Notifications Inbox',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                              tooltip: 'Clear All Messages',
                              onPressed: () => _confirmClearAllMessages(context, setModalState),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Messages List
                  Expanded(
                    child: _adminMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🔔', style: TextStyle(fontSize: 28)),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'All caught up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'No new admin messages.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _adminMessages.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final msg = _adminMessages[index];
                              final msgId = msg['id']?.toString() ?? '';
                              final titleText = msg['title']?.toString() ?? '📢 Admin Message';
                              final messageText = msg['message']?.toString() ?? msg['body']?.toString() ?? '';
                              final dateStr = msg['sentAt']?.toString() ?? msg['created_at']?.toString() ?? msg['sent_at']?.toString() ?? '';
                              final isUnread = !_readMessageIds.contains(msgId);

                              String formattedTime = '';
                              if (dateStr.isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(dateStr).toLocal();
                                  formattedTime = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                } catch (_) {
                                  formattedTime = dateStr;
                                }
                              }

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isUnread ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUnread ? const Color(0xFF6366F1).withOpacity(0.4) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            titleText,
                                            style: TextStyle(
                                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                                              fontSize: 13.5,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(left: 4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF3B82F6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      messageText,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF334155),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (formattedTime.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedTime,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (widget.role == 'Principal' || widget.role == 'Teacher')
                                          InkWell(
                                            onTap: () => _showReplyDialog(
                                              context,
                                              parentMessageId: msgId,
                                              parentMessageText: messageText,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.reply_rounded,
                                                    size: 14,
                                                    color: const Color(0xFF4F46E5),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: Color(0xFF4F46E5),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Principal sends a reply message back to the admin.
  void _showReplyDialog(
    BuildContext parentContext, {
    String? parentMessageId,
    String? parentMessageText,
  }) {
    final replyController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.reply_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reply to Admin', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                              Text(
                                widget.role == 'Teacher'
                                    ? 'Your message will be sent to the Adyapan Admin'
                                    : 'Your message will be sent to the Adyapan Admin',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parentMessageText != null && parentMessageText.isNotEmpty) ...[
                          const Text(
                            'Replying to:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                left: BorderSide(color: Color(0xFF64748B), width: 3),
                              ),
                            ),
                            child: Text(
                              parentMessageText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        const Text(
                          'Your Message',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: replyController,
                          maxLines: 5,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type your message to the admin...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
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
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    final msg = replyController.text.trim();
                                    if (msg.isEmpty) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('Please type a message.'), backgroundColor: Colors.orange),
                                      );
                                      return;
                                    }
                                    setDialogState(() => isSending = true);
                                    try {
                                      await ApiService.instance.sendPrincipalReply(
                                        msg,
                                        parentMessageId: parentMessageId,
                                        parentMessageText: parentMessageText,
                                      );
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      if (parentContext.mounted) {
                                        ScaffoldMessenger.of(parentContext).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Reply sent to admin!'),
                                            backgroundColor: Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSending = false);
                                      if (parentContext.mounted) {
                                        ScaffoldMessenger.of(parentContext).showSnackBar(
                                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 16),
                                      SizedBox(width: 6),
                                      Text('Send Reply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                          ),
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
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabs = [
      OverviewTab(
        role: widget.role,
        schoolData: widget.schoolData,
        displayName: widget.displayName,
      ),
      TeachersTab(role: widget.role, schoolData: widget.schoolData),
      StudentsTab(role: widget.role, schoolData: widget.schoolData),
      SupervisionTab(role: widget.role),
    ];

    // Footer navigation items (Supervision moved to drawer for Admin)
    if (widget.role == 'Admin') {
      _navigationItems = [
        {'title': 'Overview', 'icon': Icons.dashboard_rounded},
        {'title': 'Teachers Directory', 'icon': Icons.co_present_rounded},
        {'title': 'Students Directory', 'icon': Icons.school_rounded},
        // Index 3 = Messages (special button, not a tab)
      ];
    } else {
      _navigationItems = [
        {'title': 'Overview', 'icon': Icons.dashboard_rounded},
        {'title': 'Teachers Directory', 'icon': Icons.co_present_rounded},
        {'title': 'Students Directory', 'icon': Icons.school_rounded},
        {'title': 'Supervision Panel', 'icon': Icons.analytics_rounded},
      ];
    }

    if (widget.role == 'Admin' || widget.role == 'Principal') {
      _tabs.add(MeetingTab(role: widget.role, schoolData: widget.schoolData));
      _navigationItems.add({
        'title': 'Take Meeting',
        'icon': Icons.groups_rounded,
      });
    }

    _loadReadMessageIds();
    if (widget.role == 'Principal' || widget.role == 'Teacher') {
      _fetchMessages();
      _messageTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages());
      // Wire up notification tap → open inbox automatically
      NotificationService.instance.onNotificationTap = () {
        if (mounted) {
          _fetchMessages().then((_) {
            if (mounted) _showNotificationInbox(context);
          });
        }
      };
      // Register FCM for principal and teacher
      NotificationService.instance.registerToken();
    } else if (widget.role == 'Admin') {
      _fetchReplies();
      _messageTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchReplies());
      // Wire up notification tap for admin → open replies inbox
      NotificationService.instance.onNotificationTap = () {
        if (mounted) {
          _fetchReplies().then((_) {
            if (mounted) _showAdminRepliesInbox(context);
          });
        }
      };
      // Register FCM for admin so they get push on replies
      NotificationService.instance.registerToken();
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    // Clear notification tap callback to avoid calling into a disposed widget
    if (widget.role == 'Principal' || widget.role == 'Teacher' || widget.role == 'Admin') {
      NotificationService.instance.onNotificationTap = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Sign Out', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to end your dashboard session?',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete session using shared preferences
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
              } catch (_) {}

              if (!context.mounted) return;
              Navigator.of(context).pop(); // dismiss dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ── ADMIN MESSAGING SYSTEM ──────────────────────────────────────────────────

  Future<void> _confirmClearAllMessages(BuildContext context, StateSetter setModalState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Clear All Messages', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all recent messages and replies from the database? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.instance.clearAllMessages();
        setModalState(() {
          _adminMessages.clear();
          _principalReplies.clear();
        });
        setState(() {
          _adminMessages = [];
          _principalReplies = [];
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All messages and replies cleared successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing messages: $e')),
          );
        }
      }
    }
  }

  /// Shows admin the inbox of all replies received from principals.
  void _showAdminRepliesInbox(BuildContext context) {
    _fetchReplies(); // refresh on open
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF4F46E5), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Principal Replies',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                            tooltip: 'Clear All Messages',
                            onPressed: () => _confirmClearAllMessages(ctx, setModalState),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _principalReplies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                alignment: Alignment.center,
                                child: const Text('💬', style: TextStyle(fontSize: 28)),
                              ),
                              const SizedBox(height: 16),
                              const Text('No replies yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              const Text('Replies from principals will appear here.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _principalReplies.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reply = _principalReplies[index];
                            final messageText = reply['message']?.toString() ?? '';
                            final fromEmail = reply['from_email']?.toString() ?? '';
                            final dateStr = reply['sentAt']?.toString() ?? reply['created_at']?.toString() ?? reply['sent_at']?.toString() ?? '';
                            final parentMsgText = reply['parent_message_text']?.toString();

                            // sender_name contains the full label:
                            // "Niranjan – Principal (ABC School)" or "Ramesh – Teacher (XYZ School)"
                            final rawSenderName = (reply['sender_name']?.toString() ?? '').trim();

                            String displayName = rawSenderName;
                            String schoolName = '';
                            String roleName = rawSenderName.toLowerCase().contains('teacher') ? 'Teacher' : 'Principal';

                            // Parse "Name – Role (School)" format
                            if (rawSenderName.contains('(') && rawSenderName.contains(')')) {
                              try {
                                final startIdx = rawSenderName.indexOf('(');
                                final endIdx = rawSenderName.lastIndexOf(')');
                                schoolName = rawSenderName.substring(startIdx + 1, endIdx).trim();
                                displayName = rawSenderName.substring(0, startIdx).trim();
                                if (displayName.contains('–')) {
                                  displayName = displayName.split('–').first.trim();
                                }
                              } catch (_) {}
                            } else if (rawSenderName.contains('–')) {
                              // "Name – Role" without school
                              displayName = rawSenderName.split('–').first.trim();
                            }

                            // Fallback: if sender_name is empty/generic, use email
                            if (displayName.isEmpty || displayName.toLowerCase().contains('reply')) {
                              displayName = fromEmail.isNotEmpty ? fromEmail.split('@').first : 'Unknown';
                            }

                            String formattedTime = '';
                            if (dateStr.isNotEmpty) {
                              try {
                                final dt = DateTime.parse(dateStr).toLocal();
                                formattedTime = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {
                                formattedTime = dateStr;
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF86EFAC).withOpacity(0.6)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.reply_rounded, color: Color(0xFF10B981), size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    displayName,
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: roleName == 'Teacher'
                                                        ? const Color(0xFF8B5CF6).withOpacity(0.12)
                                                        : const Color(0xFF3B82F6).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    roleName,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: roleName == 'Teacher' ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (schoolName.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(Icons.school_outlined, size: 11, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      schoolName,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (parentMsgText != null && parentMsgText.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: const Border(
                                          left: BorderSide(color: Color(0xFF94A3B8), width: 3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'In response to:',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            parentMsgText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF475569),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  Text(messageText, style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4)),
                                  if (fromEmail.isNotEmpty || formattedTime.isNotEmpty || schoolName.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (fromEmail.isNotEmpty)
                                          Flexible(
                                            child: Text(
                                              fromEmail,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const Spacer(),
                                        if (schoolName.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF86EFAC)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.school_rounded, size: 12, color: Color(0xFF15803D)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  schoolName.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF15803D),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (formattedTime.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF2E7D32)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedTime,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF2E7D32),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  // ── Delete button ──────────────────────────
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final replyId = reply['id']?.toString() ?? '';
                                        if (replyId.isEmpty) return;
                                        // Confirm before deleting
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                                SizedBox(width: 8),
                                                Text('Delete Message', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                              ],
                                            ),
                                            content: const Text(
                                              'Delete this reply? It will be permanently removed from the database.',
                                              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  elevation: 0,
                                                ),
                                                child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true && context.mounted) {
                                          try {
                                            await ApiService.instance.deleteAdminReply(replyId);
                                            setModalState(() {
                                              _principalReplies.removeWhere((r) => r['id']?.toString() == replyId);
                                            });
                                            setState(() {
                                              _principalReplies.removeWhere((r) => r['id']?.toString() == replyId);
                                            });
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Delete failed: $e'),
                                                  backgroundColor: Colors.redAccent,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                            SizedBox(width: 4),
                                            Text(
                                              'Delete',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.redAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }

  void _showAdminMessageDialog() {
    final messageController = TextEditingController();
    final searchController = TextEditingController();
    List<Map<String, dynamic>> allSchools = [];
    List<Map<String, dynamic>> filteredSchools = [];
    List<String> selectedSchoolIds = [];
    bool sendToAll = false;
    bool isSending = false;
    bool isLoadingSchools = true;
    String targetRole = 'all'; // 'all' | 'principal' | 'teacher'

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Load schools on first build
          if (isLoadingSchools && allSchools.isEmpty) {
            DataService.instance.fetchSchools().then((schools) {
              setDialogState(() {
                allSchools = schools;
                filteredSchools = schools;
                isLoadingSchools = false;
              });
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send Message to Schools', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Select one, multiple, or all principals', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Recipient Type Selector ──
                          const Text(
                            'Send To',
                            style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                for (final opt in [
                                  {'value': 'all', 'label': 'Both', 'icon': Icons.people_rounded},
                                  {'value': 'principal', 'label': 'Principals', 'icon': Icons.person_rounded},
                                  {'value': 'teacher', 'label': 'Teachers', 'icon': Icons.co_present_rounded},
                                ]) ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() => targetRole = opt['value'] as String),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          color: targetRole == opt['value'] ? const Color(0xFF4F46E5) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(opt['icon'] as IconData,
                                              size: 14,
                                              color: targetRole == opt['value'] ? Colors.white : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              opt['label'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: targetRole == opt['value'] ? Colors.white : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Send to All toggle ──
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: sendToAll ? const Color(0xFF4F46E5).withOpacity(0.08) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sendToAll ? const Color(0xFF4F46E5).withOpacity(0.4) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: sendToAll ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.people_rounded,
                                    color: sendToAll ? Colors.white : const Color(0xFF64748B),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Send to All Schools',
                                        style: TextStyle(
                                          color: sendToAll ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        sendToAll ? '${allSchools.length} schools selected' : 'Toggle to message all principals at once',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: sendToAll,
                                  activeColor: const Color(0xFF4F46E5),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      sendToAll = val;
                                      if (val) selectedSchoolIds.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          if (!sendToAll) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Select Schools',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),

                            // ── Search bar ──
                            TextField(
                              controller: searchController,
                              onChanged: (val) {
                                setDialogState(() {
                                  filteredSchools = allSchools.where((s) =>
                                    (s['name'] ?? '').toString().toLowerCase().contains(val.toLowerCase())
                                  ).toList();
                                });
                              },
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search school by name...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                        onPressed: () {
                                          searchController.clear();
                                          setDialogState(() { filteredSchools = allSchools; });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
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
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Schools list ──
                            if (isLoadingSchools)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                                ),
                              )
                            else if (filteredSchools.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('No schools found', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredSchools.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFF6FF)),
                                    itemBuilder: (context, index) {
                                      final school = filteredSchools[index];
                                      final sid = school['id']?.toString() ?? '';
                                      final isSelected = selectedSchoolIds.contains(sid);
                                      return InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            if (isSelected) {
                                              selectedSchoolIds.remove(sid);
                                            } else {
                                              selectedSchoolIds.add(sid);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.07) : Colors.white,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(
                                                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      school['name'] ?? 'School',
                                                      style: TextStyle(
                                                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                                        fontSize: 13,
                                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (school['city'] != null)
                                                      Text(
                                                        school['city'].toString(),
                                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.school_rounded, color: Color(0xFFCBD5E1), size: 16),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // Selected count
                            if (selectedSchoolIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${selectedSchoolIds.length} school${selectedSchoolIds.length > 1 ? 's' : ''} selected',
                                        style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => setDialogState(() => selectedSchoolIds.clear()),
                                      child: const Text('Clear', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                          ],

                          const SizedBox(height: 16),
                          const Text(
                            'Message',
                            style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),

                          // ── Message text box ──
                          TextField(
                            controller: messageController,
                            maxLines: 5,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Type your message here for the selected principals...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
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
                                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Send button ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                final msg = messageController.text.trim();
                                if (msg.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please type a message first.'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                if (!sendToAll && selectedSchoolIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select at least one school or enable Send to All.'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                setDialogState(() => isSending = true);
                                try {
                                  final targets = sendToAll
                                      ? allSchools.map((s) => s['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList()
                                      : selectedSchoolIds;
                                  final targetNames = sendToAll
                                      ? 'All Schools'
                                      : allSchools.where((s) => selectedSchoolIds.contains(s['id']?.toString())).map((s) => s['name'] ?? '').join(', ');
                                  // Send via API
                                  await ApiService.instance.sendAdminMessage(
                                    message: msg,
                                    schoolIds: targets,
                                    sendToAll: sendToAll,
                                    targetRole: targetRole,
                                  );
                                  if (context.mounted) Navigator.of(ctx).pop();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ Message sent to $targetNames!'),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSending = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error sending: $e'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    sendToAll
                                        ? 'Send to All ${targetRole == 'all' ? 'Recipients' : targetRole == 'principal' ? 'Principals' : 'Teachers'}'
                                        : (selectedSchoolIds.isEmpty
                                            ? 'Send Message'
                                            : 'Send to ${selectedSchoolIds.length} School${selectedSchoolIds.length > 1 ? 's' : ''}'),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-fetch data when app returns to foreground
    if (state == AppLifecycleState.resumed) {
      DataService.instance.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Slate 800
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Exit Application',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Are you sure you want to exit Adyapan Portal?',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Exit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Expose beautiful side drawer on mobile viewports
        drawer: !isDesktop ? _buildMobileDrawer() : null,
        body: Container(
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
          child: SafeArea(
            top: true, // Guarantees status bar notch spacing
            child: Row(
              children: [
                // Desktop Navigation Sidebar
                if (isDesktop) _buildSidebar(),
    
                // Main View Content
                Expanded(
                  child: Column(
                    children: [
                      _buildTopAppBar(isDesktop),
                      Expanded(
                        child: _tabs[_selectedIndex],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: !isDesktop
            ? widget.role == 'Admin'
                ? _buildAdminBottomBar()
                : BottomNavigationBar(
                    currentIndex: _selectedIndex >= 4 ? 0 : _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedItemColor: const Color(0xFF4F46E5),
                    unselectedItemColor: const Color(0xFF64748B),
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    items: _navigationItems.take(4).map((item) {
                      return BottomNavigationBarItem(
                        icon: Icon(item['icon']),
                        label: item['title'].toString().split(' ')[0],
                      );
                    }).toList(),
                  )
            : null,
      ),
    );
  }

  /// Custom bottom bar for Admin: Overview, Teachers, Students + center Message FAB
  Widget _buildAdminBottomBar() {
    const barItems = [
      {'index': 0, 'title': 'Overview', 'icon': Icons.dashboard_rounded},
      {'index': 1, 'title': 'Teachers', 'icon': Icons.co_present_rounded},
      {'index': 2, 'title': 'Students', 'icon': Icons.school_rounded},
    ];
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          ...barItems.map((item) {
            final idx = item['index'] as int;
            final isSelected = _selectedIndex == idx;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedIndex = idx),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Message center button
          Expanded(
            child: InkWell(
              onTap: _showAdminMessageDialog,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final isPrincipal = widget.role == 'Principal';
    final isAdmin = widget.role == 'Admin';

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8EEF9),
              Color(0xFFDCE3FA),
              Color(0xFFEBF1FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Drawer Header Branding
            Container(
              padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 28),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADYAPAN',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Command Center',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User Profile Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE3FA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isPrincipal ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      child: Text(
                        widget.displayName[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isPrincipal ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.role.toUpperCase(),
                              style: TextStyle(
                                color: isPrincipal ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
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

            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),

            // Drawer Options List
            Expanded(
              child: ListView(
                children: [
                  // All navigation items
                  ..._navigationItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Material(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Supervision Panel (drawer-only for Admin)
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Material(
                        color: _selectedIndex == 3 ? const Color(0xFF4F46E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = 3);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.analytics_rounded,
                                  color: _selectedIndex == 3 ? Colors.white : const Color(0xFF475569),
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Supervision Panel',
                                  style: TextStyle(
                                    color: _selectedIndex == 3 ? Colors.white : const Color(0xFF475569),
                                    fontSize: 14,
                                    fontWeight: _selectedIndex == 3 ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleSignOut();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 16),
                        Text(
                          'Sign Out Session',
                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final isPrincipal = widget.role == 'Principal';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8EEF9), // Soft ice grey-blue
            Color(0xFFDCE3FA), // Premium pastel lavender-indigo
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
        border: const Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header (Logo/App Title)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADYAPAN',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Management Hub',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 24),

          // User Mini Profile Detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDCE3FA),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isPrincipal ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    child: Text(
                      widget.displayName[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayName.split(' ')[0],
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPrincipal ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.role.toUpperCase(),
                            style: TextStyle(
                              color: isPrincipal ? const Color(0xFF059669) : const Color(0xFF2563EB),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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
          const SizedBox(height: 32),

          // Sidebar Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Material(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'],
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              item['title'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isDesktop) {
    return Container(
      height: 72,
      color: Colors.white.withOpacity(0.55),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Title & Drawer toggle
          Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _navigationItems[_selectedIndex]['title'],
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Right side: Identity & Notifications
          Row(
            children: [
              // Notification Icon
              () {
                final hasUnread = widget.role == 'Principal' || widget.role == 'Teacher'
                    ? _adminMessages.any((m) => !_readMessageIds.contains(m['id']?.toString() ?? ''))
                    : widget.role == 'Admin'
                        ? _principalReplies.any((r) => r['status']?.toString() != 'read')
                        : false;

                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                      if (hasUnread)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                    ],
                  ),
                  onPressed: () {
                    if (widget.role == 'Principal' || widget.role == 'Teacher') {
                      _showNotificationInbox(context);
                    } else if (widget.role == 'Admin') {
                      _showAdminRepliesInbox(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new administrative notifications.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              }(),
              const SizedBox(width: 12),

              if (isDesktop) ...[
                const SizedBox(
                  height: 32,
                  child: VerticalDivider(color: Color(0xFFE2E8F0)),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
