// lib/screens/settingsscreen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool shareLocation = false;
  bool preciseLocation = false;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      shareLocation = prefs.getBool("shareLocation") ?? false;
      preciseLocation = prefs.getBool("preciseLocation") ?? false;
      darkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("shareLocation", shareLocation);
    await prefs.setBool("preciseLocation", preciseLocation);
    await prefs.setBool("darkMode", darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Privacy & Security"),

          _switchTile(
            title: "Share Location",
            subtitle: "Show your location to others",
            value: shareLocation,
            onChanged: (v) {
              setState(() => shareLocation = v);
              _savePrefs();
            },
          ),

          _switchTile(
            title: "Precise Location",
            subtitle: "Use exact location data",
            value: preciseLocation,
            onChanged: (v) {
              setState(() => preciseLocation = v);
              _savePrefs();
            },
          ),

          const SizedBox(height: 20),
          _sectionTitle("Appearance"),

          _switchTile(
            title: "Dark Mode",
            subtitle: "Enable dark theme",
            value: darkMode,
            onChanged: (v) {
              setState(() => darkMode = v);
              _savePrefs();
            },
          ),

          const SizedBox(height: 20),
          _sectionTitle("Support"),

          _tapTile(
            title: "Help Center",
            icon: Icons.help_outline,
            onTap: () {},
          ),

          _tapTile(
            title: "Privacy Policy",
            icon: Icons.privacy_tip_outlined,
            onTap: () {},
          ),

          _tapTile(
            title: "Terms of Service",
            icon: Icons.description_outlined,
            onTap: () {},
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "Version 1.0.0",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black, // FIXED — PURE BLACK
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: Colors.blue), // FIXED — real color
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black, // FIXED
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54, // FIXED (not faded grey)
                  ),
                ),
              ],
            ),
          ),

          Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
        ],
      ),
    );
  }

  Widget _tapTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.blue), // FIXED COLOR
            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // FIXED TEXT COLOR
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
