import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'IntroScreen.dart';
import 'LoginPage.dart';
import 'PageController.dart';
import 'models/AuthState.dart';
import 'main.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0;
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isInitializing = true;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Show splash screen immediately
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _opacity = 1);
      _controller.forward();
    }

    // Initialize all services while splash is showing
    try {
      if (mounted) {
        setState(() => _statusText = 'Loading services...');
      }
      await initializeApp();
      
      if (mounted) {
        setState(() => _statusText = 'Almost ready...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Continue anyway - app can still work with partial initialization
    }

    if (!mounted) return;

    // Check if user has seen intro and login before
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final hasSkippedIntro = prefs.getBool('has_skipped_intro') ?? false;
    final hasSkippedLogin = prefs.getBool('has_skipped_login') ?? false;

    if (hasSkippedIntro && (isLoggedIn || AuthState.isLoggedIn.value)) {
      // User has seen intro/login before and is logged in - go directly to home
      Get.offAll(() => const NavbarController());
    } else if (hasSkippedIntro && hasSkippedLogin) {
      // User has skipped login before - go directly to home (they can login from profile if needed)
      Get.offAll(() => const NavbarController());
    } else if (hasSkippedIntro) {
      // User has seen intro before but not logged in and hasn't skipped login - show login (skip intro)
      Get.offAll(() => LoginScreen());
    } else {
      // First time - show intro screen
      Get.offAll(() => const IntroScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B1020),
              Color(0xFF1C2E4A),
              Color(0xFF2B3A8F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.35),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/splashWhite.png",
                      width: 180,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isInitializing)
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        child: Lottie.asset(
                          'assets/quickLoad.json',
                          width: 105,
                          height: 105,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      // const SizedBox(
                      //   width: 30,
                      //   height: 30,
                      //   child: CircularProgressIndicator(
                      //     strokeWidth: 2.5,
                      //     valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                      // Text(
                      //   _statusText,
                      //   style: const TextStyle(
                      //     color: Colors.white70,
                      //     fontSize: 14,
                      //     letterSpacing: 0.5,
                      //   ),
                      // ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
