import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApprovedCoursesScreen extends StatefulWidget {
  const ApprovedCoursesScreen({super.key});

  @override
  State<ApprovedCoursesScreen> createState() => _ApprovedCoursesScreenState();
}

class _ApprovedCoursesScreenState extends State<ApprovedCoursesScreen> {
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
          'course_id, title, price, teachers(users(full_name)), categories(name)')
          .eq('is_approved', true)
          .eq('is_rejected', false)
          .order('course_id', ascending: false);

      setState(() {
        courses = response;
      });
    } catch (e) {
      showMessage('Error loading approved courses: $e');
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
        title: const Text('Approved Courses'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
          ? const Center(child: Text('No approved courses.'))
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
                ],
              ),
              trailing: Text(
                'RM ${c['price'] ?? 0}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}