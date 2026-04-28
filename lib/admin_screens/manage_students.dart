import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageStudents extends StatefulWidget {
  const ManageStudents({super.key});

  @override
  State<ManageStudents> createState() => _ManageStudentsState();
}

class _ManageStudentsState extends State<ManageStudents> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> students = [];
  List<dynamic> allStudents = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> addAuditLog(String action) async {
    await supabase.from('audit_logs').insert({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> fetchStudents() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('students')
          .select('student_id, enrollment_date, is_active, users(id, full_name, email)')
          .order('student_id', ascending: false);

      setState(() {
        allStudents = response;
        students = response;
      });
    } catch (e) {
      showMessage('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> toggleStudentStatus(Map<String, dynamic> student) async {
    final user = student['users'];
    final bool isActive = student['is_active'] == true;

    try {
      await supabase.from('students').update({
        'is_active': !isActive,
      }).eq('student_id', student['student_id']);

      await addAuditLog(
        isActive
            ? 'Deactivated student account: ${user['email']}'
            : 'Activated student account: ${user['email']}',
      );

      showMessage(isActive ? 'Student deactivated' : 'Student activated');
      await fetchStudents();
    } catch (e) {
      showMessage('Update failed: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search student...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();

                  students = allStudents.where((s) {
                    final user = s['users'] ?? {};
                    final name = (user['full_name'] ?? '').toString().toLowerCase();
                    final email = (user['email'] ?? '').toString().toLowerCase();

                    return name.contains(search) ||
                      email.contains(search);
                  }).toList();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? const Center(child: Text('No students found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final user = student['users'];
                final bool isActive = student['is_active'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      isActive ? Colors.green : Colors.red,
                      child: Icon(
                      isActive ? Icons.check : Icons.close,
                      color: Colors.white,
                      ),
                    ),
                    title: Text(user['full_name'] ?? 'Unknown Student'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? ''),
                        Text(isActive ? 'Status: Active' : 'Status: Inactive'),
                      ],
                    ),
                    trailing: FilledButton(
                      onPressed: () => toggleStudentStatus(student),
                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}