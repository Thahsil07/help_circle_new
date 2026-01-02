import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart';

class RatingScreen extends StatefulWidget {
  final String targetUserId;
  final String targetName;
  final String requestId;

  const RatingScreen({
    super.key,
    required this.targetUserId,
    required this.targetName,
    required this.requestId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 0;
  String _review = '';
  final List<String> _tags = [];
  bool _submitting = false;

  Widget _star(int i) {
    return GestureDetector(
      onTap: () => setState(() => _stars = i),
      child: Icon(
        i <= _stars ? Icons.star : Icons.star_border,
        size: 36,
        color: Colors.amber,
      ),
    );
  }

  Widget _tagChip(String label) {
    final selected = _tags.contains(label);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black, // FIXED TEXT
        ),
      ),
      selected: selected,
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      onSelected: (v) {
        setState(() {
          if (v) {
            _tags.add(label);
          } else {
            _tags.remove(label);
          }
        });
      },
    );
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final ratingsRef = FirebaseFirestore.instance.collection('ratings');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId);

      // 1️⃣ CREATE RATING (ONCE)
      await ratingsRef.add({
        'by': uid,
        'to': widget.targetUserId,
        'requestId': widget.requestId,
        'stars': _stars,
        'review': _review,
        'tags': _tags,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ GET USER DATA
      final snap = await userRef.get();
      final data = snap.data()!;

      final int ratingCount = (data['ratingCount'] ?? 0) + 1;
      final int ratingTotal = (data['ratingTotal'] ?? 0) + _stars;
      final double avg = ratingTotal / ratingCount;

      final List badges = List.from(data['badges'] ?? []);

      if (ratingCount == 1 && !badges.contains("First Rating")) {
        badges.add("First Rating");
      }
      if (avg >= 4.0 && !badges.contains("Reliable")) {
        badges.add("Reliable");
      }

      // 3️⃣ SINGLE USER UPDATE (RULE SAFE)
      await userRef.update({
        'ratingCount': FieldValue.increment(1),
        'ratingTotal': FieldValue.increment(_stars),
        'avgRating': avg,
        'badges': badges,
      });
      // 🔥 UPDATE LEADERBOARD SCORE
      final helps = data['helpsGiven'] ?? 0;

      await userRef.update({'leaderboardScore': helps * 10 + avg});

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Rating error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit rating')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Rate Your Experience',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black, // FIXED
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                widget.targetName.isNotEmpty
                    ? widget.targetName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black, // FIXED
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.targetName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black, // FIXED
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (int i = 1; i <= 5; i++) _star(i)],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tagChip('Very helpful'),
                _tagChip('On time'),
                _tagChip('Friendly'),
                _tagChip('Professional'),
                _tagChip('Good communication'),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              maxLines: 4,
              onChanged: (v) => _review = v,
              style: const TextStyle(color: Colors.black), // FIXED TEXT
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                hintStyle: GoogleFonts.inter(
                  color: Colors.black54, // FIXED (not faded)
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3474F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Rating',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
