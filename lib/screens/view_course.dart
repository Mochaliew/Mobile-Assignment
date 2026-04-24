import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../DB.dart';
import 'create_course.dart';
import 'course_detail.dart';
import 'create_lesson.dart';
import 'create_assessment.dart';

class ViewCourse extends StatefulWidget {
  const ViewCourse({super.key});

  @override
  State<ViewCourse> createState() => _ViewCourseState();
}

class _ViewCourseState extends State<ViewCourse> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Course> _courses = [];
  String _filter = 'all';

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('courses')
          .select('*, categories(name), enrollments(enrollment_id)')
          .eq('teacher_id', TeacherSession.teacherId!)
          .order('course_id', ascending: false);

      final List<Course> courses = (response as List)
          .map((m) => Course.fromJson(m as Map<String, dynamic>))
          .toList();

      setState(() => _courses = courses);
    } catch (e) {
      snackbar('Error loading courses: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Delete "${course.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      await supabase
          .from('courses')
          .delete()
          .eq('course_id', course.courseId);

      setState(() => _courses.removeWhere((c) => c.courseId == course.courseId));
      snackbar('Course deleted.');
    } catch (e) {
      snackbar('Error deleting course: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Course> get _filtered {
    switch (_filter) {
      case 'approved':
        return _courses.where((c) => c.isApproved && !c.isRejected).toList();
      case 'pending':
        return _courses.where((c) => !c.isApproved && !c.isRejected).toList();
      case 'rejected':
        return _courses.where((c) => c.isRejected).toList();
      default:
        return _courses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final approved = _courses.where((c) => c.isApproved && !c.isRejected).length;
    final pending = _courses.where((c) => !c.isApproved && !c.isRejected).length;
    final rejected = _courses.where((c) => c.isRejected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCourses),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateCourse()),
            ).then((_) => _fetchCourses()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FilterChip(label: 'All (${_courses.length})', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                _FilterChip(label: 'Pending ($pending)', active: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
                _FilterChip(label: 'Approved ($approved)', active: _filter == 'approved', onTap: () => setState(() => _filter = 'approved')),
                _FilterChip(label: 'Rejected ($rejected)', active: _filter == 'rejected', onTap: () => setState(() => _filter = 'rejected')),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  const Text('No courses found.',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateCourse()),
                    ).then((_) => _fetchCourses()),
                    child: const Text('+ Create Course'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchCourses,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final course = _filtered[index];
                  return _CourseCard(
                    course: course,
                    onDetail: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CourseDetail(courseId: course.courseId)),
                    ).then((_) => _fetchCourses()),
                    onAddLesson: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateLesson(
                              courseId: course.courseId,
                              courseName: course.title)),
                    ).then((_) => _fetchCourses()),
                    onAddAssessment: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateAssessment(
                              courseId: course.courseId,
                              courseName: course.title)),
                    ).then((_) => _fetchCourses()),
                    onDelete: () => _deleteCourse(course),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCourse()),
        ).then((_) => _fetchCourses()),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Widgets local to this screen ────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5B6FF5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active ? const Color(0xFF5B6FF5) : Colors.grey.shade300),
      ),
      child: Text(label,
          style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500)),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isApproved, isRejected;
  const _StatusBadge({required this.isApproved, required this.isRejected});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    if (isRejected) {
      bg = const Color(0xFFF8D7DA); text = const Color(0xFF721C24); label = 'Rejected';
    } else if (isApproved) {
      bg = const Color(0xFFD4EDDA); text = const Color(0xFF155724); label = 'Approved';
    } else {
      bg = const Color(0xFFFFF3CD); text = const Color(0xFF856404); label = 'Pending Approval';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onDetail, onAddLesson, onAddAssessment, onDelete;
  const _CourseCard({
    required this.course,
    required this.onDetail,
    required this.onAddLesson,
    required this.onAddAssessment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(isApproved: course.isApproved, isRejected: course.isRejected),
          const SizedBox(height: 8),
          Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (course.categoryName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Category: ${course.categoryName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          if (course.isRejected && course.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(6)),
              child: Text('⚠️ ${course.rejectionReason}', style: const TextStyle(fontSize: 13, color: Color(0xFF856404))),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Text('👥 ${course.enrollmentCount} Students', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 12),
            Text('RM ${course.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF5B6FF5), fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: onDetail, child: const Text('Details')),
              if (course.isApproved) ...[
                OutlinedButton(onPressed: onAddLesson, child: const Text('+Lesson')),
                OutlinedButton(onPressed: onAddAssessment, child: const Text('+Assessment')),
              ],
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
