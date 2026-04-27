import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewTeachersScreen extends StatefulWidget {
  const ViewTeachersScreen({super.key});

  @override
  State<ViewTeachersScreen> createState() => _ViewTeachersScreenState();
}

class _ViewTeachersScreenState extends State<ViewTeachersScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> teachers = [];

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('teachers')
          .select('teacher_id, subject_area, is_active, users(full_name, email)')
          .order('teacher_id', ascending: false);

      setState(() => teachers = response);
    } catch (e) {
      showMessage('Error loading teachers: $e');
    } finally {
      setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Teacher List'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: fetchTeachers, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : teachers.isEmpty
          ? const Center(child: Text('No teachers found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          final user = teacher['users'];
          final isActive = teacher['is_active'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.green : Colors.red,
                child: const Icon(Icons.school, color: Colors.white),
              ),
              title: Text(user?['full_name'] ?? 'Unknown Teacher'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user?['email'] ?? '-'}'),
                  Text('Subject: ${teacher['subject_area'] ?? '-'}'),
                  Text(
                    isActive ? 'Status: Active' : 'Status: Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
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