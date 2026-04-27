import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewCoursesScreen extends StatefulWidget {
  const ViewCoursesScreen({super.key});

  @override
  State<ViewCoursesScreen> createState() => _ViewCoursesScreenState();
}

class _ViewCoursesScreenState extends State<ViewCoursesScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> courses = [];

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('courses')
          .select(
          'course_id, title, description, price, is_approved, is_rejected, teachers(users(full_name)), categories(name)')
          .order('course_id', ascending: false);

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

  void showDetails(Map course) {
    final status = getStatus(course);
    final teacher =
        course['teachers']?['users']?['full_name'] ?? 'Unknown';
    final category =
        course['categories']?['name'] ?? 'No Category';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(course['title'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Teacher: $teacher'),
              Text('Category: $category'),
              Text('Price: RM ${course['price'] ?? 0}'),
              Text('Status: $status'),
              const SizedBox(height: 10),
              Text('Description:\n${course['description'] ?? '-'}'),
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
        title: const Text('All Courses'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchCourses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
          ? const Center(child: Text('No courses found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];
          final status = getStatus(c);
          final color = getStatusColor(status);

          final teacher =
              c['teachers']?['users']?['full_name'] ??
                  'Unknown';
          final category =
              c['categories']?['name'] ?? 'No Category';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => showDetails(c),
              leading: CircleAvatar(
                backgroundColor: color,
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
                      color: color,
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
    );
  }
}