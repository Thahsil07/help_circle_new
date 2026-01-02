import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:help_circle_new/screens/home/chatwindow.dart';
import 'package:help_circle_new/services/chat_service.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        elevation: 0,
        title: Text(
          "Messages",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.chatListStream(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text("Failed to load chats"));
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final participants = List<String>.from(
                data['participants'] ?? [],
              );

              // SAFETY CHECK
              if (participants.length != 2 || !participants.contains(uid)) {
                return const SizedBox.shrink();
              }

              final peerId = participants.firstWhere((id) => id != uid);

              final lastMessage = data['lastMessage'] ?? '';
              final Timestamp? lastAt = data['lastMessageAt'];

              final unreadMap = Map<String, dynamic>.from(
                data['unreadCount'] ?? {},
              );
              final unreadCount = unreadMap[uid] is int ? unreadMap[uid] : 0;

              // 🔥 FETCH USER DATA (because peerMeta does NOT exist)
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(peerId)
                    .get(),
                builder: (context, userSnap) {
                  final user =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};

                  final name = user['name'] ?? 'User';
                  final photo = user['photoUrl'] ?? '';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatWindowScreen(
                              chatId: doc.id,
                              peerId: peerId,
                              peerName: name,
                              peerPhotoUrl: photo,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEAF1FF),
                        backgroundImage: photo.isNotEmpty
                            ? NetworkImage(photo)
                            : null,
                        child: photo.isEmpty
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3474F6),
                                ),
                              )
                            : null,
                      ),

                      title: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          lastMessage.isEmpty ? "No messages yet" : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: unreadCount > 0
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),

                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastAt != null)
                            Text(
                              _formatTime(context, lastAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: unreadCount > 0
                                    ? const Color(0xFF3474F6)
                                    : Colors.grey.shade500,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3474F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
    );
  }

  String _formatTime(BuildContext context, Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return TimeOfDay.fromDateTime(dt).format(context);
    }

    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}";
  }
}
