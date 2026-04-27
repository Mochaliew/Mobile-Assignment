import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  String filter = 'All';
  List<dynamic> courses = [];

  final filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('courses').select(
          'course_id, title, description, price, is_approved, is_rejected, is_published, rejection_reason, teachers(users(full_name)), categories(name)');

      if (filter == 'Pending') {
        query = query.eq('is_approved', false).eq('is_rejected', false);
      } else if (filter == 'Approved') {
        query = query.eq('is_approved', true).eq('is_rejected', false);
      } else if (filter == 'Rejected') {
        query = query.eq('is_rejected', true);
      }

      final response = await query.order('course_id', ascending: false);

      setState(() {
        courses = response;
      });
    } catch (e) {
      showMessage('Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String getStatus(Map course) {
    if (course['is_rejected'] == true) return 'Rejected';
    if (course['is_approved'] == true) return 'Approved';
    return 'Pending';
  }

  Color getStatusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showCourseDetails(Map course) {
    final status = getStatus(course);
    final teacher = course['teachers']?['users']?['full_name'] ?? 'Unknown';
    final category = course['categories']?['name'] ?? 'No Category';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(course['title'] ?? 'Course Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Teacher: $teacher'),
              Text('Category: $category'),
              Text('Price: RM ${course['price'] ?? 0}'),
              Text('Status: $status'),
              Text('Published: ${course['is_published'] == true ? 'Yes' : 'No'}'),
              const SizedBox(height: 12),
              Text('Description:\n${course['description'] ?? '-'}'),
              if (status == 'Rejected') ...[
                const SizedBox(height: 12),
                Text(
                  'Rejection Reason:\n${course['rejection_reason'] ?? '-'}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Manage Courses'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchCourses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: filter,
              decoration: const InputDecoration(
                labelText: 'Filter Course Status',
                border: OutlineInputBorder(),
              ),
              items: filters.map((f) {
                return DropdownMenuItem(value: f, child: Text(f));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => filter = value);
                fetchCourses();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : courses.isEmpty
                ? const Center(child: Text('No courses found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final c = courses[index];
                final status = getStatus(c);
                final statusColor = getStatusColor(status);
                final teacher =
                    c['teachers']?['users']?['full_name'] ??
                        'Unknown';
                final category =
                    c['categories']?['name'] ?? 'No Category';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => showCourseDetails(c),
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(c['title'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Teacher: $teacher'),
                        Text('Category: $category'),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
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