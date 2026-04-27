import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageTeachers extends StatefulWidget {
  const ManageTeachers({super.key});

  @override
  State<ManageTeachers> createState() => _ManageTeachersState();
}

class _ManageTeachersState extends State<ManageTeachers> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> teachers = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> addAuditLog(String action) async {
    await supabase.from('audit_logs').insert({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> fetchTeachers() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase
          .from('teachers')
          .select('teacher_id, subject_area, is_active, users(id, full_name, email)');

      if (search.isNotEmpty) {
        query = query.ilike('users.full_name', '%$search%');
      }

      final response = await query.order('teacher_id', ascending: false);

      setState(() {
        teachers = response;
      });
    } catch (e) {
      showMessage('Error loading teachers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> toggleTeacherStatus(Map teacher) async {
    final userId = teacher['users']['id'];
    final bool isActive = teacher['is_active'] == true;

    try {
      await supabase.from('teachers').update({
        'is_active': !isActive,
      }).eq('teacher_id', teacher['teacher_id']);

      await addAuditLog(
        isActive
            ? 'Deactivated teacher account: ${teacher['users']['email']}'
            : 'Activated teacher account: ${teacher['users']['email']}',
      );

      showMessage(isActive ? 'Teacher deactivated' : 'Teacher activated');
      await fetchTeachers();
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
        title: const Text('Manage Teachers'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchTeachers,
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
                hintText: 'Search teacher...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                search = value;
                fetchTeachers();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : teachers.isEmpty
                ? const Center(child: Text('No teachers found'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final t = teachers[index];
                final user = t['users'];
                final bool isActive = t['is_active'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      isActive ? Colors.green : Colors.red,
                      child: Icon(
                        isActive ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user['full_name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? ''),
                        Text('Subject: ${t['subject_area'] ?? '-'}'),
                        Text(isActive
                            ? 'Status: Active'
                            : 'Status: Inactive'),
                      ],
                    ),
                    trailing: FilledButton(
                      onPressed: () => toggleTeacherStatus(t),
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