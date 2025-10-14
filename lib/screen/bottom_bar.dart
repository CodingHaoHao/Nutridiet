import 'package:flutter/material.dart';
import 'homepage.dart';
import 'logging_page.dart';
import 'assistant_page.dart';
import 'profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    LoggingPage(),
    AssistantPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF2B3A67); 
    const Color inactiveColor = Colors.black54;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            showUnselectedLabels: true,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            onTap: (idx) => setState(() => _currentIndex = idx),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_outlined),
                activeIcon: Icon(Icons.restaurant_rounded),
                label: 'Logging',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_outlined),
                activeIcon: Icon(Icons.smart_toy_rounded),
                label: 'Assistant',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
