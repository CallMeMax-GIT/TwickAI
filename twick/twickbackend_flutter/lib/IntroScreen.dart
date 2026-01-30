import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'LoginPage.dart';


class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  

  void _next() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Get.to(() => LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return _IntroPage(
            data: _pages[index],
            index: index,
            currentIndex: _currentIndex,
            onNext: _next,
            isLast: index == _pages.length - 1,
            pageController: _pageController,
          );
        },
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final _IntroData data;
  final int index;
  final int currentIndex;
  final VoidCallback onNext;
  final bool isLast;
  final PageController pageController;

  const _IntroPage({
    required this.data,
    required this.index,
    required this.currentIndex,
    required this.onNext,
    required this.isLast,
    required this.pageController,
  });
  List<TextSpan> _buildTitleSpans(_IntroData data) {
    final parts = data.title.split(data.highlight);

    if (parts.length == 1) {
      return [TextSpan(text: data.title)];
    }

    return [
      TextSpan(text: parts[0]),
      TextSpan(
        text: data.highlight,
        style: const TextStyle(color: Colors.blueAccent),
      ),
      TextSpan(text: parts[1]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: data.background),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TWICK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                if (!isLast)
                  TextButton(
                    onPressed: (){
                      pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Animated Icon
            AnimatedScale(
              scale: isActive ? 1 : 0.8,
              duration: const Duration(milliseconds: 400),
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Icon(data.icon, size: 60, color: Colors.blueAccent),
              ),
            ),

            const SizedBox(height: 48),

            // Title
            AnimatedOpacity(
              opacity: isActive ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Colors.white,
                  ),
                  children: _buildTitleSpans(data),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            AnimatedSlide(
              offset: isActive ? Offset.zero : const Offset(0, 0.2),
              duration: const Duration(milliseconds: 400),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),

            const Spacer(),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: i == currentIndex ? 24 : 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ),

            if (isLast)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    Get.to(() => LoginScreen());
                  },
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _IntroData {
  final String title;
  final String highlight;
  final String description;
  final LinearGradient background;
  final IconData icon;

  _IntroData({
    required this.title,
    required this.highlight,
    required this.description,
    required this.background,
    required this.icon,
  });
}
final List<_IntroData> _pages = [
    _IntroData(
      title: 'Tasks, Done the\nSmart Way',
      highlight: 'Smart',
      description:
          'Experience the next generation of productivity. TWICK automates your schedule so you can focus on what matters.',
      background: const LinearGradient(
        colors: [Color(0xFF0B1020), Color(0xFF2B3A8F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.task_alt,
    ),
    _IntroData(
      title: 'Just Speak, TWICK\nUnderstands',
      highlight: 'TWICK',
      description:
          'No more typing. Just tell TWICK what’s on your mind, and it will organize your schedule instantly.',
      background: const LinearGradient(
        colors: [Color(0xFF071E22), Color(0xFF0FA3B1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      icon: Icons.mic_rounded,
    ),
    _IntroData(
      title: 'TWICK Thinks Ahead\nfor You',
      highlight: 'for You',
      description:
          'Our AI automatically shifts your priorities and sets reminders based on your workflow.',
      background: const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF1C2E4A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      icon: Icons.schedule_rounded,
    ),
  ];
