import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../DB.dart';
import 'admin_login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  int totalStudents = 0;
  int totalTeachers = 0;
  int totalCourses = 0;
  int pendingCourses = 0;

  List<dynamic> latestLogs = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => _isLoading = true);

    try {
      final students = await supabase.from('students').select();
      final teachers = await supabase.from('teachers').select();
      final courses = await supabase.from('courses').select();

      final pending = await supabase
          .from('courses')
          .select()
          .eq('is_approved', false)
          .eq('is_rejected', false);

      final logs = await supabase
          .from('audit_logs')
          .select()
          .order('timestamp', ascending: false)
          .limit(5);

      setState(() {
        totalStudents = students.length;
        totalTeachers = teachers.length;
        totalCourses = courses.length;
        pendingCourses = pending.length;
        latestLogs = logs;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void logout() {
    AdminSession.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFF5B6FF5),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchDashboard),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${AdminSession.adminName ?? ''}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  statCard("Students", totalStudents.toString(), Colors.blue),
                  statCard("Teachers", totalTeachers.toString(), Colors.green),
                  statCard("Courses", totalCourses.toString(), Colors.orange),
                  statCard("Pending", pendingCourses.toString(), Colors.red),
                ],
              ),

              const SizedBox(height: 20),

              const Text("Latest Activities",
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              Card(
                child: Column(
                  children: latestLogs.map((log) {
                    return ListTile(
                      title: Text(log['action'] ?? ''),
                      subtitle: Text(log['timestamp'] ?? ''),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 5),
            Text(title),
          ],
        ),
      ),
    );
  }
}