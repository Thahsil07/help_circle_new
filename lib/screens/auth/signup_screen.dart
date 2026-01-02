import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _signup() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();

    // ---------- VALIDATION ----------
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _show("All fields are required");
      return;
    }

    if (!email.contains("@")) {
      _show("Enter a valid email");
      return;
    }

    if (password.length < 6) {
      _show("Password must be at least 6 characters");
      return;
    }

    try {
      // 1️⃣ CREATE AUTH USER
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _show("Signup failed");
        return;
      }

      // 2️⃣ UPDATE DISPLAY NAME
      await user.updateDisplayName(name);

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": name,
        "email": email,
        "photoUrl": "",
        "bio": "",
        "location": "",

        "helpsGiven": 0,
        "helpsReceived": 0,
        "ratingCount": 0,
        "ratingTotal": 0,
        "avgRating": 0.0,
        "badges": [],

        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // 4️⃣ 🔥 FORCE LOGOUT (CRITICAL)
      // await FirebaseAuth.instance.signOut();

      // 5️⃣ GO TO LOGIN SCREEN
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // go back to LoginScreen
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          _show("Email already registered");
          break;
        case "invalid-email":
          _show("Invalid email format");
          break;
        case "weak-password":
          _show("Weak password (min 6 chars)");
          break;
        default:
          _show(e.message ?? "Signup failed");
      }
    } catch (e) {
      _show("Something went wrong");
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 60,
                    color: Color(0xFF3474F6),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  "Create Account",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Join the community and start helping",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                _input(
                  controller: _name,
                  hint: "Full Name",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 16),

                _input(
                  controller: _email,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 16),

                _input(
                  controller: _password,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: true,
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3474F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF3474F6),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.black87),
        controller: controller,
        obscureText: obscure,

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.black54),

          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
