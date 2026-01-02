import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:help_circle_new/screens/home/requests/helpreq.dart';

class CreateRequestScreen extends StatefulWidget {
  final HelpRequest? existingRequest;
  const CreateRequestScreen({super.key, this.existingRequest});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen>
    with TickerProviderStateMixin {
  final titleC = TextEditingController();
  final descC = TextEditingController();
  final locationC = TextEditingController();

  DateTime? selectedDate;
  String? selectedImagePath;
  String? uploadedImageUrl;
  String? category;

  String? urgency;
  double? lat;
  double? lng;

  bool saving = false;
  bool imageUploading = false;

  // put your cloudinary config here
  final String cloudName = "duaagvv2m";
  final String uploadPreset = "requestimages";

  // category list shown as chips
  final List<String> _categories = [
    "Blood Donation",
    "Shopping",
    "Moving",
    "Medical",
    "Transport",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadIfEditing();
  }

  @override
  void dispose() {
    titleC.dispose();
    descC.dispose();
    locationC.dispose();
    super.dispose();
  }

  void _loadIfEditing() {
    final r = widget.existingRequest;
    if (r == null) return;
    if (lat == null || lng == null) {
      locationC.text = '';
    }

    titleC.text = r.title;
    descC.text = r.description;
    locationC.text = r.locationText;
    uploadedImageUrl = r.imageUrl;
    category = r.category;
    urgency = r.urgency.isNotEmpty
        ? (r.urgency[0].toUpperCase() + r.urgency.substring(1))
        : null;
    lat = r.latitude;
    lng = r.longitude;
    selectedDate = r.needDate;
  }

  // ---------------- IMAGE UPLOAD ----------------
  Future<void> _uploadToCloudinary(String filePath) async {
    setState(() => imageUploading = true);
    try {
      final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.fields["upload_preset"] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath("file", filePath));

      final response = await request.send();
      final resString = await response.stream.bytesToString();
      final data = json.decode(resString);

      if (data is Map && data["secure_url"] != null) {
        uploadedImageUrl = data["secure_url"];
      } else {
        _err("Image upload failed");
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      _err("Image upload error");
    } finally {
      if (mounted) setState(() => imageUploading = false);
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          selectedImagePath = picked.path;
          uploadedImageUrl = null;
        });
        await _uploadToCloudinary(picked.path);
      }
    } catch (e) {
      debugPrint("_pickImage error: $e");
      _err("Failed to pick image");
    }
  }

  void _removeImage() {
    setState(() {
      selectedImagePath = null;
      uploadedImageUrl = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image removed')));
  }

  // ---------------- LOCATION ----------------
  Future<void> _pickLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _err('Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;

      final places = await placemarkFromCoordinates(lat!, lng!);
      final p = places.isNotEmpty ? places.first : null;

      final loc = [
        p?.locality,
        p?.subAdministrativeArea,
        p?.administrativeArea,
      ].where((e) => e != null && e!.trim().isNotEmpty).join(', ');

      locationC.text = loc.isEmpty ? 'Unknown Location' : loc;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('pick location error: $e');
      _err('Unable to fetch location');
    }
  }

  // ---------------- MANUAL LOCATION VALIDATION ----------------
  Future<void> _validateManualLocation(String query) async {
    if (query.trim().isEmpty) {
      _err("Enter a location");
      return;
    }

    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(query)}"
        "&format=json&limit=1",
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'help_circle_app'},
      );

      final data = json.decode(res.body) as List;

      if (data.isEmpty) {
        _err("Location not found");
        return;
      }

      lat = double.parse(data[0]['lat']);
      lng = double.parse(data[0]['lon']);

      setState(() {});
    } catch (e) {
      debugPrint("Manual location error: $e");
      _err("Unable to verify location");
    }
  }

  // ---------------- SAVE ----------------
  Future<void> _save() async {
    if (imageUploading) {
      _err('Please wait for image upload to finish');
      return;
    }
    if (titleC.text.trim().isEmpty ||
        descC.text.trim().isEmpty ||
        urgency == null ||
        category == null ||
        locationC.text.trim().isEmpty ||
        selectedDate == null) {
      _err('Please fill all fields');
      return;
    }

    // 🔥 If user typed location manually, validate it
    if (lat == null || lng == null) {
      await _validateManualLocation(locationC.text.trim());
      if (lat == null || lng == null) {
        _err('Enter a valid location name');
        return;
      }
    }

    setState(() => saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final createdByName = userDoc.data()?['name'] ?? 'User';
      final photoUrl = userDoc.data()?['photoUrl'] ?? '';

      final baseData = {
        'title': titleC.text.trim(),
        'description': descC.text.trim(),
        'locationText': locationC.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'urgency': _normalizeUrgency(urgency!),
        'category': category,
        'imageUrl': uploadedImageUrl,
        'userId': uid,
        'createdByName': createdByName,
        'createdByPhotoUrl': photoUrl,
        'needDate': Timestamp.fromDate(selectedDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final ref = FirebaseFirestore.instance.collection('help_requests');

      if (widget.existingRequest == null) {
        // Create new request with all required fields
        await ref.add({
          ...baseData,
          'status': 'pending',
          'acceptedBy': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing request but preserve status/acceptedBy if missing
        await ref.doc(widget.existingRequest!.id).set({
          ...baseData,
          'status': widget.existingRequest!.status.isNotEmpty
              ? widget.existingRequest!.status
              : 'pending',
          'acceptedBy': widget.existingRequest!.acceptedBy ?? '',
          'createdAt': widget.existingRequest!.createdAt != null
              ? Timestamp.fromDate(widget.existingRequest!.createdAt!)
              : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Save request error: $e\n$st');
      _err('Failed to save request');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _err(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  String _normalizeUrgency(String u) {
    final s = u.toLowerCase();
    if (s.contains('high')) return 'high';
    if (s.contains('medium')) return 'medium';
    return 'low';
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 62, 88, 235),
          width: 1.6,
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4F8DFF), // lighter
                    Color(0xFF3474F6), // primary splash color
                  ],
                )
              : null,

          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.12),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingRequest != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4F8DFF), Color(0xFF3474F6)],
            ),
          ),
        ),

        title: Text(
          editing ? 'Update Request' : 'Create Request',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Image upload
            Text(
              'Add Photo (Optional)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (selectedImagePath == null && uploadedImageUrl == null)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to choose image',
                                style: GoogleFonts.inter(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      else if (selectedImagePath != null)
                        Image.file(File(selectedImagePath!), fit: BoxFit.cover)
                      else if (uploadedImageUrl != null)
                        Image.network(uploadedImageUrl!, fit: BoxFit.cover)
                      else
                        const SizedBox.shrink(),

                      if (imageUploading)
                        const Center(child: CircularProgressIndicator()),

                      if (selectedImagePath != null || uploadedImageUrl != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),

                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Category',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final c = _categories[i];
                        final selected = (category != null && category == c);
                        return _chip(
                          c,
                          selected,
                          () => setState(() => category = c),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Title',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleC,
                    decoration: _input('Eg: Need help moving furniture'),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urgency',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: urgency,
                              decoration: _input('Select urgency'),
                              items: ['High', 'Medium', 'Low']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => urgency = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  initialDate: selectedDate ?? DateTime.now(),
                                );
                                if (picked != null)
                                  setState(() => selectedDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedDate == null
                                          ? 'dd-mm-yyyy'
                                          : '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}',
                                      style: GoogleFonts.inter(
                                        color: selectedDate == null
                                            ? Colors.black45
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Description',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descC,
                    maxLines: 4,
                    decoration: _input(
                      'Add details that help responders understand',
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Location',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: locationC,
                          decoration: _input('Type location manually'),
                          onSubmitted: (value) {
                            _validateManualLocation(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _pickLocation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4F8DFF),
                                Color.fromARGB(255, 33, 102, 241),
                              ],
                            ),

                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3474F6),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(
                                  editing ? 'Update Request' : 'Submit Request',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}
