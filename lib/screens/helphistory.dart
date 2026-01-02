// lib/screens/home/help_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:help_circle_new/screens/home/requests/helpreq.dart';
import 'package:help_circle_new/screens/home/requests/request_details_screen.dart';
import 'package:intl/intl.dart';

class HelpHistoryScreen extends StatefulWidget {
  const HelpHistoryScreen({super.key});

  @override
  State<HelpHistoryScreen> createState() => _HelpHistoryScreenState();
}

class _HelpHistoryScreenState extends State<HelpHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  String? uid;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  // ---------------------------- GIVES HELP ----------------------------
  Stream<List<HelpRequest>> _givenStream() {
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('help_requests')
        .where('completedBy', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HelpRequest.fromDoc(d)).toList());
  }

  // ---------------------------- RECEIVED HELP ----------------------------
  Stream<List<HelpRequest>> _receivedStream() {
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('help_requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HelpRequest.fromDoc(d)).toList());
  }

  // ---------------------------- DATE FORMATTER ----------------------------
  String _fmt(DateTime? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return '-';
    }
  }

  Widget _ratingBadge(double? rating) {
    if (rating == null || rating <= 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- HISTORY LIST ----------------------------
  Widget _list(Stream<List<HelpRequest>> stream, {required bool given}) {
    return StreamBuilder<List<HelpRequest>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Text(
              'No history found',
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final r = items[i];

            // 🔑 decide which user to show
            final targetUserId = given ? r.userId : r.acceptedBy;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetUserId)
                  .get(),
              builder: (_, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>?;

                final name = userData?['name'] ?? 'User';
                final photo = userData?['photoUrl'] ?? '';

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestDetailsScreen(
                          request: r,
                          readOnly: true, // 🔒 IMPORTANT
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------- TOP ROW ----------------
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      given
                                          ? 'You helped $name'
                                          : 'Helped by $name',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ratingBadge(r.rating), // ⭐ ADD
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Done',
                                      style: GoogleFonts.inter(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            r.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _fmt(
                                  r.completedAt ?? r.acceptedAt ?? r.createdAt,
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
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
        );
      },
    );
  }

  // ---------------------------- UI ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Help History',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black, // FIXED
          ),
        ),
        bottom: TabBar(
          controller: _tc,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey.shade700,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Helps Given'),
            Tab(text: 'Helps Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _list(_givenStream(), given: true),
          _list(_receivedStream(), given: false),
        ],
      ),
    );
  }
}
