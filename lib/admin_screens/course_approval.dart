import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseApproval extends StatefulWidget {
  const CourseApproval({super.key});

  @override
  State<CourseApproval> createState() => _CourseApprovalState();
}

class _CourseApprovalState extends State<CourseApproval> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> pendingCourses = [];

  @override
  void initState() {
    super.initState();
    fetchPendingCourses();
  }

  Future<void> fetchPendingCourses() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('courses')
          .select('course_id, title, description, price, teachers(users(full_name)), categories(name)')
          .eq('is_approved', false)
          .eq('is_rejected', false)
          .order('course_id', ascending: false);

      setState(() {
        pendingCourses = response;
      });
    } catch (e) {
      showMessage('Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> approveCourse(int courseId) async {
    try {
      await supabase.from('courses').update({
        'is_approved': true,
        'is_published': true,
        'is_rejected': false,
        'rejection_reason': null,
      }).eq('course_id', courseId);

      showMessage('Course approved successfully');
      fetchPendingCourses();
    } catch (e) {
      showMessage('Approve failed: $e');
    }
  }

  Future<void> rejectCourse(int courseId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Course'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) return;

    try {
      await supabase.from('courses').update({
        'is_approved': false,
        'is_published': false,
        'is_rejected': true,
        'rejection_reason': reason,
      }).eq('course_id', courseId);

      showMessage('Course rejected successfully');
      fetchPendingCourses();
    } catch (e) {
      showMessage('Reject failed: $e');
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
        title: const Text('Course Approval'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchPendingCourses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingCourses.isEmpty
          ? const Center(child: Text('No pending courses.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingCourses.length,
        itemBuilder: (context, index) {
          final course = pendingCourses[index];

          final teacherName =
              course['teachers']?['users']?['full_name'] ?? 'Unknown';

          final categoryName =
              course['categories']?['name'] ?? 'No Category';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Teacher: $teacherName'),
                  Text('Category: $categoryName'),
                  Text('Price: RM ${course['price'] ?? 0}'),
                  const SizedBox(height: 8),
                  Text(
                    course['description'] ?? 'No description',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              approveCourse(course['course_id']),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              rejectCourse(course['course_id']),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                    ],
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