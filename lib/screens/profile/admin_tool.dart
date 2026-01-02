import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool loading = false;
  String logText = "";

  // 🔐 Replace with your real admin UID
  final String adminUid = "YOUR_UID_HERE";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // Restrict access
    if (user == null || user.uid != adminUid) {
      Future.delayed(Duration.zero, () {
        Navigator.pop(context);
      });
    }
  }

  // ----------------------------------------------------------
  // FIRESTORE OPERATIONS
  // ----------------------------------------------------------

  Future<void> addDefaultFields() async {
    setState(() {
      loading = true;
      logText = "Adding default fields to all users...";
    });

    final users = await db.collection('users').get();

    for (var doc in users.docs) {
      await doc.reference.set({
        'ratingCount': 0,
        'ratingTotal': 0,
        'avgRating': 0.0,
        'helpsGiven': 0,
        'helpsReceived': 0,
        'badges': [],
      }, SetOptions(merge: true));
    }

    setState(() {
      loading = false;
      logText = "Default fields added to ${users.docs.length} users.";
    });
  }

  Future<void> resetAllBadges() async {
    setState(() {
      loading = true;
      logText = "Clearing all badges...";
    });

    final users = await db.collection('users').get();

    for (var doc in users.docs) {
      await doc.reference.set({'badges': []}, SetOptions(merge: true));
    }

    setState(() {
      loading = false;
      logText = "Badges cleared for all users.";
    });
  }

  Future<void> resetAllRatings() async {
    setState(() {
      loading = true;
      logText = "Resetting ALL ratings...";
    });

    final users = await db.collection('users').get();

    // Reset each user rating totals
    for (var doc in users.docs) {
      await doc.reference.set({
        'ratingCount': 0,
        'ratingTotal': 0,
        'avgRating': 0.0,
      }, SetOptions(merge: true));
    }

    // Delete all rating documents
    final ratings = await db.collection('ratings').get();
    for (var r in ratings.docs) {
      await r.reference.delete();
    }

    setState(() {
      loading = false;
      logText = "All ratings cleared.";
    });
  }

  Future<void> clearChats() async {
    setState(() {
      loading = true;
      logText = "Deleting all chats...";
    });

    final chats = await db.collection('chats').get();

    for (var chat in chats.docs) {
      // Delete messages inside the chat
      final msgs = await chat.reference.collection('messages').get();
      for (var m in msgs.docs) {
        await m.reference.delete();
      }

      // Delete the chat itself
      await chat.reference.delete();
    }

    setState(() {
      loading = false;
      logText = "All chats deleted.";
    });
  }

  Future<void> getStats() async {
    final userCount = (await db.collection('users').get()).docs.length;
    final chatCount = (await db.collection('chats').get()).docs.length;
    final ratingCount = (await db.collection('ratings').get()).docs.length;

    setState(() {
      logText =
          """
Users: $userCount
Chats: $chatCount
Ratings: $ratingCount
""";
    });
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Admin Tools",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _button("Add Default User Fields", addDefaultFields),
            _button("Reset All Ratings", resetAllRatings),
            _button("Reset All Badges", resetAllBadges),
            _button("Clear All Chats", clearChats),
            _button("Show Stats", getStats),

            const SizedBox(height: 20),

            loading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    logText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _button(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
