import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:help_circle_new/screens/auth/profile/updateprofile.dart';
import 'package:help_circle_new/screens/auth/services.dart';
import 'package:help_circle_new/screens/historyscreen.dart';
import 'package:help_circle_new/screens/leader_board.dart';
import 'package:help_circle_new/screens/settingsscreen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final data = snap.data!.data() ?? {};

          final name = (data['name'] ?? "User").toString();
          final email = (data['email'] ?? "").toString();
          final photoUrl = (data['photoUrl'] ?? "").toString();

          final helpsGiven = data['helpsGiven'] ?? 0;

          final helpsReceived = data['helpsReceived'] ?? 0;

          final double avgRating =
              (data['avgRating'] as num?)?.toDouble() ?? 0.0;
          final int ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
          // ---------------- ACHIEVEMENT PROGRESS ----------------
          int nextTarget = 0;
          String nextBadge = "";

          if (helpsGiven < 1) {
            nextTarget = 1;
            nextBadge = "First Help";
          } else if (helpsGiven < 5) {
            nextTarget = 5;
            nextBadge = "5 Helps";
          } else if (helpsGiven < 10) {
            nextTarget = 10;
            nextBadge = "Top Helper";
          }

          final List badges = List.from(data['badges'] ?? []);

          return Stack(
            children: [
              _header(),

              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 150),

                    _profileCard(
                      context,
                      name,
                      email,
                      photoUrl,
                      helpsGiven,
                      helpsReceived,
                      avgRating,
                      ratingCount,
                      nextTarget,
                      nextBadge,
                    ),

                    const SizedBox(height: 20),

                    if (badges.isNotEmpty) _achievementsSection(badges),

                    const SizedBox(height: 25),

                    _editButton(context),

                    const SizedBox(height: 12),

                    _menuTile(
                      context,
                      icon: Icons.history,
                      title: "Help History",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryScreen(userId: userId),
                        ),
                      ),
                    ),
                    _menuTile(
                      context,
                      icon: Icons.leaderboard,
                      title: "Leaderboard",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                    ),

                    _menuTile(
                      context,
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),

                    _logoutTile(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 20, top: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3474F6), Color(0xFF2A5AD9), Color(0xFF1E44C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        "Profile",
        style: GoogleFonts.inter(
          fontSize: 25,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------- PROFILE CARD ----------------
  Widget _profileCard(
    BuildContext context,
    String name,
    String email,
    String photoUrl,
    int helpsGiven,
    int helpsReceived,
    double avgRating,
    int ratingCount,
    int nextTarget,
    String nextBadge,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _avatar(name, photoUrl),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            email,
            style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _statsRow(helpsReceived, helpsGiven, avgRating, ratingCount),
          if (nextTarget > 0) ...[
            const SizedBox(height: 10),
            Text(
              "Progress: $helpsGiven / $nextTarget towards $nextBadge",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- AVATAR ----------------
  Widget _avatar(String name, String photoUrl) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6A5AE0), width: 3),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE0E4FF),
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: !hasPhoto
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: GoogleFonts.inter(fontSize: 28),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // ---------------- STATS ----------------
  Widget _statsRow(
    int helpsReceived,
    int helpsGiven,
    double rating,
    int ratingCount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem("Requests", helpsReceived, Icons.trending_up, Colors.blue),
        _statItem(
          "Helps Given",
          helpsGiven,
          Icons.workspace_premium,
          Colors.green,
        ),
        _statItem(
          "Rating",
          ratingCount == 0 ? "-" : rating.toStringAsFixed(1),
          Icons.star,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statItem(
    String label,
    dynamic value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  // ---------------- ACHIEVEMENTS ----------------
  Widget _achievementsSection(List badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Achievements",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: badges.length,
            itemBuilder: (_, i) => _badge(badges[i].toString()),
          ),
        ),
      ],
    );
  }

  Widget _badge(String title) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.06)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.military_tech, color: Colors.orange),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------- EDIT PROFILE ----------------
  Widget _editButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A5AD9), Color(0xFF1E44C2)],
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateProfileScreen(userId: userId),
            ),
          );
        },
        child: Center(
          child: Text(
            "Edit Profile",
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    return _menuTile(
      context,
      icon: Icons.logout,
      title: "Logout",
      onTap: () => _confirmLogout(context),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.instance.signOut();
              Navigator.pop(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
