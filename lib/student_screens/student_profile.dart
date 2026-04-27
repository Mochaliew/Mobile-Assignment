// --- Student Profile (Placeholder) -------------------------------------------
import 'package:flutter/material.dart';
import '../DB.dart';
import '../teacher_screens/teacher_login.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  void _logout(BuildContext context) {
    StudentSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F7F9),
      body: const Center(child: Text('Profile — Coming Soon')),
    );
  }
}
