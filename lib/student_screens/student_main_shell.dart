// --- Student Main Shell (Bottom Navigation) ----------------------------------
import 'package:flutter/material.dart';
import '../db.dart';
import 'downloaded_materials.dart';
import 'student_dashboard.dart';
import 'student_catalog.dart';
import 'student_profile.dart';
import 'student_session_tracker.dart';

class StudentMainShell extends StatefulWidget {
  const StudentMainShell({super.key});

  @override
  State<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends State<StudentMainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _pages = const [
    StudentDashboard(),
    StudentCatalog(),
    DownloadedMaterials(),
    StudentProfile(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final studentId = StudentSession.studentId;
    if (studentId == null) return;

    if (state == AppLifecycleState.resumed) {
      StudentSessionTracker.startSession(studentId);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      StudentSessionTracker.endCurrentSession(studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF5B6FF5),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
