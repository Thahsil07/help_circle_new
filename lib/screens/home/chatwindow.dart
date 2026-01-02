import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:help_circle_new/services/chat_service.dart';

class ChatWindowScreen extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;
  final String peerPhotoUrl;

  const ChatWindowScreen({
    super.key,
    required this.chatId,
    required this.peerId,
    required this.peerName,
    required this.peerPhotoUrl,
  });

  @override
  State<ChatWindowScreen> createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends State<ChatWindowScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markChatRead(widget.chatId, uid);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!mounted) return;

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    _ctrl.clear();

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: uid,
      text: text,
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.peerPhotoUrl.isNotEmpty
                  ? NetworkImage(widget.peerPhotoUrl)
                  : null,
              child: widget.peerPhotoUrl.isEmpty
                  ? Text(
                      widget.peerName.isNotEmpty
                          ? widget.peerName[0].toUpperCase()
                          : "?",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.peerName,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.messagesStream(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                // mark seen whenever messages update
                _chatService.markChatRead(widget.chatId, uid);

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                Future.delayed(Duration.zero, () {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .snapshots(),
                  builder: (context, chatSnap) {
                    final chatData =
                        chatSnap.data?.data() as Map<String, dynamic>? ?? {};
                    final unreadMap = Map<String, dynamic>.from(
                      chatData['unreadCount'] ?? {},
                    );
                    final peerUnread = unreadMap[widget.peerId] is int
                        ? unreadMap[widget.peerId]
                        : 0;

                    final isSeen = peerUnread == 0;

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final senderId = d['senderId'];
                        final text = d['text'] ?? '';
                        final Timestamp? ts = d['createdAt'];

                        if (ts == null) return const SizedBox.shrink();

                        final isMe = senderId == uid;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF3474F6)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: isMe
                                    ? const Radius.circular(14)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(14),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(ts),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        isSeen ? Icons.done_all : Icons.done,
                                        size: 16,
                                        color: isSeen
                                            ? Colors.lightBlueAccent
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message…",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3474F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return TimeOfDay.fromDateTime(dt).format(context);
    }

    return "${dt.day}/${dt.month}";
  }
}
