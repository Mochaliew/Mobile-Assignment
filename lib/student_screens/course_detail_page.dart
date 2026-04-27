// --- Course Detail Page (Database-driven) ------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/catalog_course.dart';
import 'widgets/purchase_success_overlay.dart';

class CourseDetailPage extends StatefulWidget {
  final CatalogCourse course;
  final bool showPurchaseButton;
  final VoidCallback? onPurchased;

  const CourseDetailPage({
    super.key,
    required this.course,
    this.showPurchaseButton = false,
    this.onPurchased,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _showingSuccess = false;

  List<dynamic> _lessons = [];
  List<dynamic> _assessments = [];
  dynamic _finalExam;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    final courseId = widget.course.id;
    try {
      final lessonsData = await supabase
          .from('lessons')
          .select('*')
          .eq('course_id', courseId)
          .order('lesson_id');

      final assessmentsData = await supabase
          .from('assessments')
          .select('*')
          .eq('course_id', courseId)
          .order('assessment_id');

      final finalExamData = await supabase
          .from('final_exams')
          .select('*')
          .eq('course_id', courseId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _lessons = lessonsData;
          _assessments = assessmentsData;
          _finalExam = finalExamData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load course details: $e')),
        );
      }
    }
  }

  void _confirmPurchase() {
    final priceText = widget.course.price == 0
        ? '\$0 (Free)'
        : '\$${widget.course.price.toStringAsFixed(2)}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase'),
        content: Text(
          'Are you sure to pay $priceText for "${widget.course.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B6FF5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    setState(() => _showingSuccess = true);
  }

  void _onSuccessComplete() {
    if (widget.onPurchased != null) {
      widget.onPurchased!();
    }
    Navigator.pop(context, true);
  }

  String _fmtDate(dynamic value) {
    if (value == null) return 'TBD';
    DateTime? d;
    if (value is DateTime) {
      d = value;
    } else if (value is String) {
      d = DateTime.tryParse(value);
    }
    if (d == null) return value.toString();
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

  @override
  Widget build(BuildContext context) {
    final c = widget.course;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
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
                              c.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'by ${c.instructor}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              c.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Lessons & Materials
                      if (_lessons.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.menu_book, color: Color(0xFF5B6FF5)),
                            SizedBox(width: 8),
                            Text(
                              'Lessons & Materials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._lessons.asMap().entries.map((entry) {
                          final index = entry.key;
                          final lesson = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _lessons.length - 1 ? 10 : 0,
                            ),
                            child: _lessonTile(
                              title: lesson['title'] ?? 'Lesson',
                              subtitle: lesson['description'] ?? '',
                              meetLink: lesson['meet_link'],
                              scheduleDate: lesson['schedule_date'] != null
                                  ? DateTime.tryParse(lesson['schedule_date'])
                                  : null,
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                      // Assessments
                      if (_assessments.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.description, color: Color(0xFF5B6FF5)),
                            SizedBox(width: 8),
                            Text(
                              'Assessments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._assessments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final a = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _assessments.length - 1 ? 10 : 0,
                            ),
                            child: _assessmentTile(
                              a['title'] ?? 'Assessment',
                              'Passing Marks: ${a['passing_mark'] ?? 'N/A'}%',
                              'Deadline: ${_fmtDate(a['dead_line'])}',
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                      // Final Exam
                      if (_finalExam != null) ...[
                        const Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF5B6FF5),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Final Exam',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                                'Exam Date: ${_fmtDate(_finalExam['dead_line'])}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Marks: ${_finalExam['total_marks'] ?? 'N/A'}  |  Passing: ${_finalExam['passing_mark'] ?? 'N/A'}%',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Bottom padding for purchase button
                      if (widget.showPurchaseButton) const SizedBox(height: 80),
                    ],
                  ),
                ),
          if (_showingSuccess)
            PurchaseSuccessOverlay(onComplete: _onSuccessComplete),
        ],
      ),
      bottomNavigationBar: widget.showPurchaseButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _confirmPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    c.price == 0
                        ? 'Purchase Course - \$0'
                        : 'Purchase Course - \$${c.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _lessonTile({
    required String title,
    required String subtitle,
    String? meetLink,
    DateTime? scheduleDate,
  }) {
    final now = DateTime.now();
    final isPast = scheduleDate != null && scheduleDate.isBefore(now);
    final dateText = scheduleDate != null ? _fmtDate(scheduleDate) : 'TBD';

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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (meetLink != null && meetLink.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening GMeet: $meetLink')),
                    );
                  },
                  icon: const Icon(Icons.video_call, size: 18),
                  label: const Text('Go to GMeet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (meetLink != null && meetLink.isNotEmpty)
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPast
                      ? 'Class has ended and was conducted on $dateText'
                      : 'Scheduled: $dateText',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPast ? Colors.grey : const Color(0xFF5B6FF5),
                    fontWeight: isPast ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assessmentTile(String title, String passing, String deadline) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            passing,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                deadline,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
