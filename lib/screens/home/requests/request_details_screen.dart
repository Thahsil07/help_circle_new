import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:help_circle_new/screens/ratingscreen.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:help_circle_new/screens/home/chatwindow.dart';
import 'package:help_circle_new/screens/home/requests/helpreq.dart';
import 'package:help_circle_new/screens/home/requests/create_request_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final HelpRequest request;
  final bool readOnly;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.readOnly = false,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference _docRef;

  static const Color primary = Color(0xFF3474F6);

  @override
  void initState() {
    super.initState();
    _docRef = FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.request.id);
  }

  Widget _headerImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink(); // no image → no space
    }

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (c, w, p) {
            if (p == null) return w;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, size: 40),
          ),
        ),
      ),
    );
  }

  // ---------------- MAP ACTIONS ----------------

  Future<void> _openGoogleNavigation(HelpRequest r) async {
    if (r.latitude == null || r.longitude == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${r.latitude},${r.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullOSM(HelpRequest r) {
    if (r.latitude == null || r.longitude == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullOSMMap(lat: r.latitude!, lng: r.longitude!),
      ),
    );
  }

  // ---------------- STATUS BADGE ----------------

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'accepted':
        bg = Colors.blue.shade50;
        fg = Colors.blue;
        break;
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ---------------- FIRESTORE LOGIC ----------------

  Future<void> _acceptHelp(HelpRequest r) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc();

    await chatRef.set({
      'requestId': r.id,
      'participants': [r.userId, uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _docRef.update({
      'status': 'accepted',
      'acceptedBy': uid,
      'chatId': chatRef.id,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _openChat(HelpRequest r) async {
    final peerId = uid == r.userId ? r.acceptedBy : r.userId;
    if (peerId.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(peerId)
        .get();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatWindowScreen(
          chatId: r.chatId!,
          peerId: peerId,
          peerName: userDoc['name'] ?? 'User',
          peerPhotoUrl: userDoc['photoUrl'] ?? '',
        ),
      ),
    );
  }

  Future<void> _markCompleted(HelpRequest r) async {
    if (r.userId != uid || r.status != 'accepted') return;

    final helperId = r.acceptedBy;
    if (helperId.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    final reqRef = _docRef;
    final ownerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(r.userId);
    final helperRef = FirebaseFirestore.instance
        .collection('users')
        .doc(helperId);

    // 1️⃣ READ helper data ONCE
    final helperSnap = await helperRef.get();
    final data = helperSnap.data() ?? {};

    final int oldHelps = data['helpsGiven'] ?? 0;
    final double avgRating = (data['avgRating'] ?? 0).toDouble();

    final int newHelps = oldHelps + 1;
    final double leaderboardScore = newHelps * 10 + avgRating;

    // 2️⃣ UPDATE REQUEST
    batch.update(reqRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': uid,
    });

    // 3️⃣ UPDATE OWNER
    batch.set(ownerRef, {
      'helpsReceived': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 4️⃣ UPDATE HELPER + SCORE
    batch.set(helperRef, {
      'helpsGiven': newHelps,
      'leaderboardScore': leaderboardScore,
    }, SetOptions(merge: true));

    // 5️⃣ COMMIT
    await batch.commit();

    if (!mounted) return;

    // 6️⃣ GO TO RATING SCREEN
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          targetUserId: helperId,
          targetName: "Helper",
          requestId: r.id,
        ),
      ),
    );
  }

  Future<void> _deleteRequest() async {
    await _docRef.delete();
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _docRef.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final r = HelpRequest.fromDoc(snap.data!);

        final isOwner = r.userId == uid;
        final isAccepted = r.status == 'accepted';
        final isCompleted = r.status == 'completed';

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4F8DFF), Color(0xFF3474F6)],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Request Details",
              style: GoogleFonts.inter(
                letterSpacing: 0.4,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerImage(r.imageUrl),
                SizedBox(height: 14),

                // CATEGORY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r.category?.toUpperCase() ?? 'OTHER',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // MAP PREVIEW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Map Preview",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  r.latitude!,
                                  r.longitude!,
                                ),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.help_circle_new',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(r.latitude!, r.longitude!),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.open_in_full, color: primary),
                                label: Text(
                                  "Open Full Map",
                                  style: TextStyle(color: primary),
                                ),
                                onPressed: () => _openFullOSM(r),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary, // 🔥 important
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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

                const SizedBox(height: 16),

                // NAVIGATE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text("Navigate"),
                      onPressed: () => _openGoogleNavigation(r),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // USER ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.createdByName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Posted • ${r.createdAtFormatted}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(r.status),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (isOwner)
                  _twoBtnRow(
                    "Edit",
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRequestScreen(existingRequest: r),
                      ),
                    ),
                    "Delete",
                    Colors.red,
                    _deleteRequest,
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isOwner
                          ? (isAccepted && !isCompleted
                                ? () => _markCompleted(r)
                                : null)
                          : (!isAccepted
                                ? () => _acceptHelp(r)
                                : () => _openChat(r)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isOwner
                            ? "Mark Completed"
                            : (!isAccepted ? "Offer Help" : "Chat"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _twoBtnRow(
    String a,
    Color ac,
    VoidCallback ao,
    String b,
    Color bc,
    VoidCallback bo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: ao,
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Edit",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: bo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- FULL OSM MAP ----------------

class _FullOSMMap extends StatelessWidget {
  final double lat;
  final double lng;

  const _FullOSMMap({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: FlutterMap(
        options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.help_circle_new',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
