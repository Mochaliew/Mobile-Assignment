// --- Student Dashboard (Database-driven) -------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../DB.dart';
import '../teacher_screens/teacher_login.dart';
import 'course_detail_page.dart';
import 'models/catalog_course.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<dynamic> _enrollments = [];
  List<dynamic> _certificates = [];
  List<dynamic> _assessments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final studentId = StudentSession.studentId;
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Enrollments with course + teacher info
      final enrollmentsData = await supabase
          .from('enrollments')
          .select('''
            *,
            courses(
              *,
              teachers(
                teacher_id,
                user_id,
                users(full_name)
              )
            )
          ''')
          .eq('student_id', studentId);

      // 2. Certificates with course info
      final certificatesData = await supabase
          .from('certificates')
          .select('''
            *,
            courses(
              *,
              teachers(
                teacher_id,
                user_id,
                users(full_name)
              )
            )
          ''')
          .eq('student_id', studentId)
          .order('issue_date', ascending: false);

      // 3. Assessments for enrolled courses
      final courseIds = (enrollmentsData as List)
          .map((e) => e['course_id'] as int)
          .toList();

      List<dynamic> assessmentsData = [];
      if (courseIds.isNotEmpty) {
        assessmentsData = await supabase
            .from('assessments')
            .select('*, courses(title)')
            .inFilter('course_id', courseIds)
            .gte('dead_line', DateTime.now().toIso8601String())
            .order('dead_line');
      }

      if (mounted) {
        setState(() {
          _enrollments = enrollmentsData;
          _certificates = certificatesData;
          _assessments = assessmentsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
      }
    }
  }

  void _logout() {
    StudentSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLogin()),
      (route) => false,
    );
  }

  void _showCertificateDialog(String course, String instructor, String date) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF5B6FF5),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Certificate of Completion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildCertInfo('Course', course),
              const SizedBox(height: 16),
              _buildCertInfo('Instructor', instructor),
              const SizedBox(height: 16),
              _buildCertInfo('Issue Date', date),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading certificate PDF...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('View Certificate (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- Derived data helpers --------------------------------------------------
  int get _activeCount => _enrollments
      .where((e) => (e['progress'] as int) > 0 && (e['progress'] as int) < 100)
      .length;

  int get _completedCount =>
      _enrollments.where((e) => (e['progress'] as int) == 100).length;

  int get _certCount => _certificates.length;

  int get _assessmentCount => _assessments.length;

  List<dynamic> get _continueLearning => _enrollments
      .where((e) => (e['progress'] as int) > 0 && (e['progress'] as int) < 100)
      .toList();

  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _statCard(
                    Icons.menu_book,
                    Colors.blue,
                    '$_activeCount',
                    'Active Courses',
                  ),
                  _statCard(
                    Icons.check_circle,
                    Colors.green,
                    '$_completedCount',
                    'Completed',
                  ),
                  _statCard(
                    Icons.emoji_events,
                    Colors.purple,
                    '$_certCount',
                    'Certificates',
                  ),
                  _statCard(
                    Icons.access_time,
                    Colors.orange,
                    '$_assessmentCount',
                    'Assessments',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Continue Learning
              if (_continueLearning.isNotEmpty) ...[
                const Text(
                  'Continue Learning',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _continueLearning.map((enrollment) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _continueCard(enrollment),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Pending Assessments
              if (_assessments.isNotEmpty) ...[
                const Text(
                  'Pending Assessments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._assessments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final a = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _assessments.length - 1 ? 10 : 0,
                    ),
                    child: _assessmentCard(a),
                  );
                }),
                const SizedBox(height: 24),
              ],
              // Certificates
              if (_certificates.isNotEmpty) ...[
                const Text(
                  'Certificates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._certificates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cert = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _certificates.length - 1 ? 10 : 0,
                    ),
                    child: _certificateTile(cert),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _continueCard(dynamic enrollment) {
    final course = enrollment['courses'];
    final progress = (enrollment['progress'] as int) / 100;
    final title = course['title'] ?? 'Course';
    final description = course['description'] ?? '';

    final instructor = course['teachers']?['users']?['full_name'] ?? 'Unknown';
    final courseObj = CatalogCourse(
      id: course['course_id'] ?? 0,
      title: title,
      instructor: instructor,
      description: description,
      price: (course['price'] ?? 0).toDouble(),
      progress: progress,
      isPurchased: true,
      lessons: const [],
      assessments: const [],
    );

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF5B6FF5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5B6FF5)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailPage(course: courseObj),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B6FF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assessmentCard(dynamic assessment) {
    final courseTitle = assessment['courses']?['title'] ?? 'Course';
    final title = assessment['title'] ?? 'Assessment';
    final deadline = assessment['dead_line'] != null
        ? DateTime.tryParse(assessment['dead_line'])
        : null;
    final dueText = deadline != null
        ? 'Due: ${_fmtDate(deadline)}'
        : 'Due: TBD';

    // Badge logic
    String badge = '';
    Color badgeColor = Colors.transparent;
    if (deadline != null) {
      final diff = deadline.difference(DateTime.now()).inDays;
      if (diff <= 3) {
        badge = 'Due Soon';
        badgeColor = Colors.red;
      } else if (diff <= 14) {
        badge = 'Upcoming';
        badgeColor = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                courseTitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                dueText,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _certificateTile(dynamic cert) {
    final course = cert['courses'];
    final title = course['title'] ?? 'Course';
    final instructor = course['teachers']?['users']?['full_name'] ?? 'Unknown';
    final issueDate = cert['issue_date'] != null
        ? DateTime.tryParse(cert['issue_date'])
        : null;
    final dateText = issueDate != null ? _fmtDate(issueDate) : 'N/A';

    return GestureDetector(
      onTap: () => _showCertificateDialog(title, instructor, dateText),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, color: Color(0xFF5B6FF5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
