import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool showGiven = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Help History",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black, // FIXED
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 15),

          /// TOGGLE BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _toggleBtn("Helps Given", showGiven, () {
                setState(() => showGiven = true);
              }),
              const SizedBox(width: 10),
              _toggleBtn("Helps Received", !showGiven, () {
                setState(() => showGiven = false);
              }),
            ],
          ),

          const SizedBox(height: 20),

          /// HISTORY STREAM
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _historyStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No history found",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _historyCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔥 HISTORY FIRESTORE STREAM FIXED
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot> _historyStream() {
    final col = FirebaseFirestore.instance.collection('help_requests');

    if (showGiven) {
      return col
          .where('acceptedBy', isEqualTo: widget.userId)
          .orderBy('acceptedAt', descending: true)
          .snapshots();
    } else {
      return col
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // ---------------------------------------------------------------------------
  // TOGGLE BUTTON
  // ---------------------------------------------------------------------------
  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HISTORY CARD
  // ---------------------------------------------------------------------------
  Widget _historyCard(Map<String, dynamic> data) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final title = data['title'] ?? "No Title";
    final desc = data['description'] ?? "";
    final status = (data['status'] ?? '').toString().toUpperCase();

    final acceptedBy = data['acceptedBy'];
    final bool isGiven = acceptedBy == userId;

    final Timestamp? ts =
        data['completedAt'] ?? data['acceptedAt'] ?? data['createdAt'];
    final date = ts?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(.06),
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ROLE TEXT
          Text(
            isGiven ? "You helped someone" : "Someone helped you",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          /// TITLE
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          /// DESCRIPTION
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// STATUS BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              /// DATE
              if (date != null)
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS COLOR
  // ---------------------------------------------------------------------------
  Color _statusColor(String s) {
    switch (s) {
      case "COMPLETED":
        return Colors.green;
      case "ACCEPTED":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
