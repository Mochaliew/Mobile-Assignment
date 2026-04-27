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
  List<dynamic> allTeachers = [];
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

      final response = await query.order('teacher_id', ascending: false);

      final filtered = search.isEmpty
          ? response
          : response.where((t) {
        final user = t['users'] ?? {};
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final keyword = search.toLowerCase();

        return name.contains(keyword) || email.contains(keyword);
      }).toList();

      setState(() {
        teachers = filtered;
      });

      setState(() {
        allTeachers = response;
        teachers = response;
      });

    } catch (e) {
      showMessage('Error loading teachers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> createTeacher() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final subjectController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Teacher Account'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Area',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'password': passwordController.text.trim(),
                'subject': subjectController.text.trim(),
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final name = result['name']!;
    final email = result['email']!;
    final password = result['password']!;
    final subject = result['subject']!;

    if (name.isEmpty || email.isEmpty || password.isEmpty || subject.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    try {
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        showMessage('Email already exists.');
        return;
      }

      final userResponse = await supabase
          .from('users')
          .insert({
        'full_name': name,
        'email': email,
        'password_hash': password,
        'role': 'Teacher',
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      final userId = userResponse['id'];

      await supabase.from('teachers').insert({
        'user_id': userId,
        'subject_area': subject,
        'is_active': true,
      });

      await addAuditLog('Created teacher account: $email');

      showMessage('Teacher account created successfully.');
      await fetchTeachers();
    } catch (e) {
      showMessage('Create teacher failed: $e');
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createTeacher,
        icon: const Icon(Icons.add),
        label: const Text('Create Teacher'),
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
                setState(() {
                  search = value.toLowerCase();

                  teachers = allTeachers.where((t) {
                    final user = t['users'] ?? {};
                    final name = (user['full_name'] ?? '').toLowerCase();
                    final email = (user['email'] ?? '').toLowerCase();

                    return name.contains(search) || email.contains(search);
                  }).toList();
                });
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
                final user = t['users'] ?? {};
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
                        Text(user['email'] ?? '-'),
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