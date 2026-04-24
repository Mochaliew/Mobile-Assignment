// lib/screens/view_lesson.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import '../DB.dart';
import 'create_lesson.dart';
import 'edit_lesson.dart';

class ViewLesson extends StatefulWidget {
  const ViewLesson({super.key});

  @override
  State<ViewLesson> createState() => _ViewLessonState();
}

class _ViewLessonState extends State<ViewLesson> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  // List of { 'course': Course, 'lessons': List<Lesson> }
  List<Map<String, dynamic>> _courseLessons = [];

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);

    try {
      // Only approved courses
      final coursesRes = await supabase
          .from('courses')
          .select('*, categories(name)')
          .eq('teacher_id', TeacherSession.teacherId!)
          .eq('is_approved', true)
          .order('title');

      final List<Course> courses = (coursesRes as List)
          .map((m) => Course.fromJson(m as Map<String, dynamic>))
          .toList();

      final result = <Map<String, dynamic>>[];
      for (final course in courses) {
        final lessonsRes = await supabase
            .from('lessons')
            .select()
            .eq('course_id', course.courseId)
            .order('schedule_date', nullsFirst: false)
            .order('title');

        final lessons = <Lesson>[];
        for (final lm in lessonsRes as List) {
          final lesson = Lesson.fromJson(lm as Map<String, dynamic>);
          final filesRes = await supabase
              .from('course_files')
              .select()
              .eq('lesson_id', lesson.lessonId);
          lessons.add(Lesson(
            lessonId: lesson.lessonId,
            courseId: lesson.courseId,
            courseName: lesson.courseName,
            title: lesson.title,
            description: lesson.description,
            meetLink: lesson.meetLink,
            scheduleDate: lesson.scheduleDate,
            files: (filesRes as List)
                .map((m) => CourseFile.fromJson(m as Map<String, dynamic>))
                .toList(),
          ));
        }
        result.add({'course': course, 'lessons': lessons});
      }

      setState(() => _courseLessons = result);
    } catch (e) {
      snackbar('Error loading lessons: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Lessons'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courseLessons.isEmpty
          ? const Center(child: Text('No approved courses found.'))
          : RefreshIndicator(
        onRefresh: _fetchAll,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _courseLessons.length,
          itemBuilder: (context, index) {
            final entry = _courseLessons[index];
            final course = entry['course'] as Course;
            final lessons = entry['lessons'] as List<Lesson>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold)),
                              Text('${lessons.length} lesson(s)',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CreateLesson(
                                    courseId: course.courseId,
                                    courseName: course.title)),
                          ).then((_) => _fetchAll()),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B6FF5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lessons
                  if (lessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No lessons yet.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: lessons.map((lesson) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text('📖 ${lesson.title}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF5B6FF5)),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EditLesson(
                                            lesson: lesson,
                                            courseName: course.title)),
                                  ).then((_) => _fetchAll()),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ]),
                              if (lesson.description.isNotEmpty)
                                Text(lesson.description,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              if (lesson.meetLink.isNotEmpty)
                                const Text('🔗 Meeting link attached',
                                    style: TextStyle(
                                        color: Color(0xFF5B6FF5), fontSize: 12)),
                              if (lesson.scheduleDate != null)
                                Text(
                                    '📅 ${DateFormat('MMM dd, yyyy hh:mm a').format(lesson.scheduleDate!)}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              if (lesson.files.isNotEmpty)
                                ...lesson.files.map((f) => Row(children: [
                                  Text(
                                      f.fileType == 'pdf' ? '📄 PDF' : '🎥 Video',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text(
                                      '• ${DateFormat('MMM dd, yyyy').format(f.uploadedAt)}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 11)),
                                ])),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
