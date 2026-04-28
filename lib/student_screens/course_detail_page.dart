// --- Course Detail Page (Database-driven) ------------------------------------
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../DB.dart';
import 'models/catalog_course.dart';
import 'widgets/assessment_quiz_dialog.dart';
import 'widgets/purchase_success_overlay.dart';

class CourseDetailPage extends StatefulWidget {
  final CatalogCourse course;
  final bool showPurchaseButton;
  final Future<void> Function()? onPurchased;

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
  Set<int> _completedAssessmentIds = {};
  Map<int, dynamic> _filesByLessonId = {};

  bool get _hasCourseAccess => !widget.showPurchaseButton;

  void _showPurchaseRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please purchase this course to access this content.'),
      ),
    );
  }

  Future<void> _openMeetLink(String meetLink) async {
    final trimmedLink = meetLink.trim();
    final linkWithScheme = trimmedLink.startsWith(RegExp(r'https?://'))
        ? trimmedLink
        : 'https://$trimmedLink';
    final uri = Uri.tryParse(linkWithScheme);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid GMeet link')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open GMeet link')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open GMeet link')),
      );
    }
  }

  String _safeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'material.pdf' : sanitized;
  }

  Future<Directory> _downloadedMaterialsDir() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${documentsDir.path}/downloaded_materials');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    final courseId = widget.course.id;
    final studentId = StudentSession.studentId;
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

      Set<int> completedIds = {};
      if (studentId != null) {
        final certs = await supabase
            .from('certificates')
            .select('assesment_id')
            .eq('student_id', studentId)
            .not('assesment_id', 'is', null);
        completedIds = {for (var c in certs) c['assesment_id'] as int};
      }

      // Fetch files for this course's lessons
      final lessonIds = (lessonsData as List)
          .map((l) => l['lesson_id'] as int)
          .toList();
      final filesData = lessonIds.isNotEmpty
          ? await supabase
                .from('course_files')
                .select('*')
                .inFilter('lesson_id', lessonIds)
          : [];
      final filesMap = {for (var f in filesData) f['lesson_id'] as int: f};

      if (mounted) {
        setState(() {
          _lessons = lessonsData;
          _assessments = assessmentsData;
          _finalExam = finalExamData;
          _completedAssessmentIds = completedIds;
          _filesByLessonId = filesMap;
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

  Future<void> _onSuccessComplete() async {
    if (widget.onPurchased != null) {
      await widget.onPurchased!();
    }
    if (mounted) Navigator.pop(context, true);
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
                        if (!_hasCourseAccess) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD58A),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFFB45309),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Preview only. Purchase this course to join meetings, view materials, download files, and take assessments.',
                                    style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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
                              file:
                                  _filesByLessonId[lesson['lesson_id'] as int],
                              hasAccess: _hasCourseAccess,
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
                              assessment: a,
                              title: a['title'] ?? 'Assessment',
                              passing:
                                  'Passing Marks: ${a['passing_mark'] ?? 'N/A'}%',
                              deadline: 'Deadline: ${_fmtDate(a['dead_line'])}',
                              isCompleted: _completedAssessmentIds.contains(
                                a['assessment_id'] as int,
                              ),
                              hasAccess: _hasCourseAccess,
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
    dynamic file,
    required bool hasAccess,
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
                  onPressed: hasAccess
                      ? () => _openMeetLink(meetLink)
                      : _showPurchaseRequiredMessage,
                  icon: Icon(
                    hasAccess ? Icons.video_call : Icons.lock_outline,
                    size: 18,
                  ),
                  label: Text(hasAccess ? 'Go to GMeet' : 'Locked'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasAccess
                        ? const Color(0xFF5B6FF5)
                        : Colors.grey.shade300,
                    foregroundColor: hasAccess
                        ? Colors.white
                        : Colors.grey.shade700,
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
          if (file != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 18,
                  color: Color(0xFF5B6FF5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Material: ${file['file_name'] ?? 'File'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5B6FF5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: hasAccess
                      ? () => _viewMaterial(file)
                      : _showPurchaseRequiredMessage,
                  icon: Icon(
                    hasAccess ? Icons.visibility_outlined : Icons.lock_outline,
                    size: 16,
                  ),
                  label: Text(hasAccess ? 'View' : 'Locked'),
                  style: TextButton.styleFrom(
                    foregroundColor: hasAccess
                        ? const Color(0xFF5B6FF5)
                        : Colors.grey.shade600,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: hasAccess
                      ? () => _downloadMaterial(file, lessonTitle: title)
                      : _showPurchaseRequiredMessage,
                  icon: const Icon(Icons.download_outlined, size: 20),
                  color: hasAccess
                      ? const Color(0xFF5B6FF5)
                      : Colors.grey.shade500,
                  tooltip: 'Download',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _viewMaterial(dynamic file) async {
    final url = file['file_path'] as String?;
    final uri = url == null ? null : Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file URL available')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this material')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this material')),
      );
    }
  }

  Future<void> _downloadMaterial(
    dynamic file, {
    required String lessonTitle,
  }) async {
    final url = file['file_path'] as String?;
    final fileName = _safeFileName(
      file['file_name'] as String? ?? 'material.pdf',
    );
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file URL available')));
      return;
    }

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Downloading material...')),
    );

    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          [],
          (a, b) => a..addAll(b),
        );
        final dir = await _downloadedMaterialsDir();
        final savePath = '${dir.path}/$fileName';
        await File(savePath).writeAsBytes(bytes);
        scaffold.showSnackBar(
          SnackBar(content: Text('Downloaded "$fileName" from $lessonTitle')),
        );
      } else {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Download failed: server error')),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Widget _assessmentTile({
    required dynamic assessment,
    required String title,
    required String passing,
    required String deadline,
    required bool isCompleted,
    required bool hasAccess,
  }) {
    return GestureDetector(
      onTap: isCompleted || !hasAccess
          ? null
          : () {
              showDialog(
                context: context,
                builder: (_) => AssessmentQuizDialog(
                  assessmentId: assessment['assessment_id'] as int,
                  courseId: widget.course.id,
                  assessmentTitle: title,
                  passingMark: assessment['passing_mark'] ?? 70,
                ),
              );
            },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!hasAccess)
                  const Icon(Icons.lock_outline, color: Colors.grey)
                else
                  const Icon(Icons.chevron_right, color: Color(0xFF5B6FF5)),
              ],
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
            if (!hasAccess) ...[
              const SizedBox(height: 8),
              const Text(
                'Purchase required to attempt this assessment.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
