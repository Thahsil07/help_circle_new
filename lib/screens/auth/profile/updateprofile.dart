// // lib/screens/profile/updateprofile.dart

// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// class UpdateProfileScreen extends StatefulWidget {
//   final String userId;
//   final bool openImagePickerOnly;

//   const UpdateProfileScreen({
//     super.key,
//     required this.userId,
//     this.openImagePickerOnly = false,
//   });

//   @override
//   State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
// }

// class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
//   final TextEditingController nameCtrl = TextEditingController();
//   final TextEditingController bioCtrl = TextEditingController();

//   bool loading = false;
//   File? _pickedImage;
//   double uploadProgress = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();

//     if (widget.openImagePickerOnly) {
//       WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
//     }
//   }

//   Future<void> _loadUser() async {
//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.userId)
//         .get();

//     if (!doc.exists) return;

//     final data = doc.data()!;
//     nameCtrl.text = data['name'] ?? '';
//     bioCtrl.text = data['bio'] ?? '';
//   }

//   // ---------------- PICK IMAGE ----------------
//   Future<void> _pickImage() async {
//     final XFile? file = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 90,
//     );

//     if (file == null) return;

//     final compressed = await _compressFile(File(file.path));
//     setState(() => _pickedImage = compressed);

//     if (widget.openImagePickerOnly) {
//       await _uploadAndSave();
//       if (mounted) Navigator.pop(context);
//     }
//   }

//   // ---------------- COMPRESS IMAGE ----------------
//   Future<File> _compressFile(File file) async {
//     final dir = await getTemporaryDirectory();
//     final targetPath = p.join(
//       dir.path,
//       'cmp_${DateTime.now().millisecondsSinceEpoch}.jpg',
//     );

//     final result = await FlutterImageCompress.compressAndGetFile(
//       file.absolute.path,
//       targetPath,
//       quality: 75,
//       minWidth: 800,
//       minHeight: 800,
//       keepExif: true,
//     );

//     return File(result?.path ?? file.path);
//   }

//   // ---------------- UPLOAD IMAGE (SAFE STATIC PATH) ----------------
//   Future<String?> _uploadImage(File file) async {
//     final uid = widget.userId;

//     // ALWAYS same path
//     final ref = FirebaseStorage.instance.ref().child(
//       "user_photos/$uid/profile.jpg",
//     );

//     final uploadTask = ref.putFile(file);

//     uploadTask.snapshotEvents.listen((TaskSnapshot snap) {
//       double progress = snap.bytesTransferred / snap.totalBytes;
//       setState(() => uploadProgress = progress);
//     });

//     final snapshot = await uploadTask.whenComplete(() {});
//     final url = await snapshot.ref.getDownloadURL();

//     if (mounted) setState(() => uploadProgress = 0.0);

//     return url;
//   }

//   // ---------------- UPLOAD ONLY ----------------
//   Future<void> _uploadAndSave() async {
//     if (_pickedImage == null) return;

//     setState(() => loading = true);

//     try {
//       final url = await _uploadImage(_pickedImage!);

//       if (url != null) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .set({'photoUrl': url}, SetOptions(merge: true));

//         await _addHistory("Updated profile picture", "Changed profile photo");
//       }
//     } catch (e) {
//       _showError("Upload failed: $e");
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   // ---------------- SAVE FULL PROFILE ----------------
//   Future<void> _saveProfile() async {
//     final name = nameCtrl.text.trim();
//     final bio = bioCtrl.text.trim();

//     setState(() => loading = true);

//     try {
//       final Map<String, dynamic> update = {'name': name, 'bio': bio};

//       if (_pickedImage != null) {
//         final url = await _uploadImage(_pickedImage!);
//         if (url != null) update['photoUrl'] = url;
//       }

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .set(update, SetOptions(merge: true));

//       await _addHistory('Updated profile', 'Name or bio updated');

//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       _showError("Failed to save: $e");
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   // ---------------- ERROR SNACKBAR ----------------
//   void _showError(String msg) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//     }
//   }

//   // ---------------- HISTORY LOG ----------------
//   Future<void> _addHistory(String title, String subtitle) async {
//     final col = FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.userId)
//         .collection('history');

//     await col.add({
//       'title': title,
//       'subtitle': subtitle,
//       'dateText': _niceDateText(),
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//   }

//   String _niceDateText() {
//     final now = DateTime.now();
//     return "${now.day}-${now.month}-${now.year}";
//   }

//   // ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FAFF),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF3474F6),
//         elevation: 0,
//         title: Text(
//           'Edit Profile',
//           style: GoogleFonts.inter(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         actions: [
//           if (_pickedImage != null)
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: Center(
//                 child: Text(
//                   '${(uploadProgress * 100).toStringAsFixed(0)}%',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//         ],
//       ),

//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),

//             Center(
//               child: Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 48,
//                     backgroundColor: Colors.grey.shade200,
//                     backgroundImage: _pickedImage != null
//                         ? FileImage(_pickedImage!) as ImageProvider
//                         : null,
//                     child: _pickedImage == null
//                         ? const Icon(
//                             Icons.person,
//                             size: 50,
//                             color: Colors.black54,
//                           )
//                         : null,
//                   ),

//                   Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: GestureDetector(
//                       onTap: _pickImage,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               blurRadius: 6,
//                               color: Colors.black.withOpacity(0.15),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(Icons.camera_alt, size: 20),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             Text(
//               "Full Name",
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 6),
//             _inputField(nameCtrl, "Enter your name"),

//             const SizedBox(height: 20),

//             Text(
//               "Bio",
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 6),
//             _inputField(bioCtrl, "Tell something about yourself", maxLines: 4),

//             const SizedBox(height: 30),

//             ElevatedButton(
//               onPressed: loading ? null : _saveProfile,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF3474F6),
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//               child: loading
//                   ? const SizedBox(
//                       height: 24,
//                       width: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3,
//                         color: Colors.white,
//                       ),
//                     )
//                   : Text(
//                       'Save Changes',
//                       style: GoogleFonts.inter(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//             ),

//             const SizedBox(height: 14),

//             if (uploadProgress > 0 && uploadProgress < 1)
//               LinearProgressIndicator(
//                 value: uploadProgress,
//                 minHeight: 6,
//                 backgroundColor: Colors.grey.shade200,
//                 color: const Color(0xFF3474F6),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------- INPUT FIELD ----------------
//   Widget _inputField(
//     TextEditingController ctrl,
//     String hint, {
//     int maxLines = 1,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//             color: Colors.black.withOpacity(0.06),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: ctrl,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           hintText: hint,
//           border: InputBorder.none,
//           hintStyle: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
//         ),
//       ),
//     );
//   }
// }
// lib/screens/profile/updateprofile.dart

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class UpdateProfileScreen extends StatefulWidget {
  final String userId;
  final bool openImagePickerOnly;

  const UpdateProfileScreen({
    super.key,
    required this.userId,
    this.openImagePickerOnly = false,
  });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();

  bool loading = false;
  File? _pickedImage;
  double uploadProgress = 0.0;

  // ⚠️ PUT YOUR CLOUDINARY DETAILS HERE
  final String cloudName = "duaagvv2m";
  final String uploadPreset = "profileimage";

  @override
  void initState() {
    super.initState();
    _loadUser();

    if (widget.openImagePickerOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    nameCtrl.text = data['name'] ?? '';
    bioCtrl.text = data['bio'] ?? '';
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (file == null) return;

    final compressed = await _compressFile(File(file.path));
    setState(() => _pickedImage = compressed);

    if (widget.openImagePickerOnly) {
      await _uploadAndSave();
      if (mounted) Navigator.pop(context);
    }
  }

  // ---------------- COMPRESS IMAGE ----------------
  Future<File> _compressFile(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'cmp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
      keepExif: true,
    );

    return File(result?.path ?? file.path);
  }

  // ---------------- CLOUDINARY UPLOAD ----------------
  Future<String?> uploadToCloudinary(File file) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonRes = json.decode(resBody);
      return jsonRes["secure_url"];
    } else {
      print("Cloudinary Error: $resBody");
      return null;
    }
  }

  // ---------------- UPLOAD ONLY ----------------
  Future<void> _uploadAndSave() async {
    if (_pickedImage == null) return;

    setState(() => loading = true);

    try {
      final url = await uploadToCloudinary(_pickedImage!);

      if (url != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({'photoUrl': url}, SetOptions(merge: true));

        await _addHistory("Updated profile picture", "Changed profile photo");
      }
    } catch (e) {
      _showError("Upload failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- SAVE FULL PROFILE ----------------
  Future<void> _saveProfile() async {
    final name = nameCtrl.text.trim();
    final bio = bioCtrl.text.trim();

    setState(() => loading = true);

    try {
      final Map<String, dynamic> update = {'name': name, 'bio': bio};

      if (_pickedImage != null) {
        final url = await uploadToCloudinary(_pickedImage!);
        if (url != null) update['photoUrl'] = url;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(update, SetOptions(merge: true));

      await _addHistory('Updated profile', 'Name or bio updated');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Failed to save: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- HISTORY SYSTEM ----------------
  Future<void> _addHistory(String title, String subtitle) async {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('history');

    await col.add({
      'title': title,
      'subtitle': subtitle,
      'dateText': _niceDateText(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _niceDateText() {
    final now = DateTime.now();
    return "${now.day}-${now.month}-${now.year}";
  }

  // ---------------- ERROR MESSAGE ----------------
  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3474F6),
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : null,
                    child: _pickedImage == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.black54,
                          )
                        : null,
                  ),

                  // Camera Button
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.15),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Full Name",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _inputField(nameCtrl, "Enter your name"),

            const SizedBox(height: 20),

            Text(
              "Bio",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _inputField(bioCtrl, "Tell something about yourself", maxLines: 4),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3474F6),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _inputField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}
