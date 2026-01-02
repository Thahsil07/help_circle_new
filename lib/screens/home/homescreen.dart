import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:help_circle_new/screens/auth/profile/profile_screen.dart';
import 'package:help_circle_new/screens/home/chatlist.dart';
import 'package:help_circle_new/screens/home/requests/create_request_screen.dart';
import 'package:help_circle_new/screens/home/requests/helpreq.dart';
import 'package:help_circle_new/screens/home/requests/request_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  Position? userPos;

  final ValueNotifier<bool> showMyRequests = ValueNotifier(false);

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController searchCtrl = TextEditingController();
  String get query => searchCtrl.text.trim();

  final List<String> categories = [
    "Blood Donation",
    "Shopping",
    "Moving",
    "Medical",
    "Transport",
    "Other",
  ];

  final List<String> urgencies = ["High", "Medium", "Low"];

  Set<String> selectedCategories = {};
  Set<String> selectedUrgencies = {};
  double radiusKm = 10.0;
  bool sortByDistance = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    selectedCategories = categories.toSet();
    selectedUrgencies = urgencies.toSet();
  }

  Future<void> _loadLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever)
        return;

      userPos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // --------------------------------------------------
  // BASE STREAM
  // --------------------------------------------------
  Stream<List<HelpRequest>> get _baseStream => FirebaseFirestore.instance
      .collection("help_requests")
      .snapshots()
      .map((snap) => snap.docs.map((d) => HelpRequest.fromDoc(d)).toList());

  // --------------------------------------------------
  // COMMUNITY (STRICT)
  // --------------------------------------------------
  Stream<List<HelpRequest>> get _communityStream {
    return _baseStream.map((list) {
      var filtered = list.where((r) {
        if (r.status == 'completed') return false;
        if (r.userId == uid) return false;

        final q = query.toLowerCase();
        final matchSearch =
            q.isEmpty ||
            r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            (r.category?.toLowerCase().contains(q) ?? false);

        final matchCategory = selectedCategories.contains(
          r.category ?? "Other",
        );

        final matchUrgency = selectedUrgencies.contains(
          _normalizeUrgency(r.urgency),
        );

        return matchSearch && matchCategory && matchUrgency;
      }).toList();

      if (userPos != null) {
        filtered = filtered
            .map((r) {
              if (r.latitude == null || r.longitude == null) {
                return r.copyWith(distanceKm: double.infinity);
              }
              final d = HelpRequest.calculateDistanceKm(
                userPos!.latitude,
                userPos!.longitude,
                r.latitude!,
                r.longitude!,
              );
              return r.copyWith(distanceKm: d);
            })
            .where((r) => r.distanceKm <= radiusKm)
            .toList();

        if (sortByDistance) {
          filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        }
      }

      return filtered;
    });
  }

  // --------------------------------------------------
  // MY REQUESTS (OWNER ONLY)
  // --------------------------------------------------
  Stream<List<HelpRequest>> _myRequestsStream() {
    if (uid == null) return Stream.value([]);

    return _baseStream.map((list) {
      final mine = list.where((r) => r.userId == uid).toList();
      mine.sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );
      return mine;
    });
  }

  // --------------------------------------------------
  // UNREAD
  // --------------------------------------------------
  Stream<int> _unreadStream() {
    if (uid == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: uid)
        .snapshots()
        .map((snap) {
          int total = 0;
          for (var doc in snap.docs) {
            final unread = doc["unreadCount"];
            if (unread is Map && unread[uid] != null) {
              total += (unread[uid] as num).toInt();
            }
          }
          return total;
        });
  }

  String _normalizeUrgency(String u) {
    final s = u.toLowerCase();
    if (s.contains("high") || s.contains("urgent")) return "High";
    if (s.contains("med")) return "Medium";
    return "Low";
  }

  // --------------------------------------------------
  // UI (UNCHANGED)
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      floatingActionButton: index == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF3474F6),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateRequestScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(child: _screen()),
    );
  }

  Widget _screen() {
    if (index == 0) return _home();
    if (index == 1) return ChatListScreen();
    return ProfileScreen(userId: uid ?? "");
  }

  Widget _home() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 18),

          StreamBuilder<List<HelpRequest>>(
            stream: _communityStream,
            builder: (_, snap) {
              final count = snap.data?.length ?? 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(19, 8, 25, 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4F8DFF), // lighter than splash
                      Color(0xFF3474F6), // splash color
                    ],
                  ),

                  borderRadius: BorderRadius.circular(18),
                ),
                child: _header(count),
              );
            },
          ),

          const SizedBox(height: 8),
          _searchBar(),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: showMyRequests,
            builder: (_, isMy, __) {
              return _elasticSegment(
                isMyRequests: isMy,
                onCommunity: () => showMyRequests.value = false,
                onMyRequests: () => showMyRequests.value = true,
              );
            },
          ),

          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: showMyRequests,
              builder: (_, isMy, __) {
                return StreamBuilder<List<HelpRequest>>(
                  stream: isMy ? myRequestsStream() : _communityStream,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final list = snap.data!;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          isMy
                              ? "You haven't created any requests."
                              : "No requests available.",
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RequestDetailsScreen(request: r),
                              ),
                            ),
                            child: _requestCard(r, r.distanceKm),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // HEADER
  //--------------------------------------------------

  Widget _header(int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Help Near You",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$count requests nearby",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22, color: Colors.white),
          onPressed: _openFilterSheet,
        ),
      ],
    );
  }

  //--------------------------------------------------
  // SEARCH BAR
  //--------------------------------------------------
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: (_) => setState(() {}),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: "Search help requests...",
          hintStyle: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 0,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  //--------------------------------------------------
  // SEGMENT CONTROL
  //--------------------------------------------------
  Widget _elasticSegment({
    required bool isMyRequests,
    required VoidCallback onCommunity,
    required VoidCallback onMyRequests,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withOpacity(0.00)),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                left: isMyRequests ? w : 0,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3474F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCommunity,
                      child: Center(
                        child: Text(
                          "Community",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isMyRequests
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: onMyRequests,
                      child: Center(
                        child: Text(
                          "My Requests",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isMyRequests ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    late Color bg;
    late Color fg;
    late String text;

    switch (status) {
      case 'accepted':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        text = 'ACCEPTED';
        break;

      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = 'COMPLETED';
        break;

      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        text = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  //--------------------------------------------------
  // REQUEST CARD
  //--------------------------------------------------
  Widget _requestCard(HelpRequest r, double distanceKm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                r.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // CATEGORY
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                r.category ?? "General",
                style: TextStyle(
                  color: Colors.blueAccent.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // USER + STATUS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16, // 🔽 slightly smaller
                  backgroundImage: (r.createdByPhotoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(r.createdByPhotoUrl!)
                      : null,
                  child: (r.createdByPhotoUrl?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.createdByName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _timeAgo(r),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (r.userId == uid)
                  _tag("YOURS", Colors.blue.shade800, Colors.blue.shade50)
                else
                  _statusBadge(r.status),
              ],
            ),
          ),

          // TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              r.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),

          // DESCRIPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              r.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4, // 🔼 better readability
                color: Colors.grey.shade800,
              ),
            ),
          ),

          // FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  _distanceText(distanceKm),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  //--------------------------------------------------
  // TIME AGO
  //--------------------------------------------------
  bool _isRecent(DateTime? d) {
    if (d == null) return false;
    return DateTime.now().difference(d).inHours <= 24;
  }

  String _distanceText(double km) {
    if (km.isInfinite) return "Location unavailable";
    if (km < 0.1) return "Nearby";
    return "${km.toStringAsFixed(1)} km away";
  }

  String _timeAgo(HelpRequest r) {
    final d = r.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }

  //--------------------------------------------------
  // FILTER SHEET
  //--------------------------------------------------
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final tempCats = selectedCategories.toSet();
        final tempUrg = selectedUrgencies.toSet();
        double tempRadius = radiusKm;
        bool tempSort = sortByDistance;

        return StatefulBuilder(
          builder: (context, setX) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCategories = categories.toSet();
                            selectedUrgencies = urgencies.toSet();
                            radiusKm = 10.0;
                            sortByDistance = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // CATEGORY
                  const Text(
                    "Category",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in categories)
                        FilterChip(
                          label: Text(c),
                          selected: tempCats.contains(c),
                          onSelected: (v) {
                            setX(() {
                              v ? tempCats.add(c) : tempCats.remove(c);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // URGENCY
                  const Text(
                    "Urgency",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final u in urgencies)
                        ChoiceChip(
                          label: Text(u),
                          selected: tempUrg.contains(u),
                          onSelected: (v) {
                            setX(() {
                              v ? tempUrg.add(u) : tempUrg.remove(u);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // RADIUS
                  const Text(
                    "Nearby Radius (km)",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    min: 1,
                    max: 50,
                    divisions: 9,
                    label: "${tempRadius.toInt()} km",
                    value: tempRadius,
                    onChanged: (v) => setX(() => tempRadius = v),
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: tempSort,
                        onChanged: (v) => setX(() => tempSort = v ?? true),
                      ),
                      const Text("Sort by distance (closest first)"),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategories = tempCats;
                              selectedUrgencies = tempUrg;
                              radiusKm = tempRadius;
                              sortByDistance = tempSort;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //--------------------------------------------------
  // MY REQUESTS STREAM
  //--------------------------------------------------
  Stream<List<HelpRequest>> myRequestsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection("help_requests")
        .where("userId", isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((e) => HelpRequest.fromDoc(e)).toList();

          // newest first
          list.sort(
            (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
              a.createdAt ?? DateTime(2000),
            ),
          );

          return list;
        });
  }

  //--------------------------------------------------
  // BOTTOM NAV BAR (FIXED)
  //--------------------------------------------------
  Widget _bottomNav() {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 70 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAF1FF), // slightly tinted white
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: CupertinoIcons.house_fill,
            label: "Home",
            active: index == 0,
            onTap: () => setState(() => index = 0),
          ),
          StreamBuilder<int>(
            stream: _unreadStream(),
            builder: (_, snap) {
              final count = snap.data ?? 0;
              return _navItem(
                icon: CupertinoIcons.chat_bubble_fill,
                label: "Chat",
                active: index == 1,
                badge: count,
                onTap: () => setState(() => index = 1),
              );
            },
          ),
          _navItem(
            icon: CupertinoIcons.person_crop_circle_fill,
            label: "Profile",
            active: index == 2,
            onTap: () => setState(() => index = 2),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    final color = active ? const Color(0xFF3474F6) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(icon, size: 24, color: color),
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),

          if (badge > 0)
            Positioned(
              right: 22,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? "99+" : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
