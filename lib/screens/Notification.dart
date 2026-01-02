// lib/screens/notifications/notifications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Stream<QuerySnapshot> _notifStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markRead(DocumentReference doc) async {
    await doc.update({'read': true});
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black, // FIXED: Always black
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                color: Colors.blue, // FIXED color
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _notifStream(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final bool read = data['read'] ?? false;
              final String title = data['title'] ?? '';
              final String body = data['body'] ?? '';
              final ts = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: read
                      ? Colors.grey.shade200
                      : Colors.blue.shade100,
                  child: Icon(
                    Icons.notifications,
                    color: read ? Colors.grey : Colors.blue,
                  ),
                ),

                title: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black, // FIXED
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black87, // FIXED
                      ),
                    ),
                    if (ts != null)
                      Text(
                        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')} • ${ts.day}/${ts.month}/${ts.year}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),

                trailing: read
                    ? null
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),

                onTap: () async {
                  await _markRead(d.reference);

                  final type = data['type'] as String?;
                  if (type == 'help_completed' &&
                      data['meta'] != null &&
                      data['meta']['requestId'] != null) {
                    Navigator.pushNamed(
                      context,
                      '/request',
                      arguments: data['meta']['requestId'],
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
