import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../DB.dart';
import 'admin_login.dart';
import 'course_approval.dart';
import 'manage_students.dart';
import 'category_management.dart';
import 'transactions.dart';
import 'system_settings.dart';
import 'audit_logs.dart';
import 'manage_teachers.dart';
import 'role_permission.dart';
import 'enrollment_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  int totalTeachers = 0;
  int totalStudents = 0;
  int totalCourses = 0;
  int pendingCourses = 0;
  int approvedCourses = 0;
  int rejectedCourses = 0;
  List<dynamic> latestLogs = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => _isLoading = true);

    try {
      final teachers = await supabase.from('teachers').select('teacher_id');
      final students = await supabase.from('students').select('student_id');
      final courses = await supabase.from('courses').select('course_id');

      final pending = await supabase
          .from('courses')
          .select('course_id')
          .eq('is_approved', false)
          .eq('is_rejected', false);

      final approved = await supabase
          .from('courses')
          .select('course_id')
          .eq('is_approved', true)
          .eq('is_rejected', false);

      final rejected = await supabase
          .from('courses')
          .select('course_id')
          .eq('is_rejected', true);

      final logs = await supabase
          .from('audit_logs')
          .select()
          .order('timestamp', ascending: false)
          .limit(5);

      setState(() {
        totalTeachers = teachers.length;
        totalStudents = students.length;
        totalCourses = courses.length;
        pendingCourses = pending.length;
        approvedCourses = approved.length;
        rejectedCourses = rejected.length;
        latestLogs = logs;
      });
    } catch (e) {
      showMessage('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF212529),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: fetchDashboard, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${AdminSession.adminName ?? 'Admin'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mobile Admin Module',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _StatCard('Total Teachers', totalTeachers, Colors.blue),
                  _StatCard('Total Students', totalStudents, Colors.green),
                  _StatCard('Total Courses', totalCourses, Colors.orange),
                  _StatCard('Pending Courses', pendingCourses, Colors.amber),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Course Status',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _MiniStatusCard(
                      title: 'Approved',
                      value: approvedCourses,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatusCard(
                      title: 'Rejected',
                      value: rejectedCourses,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Admin Functions',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _MenuCard(
                icon: Icons.school,
                title: 'Manage Courses',
                subtitle: 'Approve, publish and monitor courses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CourseApproval(),
                    ),
                  ).then((_) => fetchDashboard());
                },
              ),

              _MenuCard(
                icon: Icons.category,
                title: 'Manage Categories',
                subtitle: 'Create, edit, delete and restore categories',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagement()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.people,
                title: 'Manage Students',
                subtitle: 'Manage students, enrollments and accounts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageStudents()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.person,
                title: 'Manage Teachers',
                subtitle: 'Manage teacher accounts and status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageTeachers()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.settings,
                title: 'System Settings',
                subtitle: 'Platform branding, email and storage settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SystemSettingsScreen()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.payment,
                title: 'Transactions',
                subtitle: 'View student payments and enrollments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.history,
                title: 'Audit Logs',
                subtitle: 'View latest system activities',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.security,
                title: 'Role & Permission',
                subtitle: 'View access rights for each user role',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RolePermissionScreen()),
                  );
                },
              ),

              _MenuCard(
                icon: Icons.assignment,
                title: 'Enrollment Management',
                subtitle: 'View and filter course enrollments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnrollmentManagement()),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Latest Activities',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: latestLogs.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent activities.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : Column(
                  children: latestLogs.map((log) {
                    return ListTile(
                      leading: const Icon(Icons.history),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _StatCard(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _MiniStatusCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 26,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF212529)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}