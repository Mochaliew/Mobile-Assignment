import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
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
          .select('student_id, class_name, enrollment_date, is_active, users(full_name, email)')
          .order('student_id', ascending: false);

      setState(() => students = response);
    } catch (e) {
      showMessage('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String statusText(Map student) {
    return student['is_active'] == true ? 'Active' : 'Inactive';
  }

  Color statusColor(Map student) {
    return student['is_active'] == true ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Student List'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: fetchStudents, icon: const Icon(Icons.refresh)),
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

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor(student),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(user?['full_name'] ?? 'Unknown Student'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user?['email'] ?? '-'}'),
                  Text('Class: ${student['class_name'] ?? '-'}'),
                  Text(
                    'Status: ${statusText(student)}',
                    style: TextStyle(
                      color: statusColor(student),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}