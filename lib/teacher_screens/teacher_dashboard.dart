// --- Teacher Dashboard Screen -------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import '../DB.dart';
import 'teacher_login.dart';
import 'view_course.dart';
import 'view_lesson.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  int _totalStudents = 0;
  int _totalLessons = 0;
  int _totalAssessments = 0;
  int _totalCourses = 0;
  List<Map<String, dynamic>> _upcomingLessons = [];
  List<Map<String, dynamic>> _recentAssessments = [];

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);

    try {
      final tid = TeacherSession.teacherId!;

      final coursesRes = await supabase
          .from('courses')
          .select('course_id, enrollments(enrollment_id)')
          .eq('teacher_id', tid)
          .eq('is_approved', true)
          .eq('is_rejected', false);

      final courseIds =
      (coursesRes as List).map((c) => c['course_id'] as int).toList();

      _totalCourses = courseIds.length;

      if (courseIds.isNotEmpty) {
        final enrollRes = await supabase
            .from('enrollments')
            .select('student_id')
            .inFilter('course_id', courseIds);
        final studentSet = <int>{};
        for (final e in enrollRes as List) {
          studentSet.add(e['student_id']);
        }
        _totalStudents = studentSet.length;

        final lessonRes = await supabase
            .from('lessons')
            .select('lesson_id')
            .inFilter('course_id', courseIds);
        _totalLessons = (lessonRes as List).length;

        final assessRes = await supabase
            .from('assessments')
            .select('assessment_id')
            .inFilter('course_id', courseIds);
        _totalAssessments = (assessRes as List).length;

        final now = DateTime.now().toIso8601String();
        final upRes = await supabase
            .from('lessons')
            .select('title, schedule_date, courses(title)')
            .inFilter('course_id', courseIds)
            .gte('schedule_date', now)
            .order('schedule_date')
            .limit(5);
        _upcomingLessons = List<Map<String, dynamic>>.from(upRes as List);

        final recRes = await supabase
            .from('assessments')
            .select('title, courses(title)')
            .inFilter('course_id', courseIds)
            .order('assessment_id', ascending: false)
            .limit(5);
        _recentAssessments = List<Map<String, dynamic>>.from(recRes as List);
      }

      setState(() {});
    } catch (e) {
      snackbar('Error loading dashboard: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    TeacherSession.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _fetchDashboard),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B6FF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${TeacherSession.teacherName}! 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          TeacherSession.teacherEmail ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      emoji: '📚',
                      title: 'My Courses',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ViewCourse()),
                      ).then((_) => _fetchDashboard()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      emoji: '📖',
                      title: 'My Lessons',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ViewLesson()),
                      ).then((_) => _fetchDashboard()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Overview',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                      number: _totalCourses.toString(),
                      label: 'Active Courses',
                      color: const Color(0xFF5B6FF5)),
                  _StatCard(
                      number: _totalStudents.toString(),
                      label: 'Total Students',
                      color: const Color(0xFF38B2AC)),
                  _StatCard(
                      number: _totalLessons.toString(),
                      label: 'Total Lessons',
                      color: const Color(0xFFED8936)),
                  _StatCard(
                      number: _totalAssessments.toString(),
                      label: 'Assessments',
                      color: const Color(0xFF9F7AEA)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('📅 Upcoming Lessons',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _upcomingLessons.isEmpty
                      ? const Text('No upcoming lessons.',
                      style: TextStyle(color: Colors.grey))
                      : Column(
                    children: _upcomingLessons.map((l) {
                      final schedule = l['schedule_date'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                          .format(DateTime.parse(
                          l['schedule_date']))
                          : '';
                      return ListTile(
                        leading: const Icon(Icons.book_outlined,
                            color: Color(0xFF5B6FF5)),
                        title: Text(l['title'] ?? ''),
                        subtitle: Text(
                            '${l['courses']?['title'] ?? ''}  •  $schedule'),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('📝 Recent Assessments',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _recentAssessments.isEmpty
                      ? const Text('No assessments yet.',
                      style: TextStyle(color: Colors.grey))
                      : Column(
                    children: _recentAssessments.map((a) {
                      return ListTile(
                        leading: const Icon(Icons.quiz_outlined,
                            color: Color(0xFF5B6FF5)),
                        title: Text(a['title'] ?? ''),
                        subtitle: Text(
                            a['courses']?['title'] ?? ''),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji, title;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.emoji, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String number, label;
  final Color color;
  const _StatCard(
      {required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(number,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );
}
