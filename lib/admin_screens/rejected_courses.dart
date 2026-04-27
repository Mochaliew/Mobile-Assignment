import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RejectedCoursesScreen extends StatefulWidget {
  const RejectedCoursesScreen({super.key});

  @override
  State<RejectedCoursesScreen> createState() =>
      _RejectedCoursesScreenState();
}

class _RejectedCoursesScreenState extends State<RejectedCoursesScreen> {
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
          'course_id, title, rejection_reason, teachers(users(full_name)), categories(name)')
          .eq('is_rejected', true)
          .order('course_id', ascending: false);

      setState(() {
        courses = response;
      });
    } catch (e) {
      showMessage('Error loading rejected courses: $e');
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
      appBar: AppBar(
        title: const Text('Rejected Courses'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
          ? const Center(child: Text('No rejected courses.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];

          final teacher =
              c['teachers']?['users']?['full_name'] ?? 'Unknown';
          final category = c['categories']?['name'] ?? 'No Category';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(c['title'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teacher: $teacher'),
                  Text('Category: $category'),
                  Text(
                    'Reason: ${c['rejection_reason'] ?? 'No reason'}',
                    style: const TextStyle(color: Colors.red),
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