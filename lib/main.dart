// --- Main Entry Point --------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'teacher_screens/teacher_login.dart';
import 'admin_screens/admin_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ldwrvxijjrxdffxrrknj.supabase.co',
    anonKey: 'sb_publishable_Zz4mhYdcKp_OMBeh9_rVhg_VbT5AbuC',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSD E-Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6FF5)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'RSD E-Learning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF5B6FF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 70,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Welcome to RSD E-Learning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'A secure e-learning platform supporting students, teachers, and administrators through structured digital education.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            _LoginCard(
              icon: Icons.admin_panel_settings,
              title: 'Admin Login',
              subtitle: 'Manage teachers, students, courses, payments and system settings.',
              buttonText: 'Continue as Admin',
              color: const Color(0xFF212529),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLogin()),
                );
              },
            ),

            const SizedBox(height: 16),

            _LoginCard(
              icon: Icons.person,
              title: 'Teacher Login',
              subtitle: 'Create courses, upload materials, manage lessons and assessments.',
              buttonText: 'Continue as Teacher',
              color: const Color(0xFF5B6FF5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherLogin()),
                );
              },
            ),

           // const SizedBox(height: 40),

           // const SizedBox(height: 16),

            //_LoginCard(
            //  icon: Icons.school,
            //  title: 'Student Login',
            //  subtitle: 'Enroll in courses, access materials and track progress.',
            //  buttonText: 'Continue as Student',
            //  color: Colors.green,
            //  onTap: () {
            //    Navigator.push(
            //      context,
            //      MaterialPageRoute(builder: (_) => const StudentLogin()),
            //    );
            //  },
           // ),

            const Text(
              '© 2025 RSD E-Learning. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color color;
  final VoidCallback onTap;

  const _LoginCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onTap,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}