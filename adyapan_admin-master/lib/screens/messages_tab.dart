import 'package:flutter/material.dart';

class MessagesTab extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Set<String> readMessageIds;
  final Future<void> Function() onRefresh;
  final Function(String msgId, String messageText) onReply;
  final Function() onComposeNew;

  const MessagesTab({
    super.key,
    required this.messages,
    required this.readMessageIds,
    required this.onRefresh,
    required this.onReply,
    required this.onComposeNew,
  });

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  Future<void> _handleRefresh() async {
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Message Center 💬',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: widget.onComposeNew,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4F46E5),
        child: widget.messages.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('📬', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'All caught up!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No messages received from the admin yet.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Check for Messages'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: widget.messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  final msgId = msg['id']?.toString() ?? '';
                  final titleText = msg['title']?.toString() ?? '📢 Admin Message';
                  final messageText = msg['message']?.toString() ?? msg['body']?.toString() ?? '';
                  final dateStr = msg['sentAt']?.toString() ?? msg['created_at']?.toString() ?? msg['sent_at']?.toString() ?? '';
                  final isUnread = !widget.readMessageIds.contains(msgId);

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
                    decoration: BoxDecoration(
                      color: isUnread ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread ? const Color(0xFF6366F1).withOpacity(0.4) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                    fontSize: 14,
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
                          const SizedBox(height: 12),
                          Text(
                            messageText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF334155),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
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
                              InkWell(
                                onTap: () => widget.onReply(msgId, messageText),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.reply_rounded,
                                        size: 14,
                                        color: Color(0xFF4F46E5),
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
                    ),
                  );
                },
              ),
      ),
    );
  }
}
