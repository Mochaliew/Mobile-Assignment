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

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('students')
          .select('student_id, class_name, enrollment_date, users(id, full_name, email, lockout_end)')
          .order('student_id', ascending: false);

      setState(() {
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
    final userId = user['id'];
    final bool isActive = user['lockout_end'] == null;

    try {
      await supabase.from('users').update({
        'lockout_end': isActive ? DateTime.now().add(const Duration(days: 36500)).toIso8601String() : null,
      }).eq('id', userId);

      showMessage(isActive ? 'Student deactivated' : 'Student activated');
      fetchStudents();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? const Center(child: Text('No students found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final user = student['users'];
          final bool isActive = user['lockout_end'] == null;

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
                  Text('Class: ${student['class_name'] ?? '-'}'),
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
    );
  }
}