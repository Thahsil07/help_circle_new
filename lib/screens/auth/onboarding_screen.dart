// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:help_circle/screens/auth/login_screen.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _controller = PageController();
//   int _currentPage = 0;

//   final List<Map<String, dynamic>> pages = [
//     {
//       "icon": Icons.favorite_border,
//       "iconColor": Color(0xFF3474F6),
//       "bgColor": Color(0xFFE4EEFF),
//       "title": "Connect & Help",
//       "subtitle":
//           "Join a community of volunteers ready to help and people who need assistance in your neighborhood",
//     },
//     {
//       "icon": Icons.place_outlined,
//       "iconColor": Color(0xFF2CAB63),
//       "bgColor": Color(0xFFE2F5EA),
//       "title": "Find Help Nearby",
//       "subtitle":
//           "Discover people who need help close to you. Every small act of kindness makes a big difference",
//     },
//     {
//       "icon": Icons.shield_outlined,
//       "iconColor": Color(0xFFF2C94C),
//       "bgColor": Color(0xFFFFF6DC),
//       "title": "Safe & Secure",
//       "subtitle":
//           "Verified profiles, secure messaging, and community ratings ensure a safe helping experience",
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5FAFF),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: PageView.builder(
//                 controller: _controller,
//                 itemCount: pages.length,
//                 onPageChanged: (index) {
//                   setState(() => _currentPage = index);
//                 },
//                 itemBuilder: (context, index) {
//                   return Column(
//                     children: [
//                       const Spacer(),

//                       Container(
//                         padding: const EdgeInsets.all(30),
//                         decoration: BoxDecoration(
//                           color: pages[index]["bgColor"],
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           pages[index]["icon"],
//                           size: 70,
//                           color: pages[index]["iconColor"],
//                         ),
//                       ),

//                       const SizedBox(height: 30),

//                       Text(
//                         pages[index]["title"],
//                         textAlign: TextAlign.center,
//                         style: GoogleFonts.inter(
//                           fontSize: 22,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black87,
//                         ),
//                       ),

//                       const SizedBox(height: 15),

//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 25),
//                         child: Text(
//                           pages[index]["subtitle"],
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.cabin(
//                             fontSize: 18,
//                             color: Colors.black54,
//                           ),
//                         ),
//                       ),

//                       const Spacer(),
//                     ],
//                   );
//                 },
//               ),
//             ),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(
//                 pages.length,
//                 (dotIndex) => AnimatedContainer(
//                   duration: const Duration(milliseconds: 250),
//                   margin: const EdgeInsets.symmetric(horizontal: 4),
//                   width: _currentPage == dotIndex ? 22 : 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: _currentPage == dotIndex
//                         ? const Color(0xFF3474F6)
//                         : Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 15),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_currentPage == pages.length - 1) {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (_) => const LoginScreen()),
//                       );
//                     } else {
//                       _controller.nextPage(
//                         duration: const Duration(milliseconds: 400),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3474F6),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: Text(
//                     _currentPage == pages.length - 1 ? "Get Started" : "Next",
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 25),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:help_circle_new/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ADDED

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "icon": Icons.favorite_border,
      "iconColor": Color(0xFF3474F6),
      "bgColor": Color(0xFFE4EEFF),
      "title": "Connect & Help",
      "subtitle":
          "Join a community of volunteers ready to help and people who need assistance in your neighborhood",
    },
    {
      "icon": Icons.place_outlined,
      "iconColor": Color(0xFF2CAB63),
      "bgColor": Color(0xFFE2F5EA),
      "title": "Find Help Nearby",
      "subtitle":
          "Discover people who need help close to you. Every small act of kindness makes a big difference",
    },
    {
      "icon": Icons.shield_outlined,
      "iconColor": Color(0xFFF2C94C),
      "bgColor": Color(0xFFFFF6DC),
      "title": "Safe & Secure",
      "subtitle":
          "Verified profiles, secure messaging, and community ratings ensure a safe helping experience",
    },
  ];

  // ✅ SAVE ONBOARDING DONE
  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("onboarding_done", true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: pages[index]["bgColor"],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pages[index]["icon"],
                          size: 70,
                          color: pages[index]["iconColor"],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        pages[index]["title"],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          pages[index]["subtitle"],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cabin(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (dotIndex) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == dotIndex ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == dotIndex
                        ? const Color(0xFF3474F6)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == pages.length - 1) {
                      await _completeOnboarding();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3474F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1 ? "Get Started" : "Next",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
