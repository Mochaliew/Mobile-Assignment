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
  bool _isActionLoading = false;
  String filter = 'All';
  List<dynamic> courses = [];

  final filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> addAuditLog(String action) async {
    await supabase.from('audit_logs').insert({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> approveCourse(int courseId) async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      await supabase.from('courses').update({
        'is_approved': true,
        'is_published': true,
        'is_rejected': false,
        'rejection_reason': null,
      }).eq('course_id', courseId);

      await addAuditLog('Approved course ID: $courseId');
      showMessage('Course approved');
      await fetchCourses();
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> rejectCourse(int courseId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Course'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await supabase.from('courses').update({
        'is_approved': false,
        'is_published': false,
        'is_rejected': true,
        'rejection_reason': reason,
      }).eq('course_id', courseId);

      await addAuditLog('Rejected course ID: $courseId | Reason: $reason');

      showMessage('Course rejected');
      await fetchCourses();
    } catch (e) {
      showMessage('Reject failed: $e');
    }
  }

  Future<void> restoreToPending(int courseId) async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      await supabase.from('courses').update({
        'is_approved': false,
        'is_published': false,
        'is_rejected': false,
        'rejection_reason': null,
      }).eq('course_id', courseId);

      await addAuditLog('Restored course ID: $courseId to pending');
      showMessage('Course restored to pending');

      await fetchCourses();
    } finally {
      setState(() => _isActionLoading = false);
    }
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

  Future<bool> confirmAction(String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
        false;
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          onTap: () => showCourseDetails(c),
                          leading: CircleAvatar(
                            backgroundColor: statusColor,
                            child: const Icon(Icons.menu_book, color: Colors.white),
                          ),
                          title: Text(c['title'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Teacher: $teacher'),
                              Text('Category: $category'),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => showCourseDetails(c),
                                icon: const Icon(Icons.visibility),
                                label: const Text('View'),
                              ),
                            ),

                            if (status == 'Pending') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final confirm = await confirmAction('Approve this course?');
                                    if (confirm) await approveCourse(c['course_id']);
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => rejectCourse(c['course_id']),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                              ),
                            ],

                            if (status == 'Approved') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => rejectCourse(c['course_id']),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                              ),
                            ],

                            if (status == 'Rejected') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final confirm = await confirmAction('Restore to pending?');
                                    if (confirm) await restoreToPending(c['course_id']);
                                  },
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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