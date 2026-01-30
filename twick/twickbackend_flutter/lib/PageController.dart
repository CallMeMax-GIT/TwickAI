import 'dart:ui';

import 'package:flutter/material.dart';
import 'CategoriesPage.dart';
import 'CreateTask.dart';
import 'HomePage.dart';
import 'services/NotificationService.dart';

class NavbarController extends StatefulWidget {
  const NavbarController({super.key});

  @override
  State<NavbarController> createState() => _NavbarControllerState();
}

class _NavbarControllerState extends State<NavbarController> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _lastHomeIndex = 0;
  int _lastCategoriesIndex = 0;
  // final WakeWordService _wakeWordService = WakeWordService();

  List<Widget> get _pages {
    // Only update key when page becomes visible
    if (_currentIndex == 0) {
      _lastHomeIndex++;
    }
    if (_currentIndex == 2) {
      _lastCategoriesIndex++;
    }
    
    return [
      HomePage(key: ValueKey('home_$_lastHomeIndex')),
    CreateTaskPage(),
      CategoriesPage(key: ValueKey('categories_$_lastCategoriesIndex')),
  ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _initializeWakeWord();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app comes to foreground, check and reschedule any missed recurring notifications
      NotificationService.checkAndRescheduleRecurringTasks();
    }
  }

  // Future<void> _initializeWakeWord() async {
  //   await _wakeWordService.initialize();
  //   // Start listening when on HomePage
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (mounted && _currentIndex == 0) {
  //       _wakeWordService.startListening(context);
  //     }
  //   });
  // }

  // @override
  // void dispose() {
  //   _wakeWordService.stopListening();
  //   super.dispose();
  // }

  void _onTap(int index) {
    if (index == 1) {
      openAssistantTab(context);
      return;
    }
    
    // Manage wake word listening based on page
    // if (index == 0) {
    //   // Starting HomePage - start listening
    //   _wakeWordService.startListening(context);
    // } else {
    //   // Leaving HomePage - stop listening
    //   _wakeWordService.stopListening();
    // }
    
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.grey[50],toolbarHeight: 0,),
      backgroundColor: Colors.grey[50],
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
            decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 248, 248),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
            ),
            ],
          ),
      child: SafeArea(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Expanded(
              child: _NavItem(
                  icon: Icons.home_rounded,
                label: 'HOME',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
            ),
        
            // Spacer for center button - matches button width (70)
            const SizedBox(width: 70),
        
            Expanded(
              child: _NavItem(
                icon: Icons.category_rounded,
                label: 'CATEGORIES',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
        ),
        // Center Create Button - overlapping the top edge
        Positioned(
          top: -20, // Overlap the top edge
          child: GestureDetector(
                  onTap: () => onTap(1),
                  child: Container(
              height: 70,
              width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6), // Blue
                    Color(0xFF1E40AF), // Dark Blue
                    Color(0xFF000000), // Black
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                    color: const Color(0xFF1E40AF).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                size: 25,
                ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Icon(
            icon,
            size: 24,
            color: isActive ? Colors.blueAccent : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.blueAccent : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
