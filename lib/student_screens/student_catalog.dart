// --- Student Catalog (Database-driven) ---------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db.dart';
import '../teacher_screens/teacher_login.dart';
import 'course_detail_page.dart';
import 'models/catalog_course.dart';

class StudentCatalog extends StatefulWidget {
  const StudentCatalog({super.key});

  @override
  State<StudentCatalog> createState() => _StudentCatalogState();
}

class _StudentCatalogState extends State<StudentCatalog> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<CatalogCourse> _courses = [];
  int _selectedTab = 0; // 0 = All, 1 = Available, 2 = My Purchases
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final studentId = StudentSession.studentId;
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch all published & approved courses with teacher info
      final coursesData = await supabase
          .from('courses')
          .select(''', teachers(user_id, users(full_name))''')
          .eq('is_published', true)
          .eq('is_approved', true);

      // Fetch current student's enrollments
      final enrollmentsData = await supabase
          .from('enrollments')
          .select('course_id, progress')
          .eq('student_id', studentId);

      final enrollmentMap = {
        for (var e in enrollmentsData)
          e['course_id'] as int: (e['progress'] ?? 0) as int,
      };

      // Fetch total assessments per course
      final allAssessments = await supabase
          .from('assessments')
          .select('course_id, assessment_id');
      final totalPerCourse = <int, int>{};
      for (var a in allAssessments) {
        final cid = a['course_id'] as int;
        totalPerCourse[cid] = (totalPerCourse[cid] ?? 0) + 1;
      }

      // Fetch completed assessments per course for this student
      final certs = await supabase
          .from('certificates')
          .select('course_id, assesment_id')
          .eq('student_id', studentId)
          .not('assesment_id', 'is', null);
      final completedPerCourse = <int, int>{};
      for (var c in certs) {
        final cid = c['course_id'] as int;
        completedPerCourse[cid] = (completedPerCourse[cid] ?? 0) + 1;
      }

      final loaded = (coursesData as List).map<CatalogCourse>((c) {
        final courseId = c['course_id'] as int;
        final isPurchased = enrollmentMap.containsKey(courseId);
        final total = totalPerCourse[courseId] ?? 0;
        final completed = completedPerCourse[courseId] ?? 0;
        final progress = isPurchased && total > 0
            ? ((completed / total) * 100).round()
            : 0;
        final instructor = c['teachers']?['users']?['full_name'] ?? 'Unknown';

        return CatalogCourse(
          id: courseId,
          title: c['title'] ?? '',
          instructor: instructor,
          description: c['description'] ?? '',
          price: (c['price'] ?? 0).toDouble(),
          progress: progress / 100,
          isPurchased: isPurchased,
          lessons: const [],
          assessments: const [],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _courses = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load catalog: $e')));
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

  Future<void> _onCoursePurchased(int courseId) async {
    final studentId = StudentSession.studentId;
    if (studentId == null) return;

    try {
      await supabase.from('enrollments').insert({
        'student_id': studentId,
        'course_id': courseId,
        'progress': 0,
      });
      await _loadCourses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
      }
    }
  }

  List<CatalogCourse> get _filteredCourses {
    List<CatalogCourse> result;
    switch (_selectedTab) {
      case 1:
        result = _courses.where((c) => !c.isPurchased).toList();
        break;
      case 2:
        result = _courses.where((c) => c.isPurchased).toList();
        break;
      default:
        result = List.from(_courses);
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (c) =>
                c.title.toLowerCase().contains(q) ||
                c.instructor.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  Future<void> _openCourseDetail(
    CatalogCourse course, {
    bool showPurchase = false,
  }) async {
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(
          course: course,
          showPurchaseButton: showPurchase,
          onPurchased: () => _onCoursePurchased(course.id),
        ),
      ),
    );

    // Refresh catalog if purchase happened (enrollment already inserted by onPurchased)
    if (purchased == true && mounted) {
      _loadCourses();
    }
  }

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
          'Course Catalog',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5B6FF5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tabs
                  Row(
                    children: [
                      _tabButton('All Courses', 0),
                      const SizedBox(width: 8),
                      _tabButton('Available', 1),
                      const SizedBox(width: 8),
                      _tabButton('My Purchases', 2),
                    ],
                  ),
                ],
              ),
            ),
            // Course list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = _filteredCourses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: course.isPurchased
                        ? _purchasedCard(course)
                        : _availableCard(course),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF5B6FF5) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isActive ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _purchasedCard(CatalogCourse course) {
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
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${course.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B6FF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'by ${course.instructor}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '${(course.progress * 100).toInt()}%',
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
              value: course.progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5B6FF5)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openCourseDetail(course),
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

  Widget _availableCard(CatalogCourse course) {
    final isFree = course.price == 0;

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
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isFree ? 'Free' : '\$${course.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFree ? Colors.green : const Color(0xFF5B6FF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'by ${course.instructor}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _openCourseDetail(course, showPurchase: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _openCourseDetail(course, showPurchase: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Purchase'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
