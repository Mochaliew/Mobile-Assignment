// --- Course Detail Screen ----------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import '../DB.dart';
import 'create_lesson.dart';
import 'edit_lesson.dart';
import 'create_assessment.dart';
import 'view_assessment.dart';

class CourseDetail extends StatefulWidget {
  final int courseId;
  const CourseDetail({super.key, required this.courseId});

  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  Course? _course;
  List<Lesson> _lessons = [];
  List<Assessment> _assessments = [];
  List<FinalExam> _finalExams = [];
  List<Category> _categories = [];

  bool _editingInfo = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _editCategoryId;

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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchCourse(),
        _fetchLessons(),
        _fetchAssessments(),
        _fetchFinalExams(),
        _fetchCategories(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCourse() async {
    final response = await supabase
        .from('courses')
        .select('*, categories(name), enrollments(enrollment_id)')
        .eq('course_id', widget.courseId)
        .single();
    _course = Course.fromJson(response);
    _titleController.text = _course!.title;
    _descController.text = _course!.description;
    _editCategoryId = _course!.categoryId;
  }

  Future<void> _fetchLessons() async {
    final response = await supabase
        .from('lessons')
        .select()
        .eq('course_id', widget.courseId)
        .order('schedule_date', nullsFirst: false)
        .order('title');

    final lessons = <Lesson>[];
    for (final lm in response as List) {
      final lesson = Lesson.fromJson(lm as Map<String, dynamic>);
      final filesRes = await supabase
          .from('course_files')
          .select()
          .eq('lesson_id', lesson.lessonId);
      final List<CourseFile> files = (filesRes as List)
          .map((m) => CourseFile.fromJson(m as Map<String, dynamic>))
          .toList();
      lessons.add(Lesson(
        lessonId: lesson.lessonId,
        courseId: lesson.courseId,
        courseName: lesson.courseName,
        title: lesson.title,
        description: lesson.description,
        meetLink: lesson.meetLink,
        scheduleDate: lesson.scheduleDate,
        files: files,
      ));
    }
    _lessons = lessons;
  }

  Future<void> _fetchAssessments() async {
    final response = await supabase
        .from('assessments')
        .select()
        .eq('course_id', widget.courseId)
        .order('assessment_id', ascending: false);

    final assessments = <Assessment>[];
    for (final am in response as List) {
      final a = Assessment.fromJson(am as Map<String, dynamic>);
      final qRes = await supabase
          .from('assessment_questions')
          .select()
          .eq('assessment_id', a.assessmentId);
      assessments.add(Assessment(
        assessmentId: a.assessmentId,
        courseId: a.courseId,
        courseName: a.courseName,
        title: a.title,
        totalMarks: a.totalMarks,
        passingMark: a.passingMark,
        deadline: a.deadline,
        questions: (qRes as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));
    }
    _assessments = assessments;
  }

  Future<void> _fetchFinalExams() async {
    final response = await supabase
        .from('final_exams')
        .select()
        .eq('course_id', widget.courseId)
        .order('final_id', ascending: false);

    final finals = <FinalExam>[];
    for (final fm in response as List) {
      final f = FinalExam.fromJson(fm as Map<String, dynamic>);
      final qRes = await supabase
          .from('final_questions')
          .select()
          .eq('final_id', f.finalId);
      finals.add(FinalExam(
        finalId: f.finalId,
        courseId: f.courseId,
        courseName: f.courseName,
        title: f.title,
        totalMarks: f.totalMarks,
        passingMark: f.passingMark,
        deadline: f.deadline,
        questions: (qRes as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));
    }
    _finalExams = finals;
  }

  Future<void> _fetchCategories() async {
    final response =
    await supabase.from('categories').select().order('name');
    final data = List<Map<String, dynamic>>.from(response);
    _categories = data.map((e) => Category.fromJson(e)).toList();
  }

  Future<void> _saveInfo() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty || _editCategoryId == null) {
      snackbar('Please fill in all fields.', Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('courses').update({
        'title': title,
        'category_id': _editCategoryId,
        'description': desc,
      }).eq('course_id', widget.courseId);

      snackbar('Course updated successfully.');
      setState(() => _editingInfo = false);
      await _fetchCourse();
    } catch (e) {
      snackbar('Error updating course: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Text('Delete "${lesson.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
      await supabase.from('course_files').delete().eq('lesson_id', lesson.lessonId);
      await supabase.from('lessons').delete().eq('lesson_id', lesson.lessonId);
      snackbar('Lesson deleted.');
      await _fetchLessons();
    } catch (e) {
      snackbar('Error deleting lesson: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssessment(Assessment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: Text('Delete "${a.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      setState(() => _isLoading = true);
      await supabase.from('assessment_questions').delete().eq('assessment_id', a.assessmentId);
      await supabase.from('assessments').delete().eq('assessment_id', a.assessmentId);
      snackbar('Assessment deleted.');
      await _fetchAssessments();
    } catch (e) {
      snackbar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFinalExam(FinalExam f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Final Exam?'),
        content: Text('Delete "${f.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      setState(() => _isLoading = true);
      await supabase.from('final_questions').delete().eq('final_id', f.finalId);
      await supabase.from('final_exams').delete().eq('final_id', f.finalId);
      snackbar('Final exam deleted.');
      await _fetchFinalExams();
    } catch (e) {
      snackbar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.title ?? 'Course Detail',
            overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _course == null
          ? const Center(child: Text('Course not found.'))
          : RefreshIndicator(
        onRefresh: _fetchAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildCourseInfo(),
            _buildLessonsSection(),
            _buildAssessmentsSection(),
            _buildFinalExamsSection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    final c = _course!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Course Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => setState(() => _editingInfo = !_editingInfo),
              child: Text(_editingInfo ? 'Cancel' : 'Edit'),
            ),
          ]),
          const Divider(),
          if (!_editingInfo) ...[
            _InfoRow('Title', c.title),
            _InfoRow('Category', c.categoryName.isEmpty ? 'N/A' : c.categoryName),
            _InfoRow('Description', c.description),
            _InfoRow('Price', 'RM ${c.price.toStringAsFixed(2)}'),
            _InfoRow('Students Enrolled', c.enrollmentCount.toString()),
            const SizedBox(height: 8),
            _StatusBadge(isApproved: c.isApproved, isRejected: c.isRejected),
            if (c.isRejected && c.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(6)),
                child: Text('⚠️ Reason: ${c.rejectionReason}', style: const TextStyle(color: Color(0xFF856404))),
              ),
            ],
          ] else ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _editCategoryId,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((cat) => DropdownMenuItem(value: cat.categoryId, child: Text(cat.name))).toList(),
              onChanged: (v) => setState(() => _editCategoryId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveInfo,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B6FF5), foregroundColor: Colors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildLessonsSection() => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Lessons (${_lessons.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateLesson(
                  courseId: widget.courseId, courseName: _course!.title)),
            ).then((_) => _fetchLessons()),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Lesson'),
          ),
        ]),
        const Divider(),
        _lessons.isEmpty
            ? const Text('No lessons yet.', style: TextStyle(color: Colors.grey))
            : Column(
          children: _lessons.map((l) => _LessonTile(
            lesson: l,
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditLesson(
                  lesson: l, courseName: _course!.title)),
            ).then((_) => _fetchLessons()),
            onDelete: () => _deleteLesson(l),
          )).toList(),
        ),
      ]),
    ),
  );

  Widget _buildAssessmentsSection() => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Assessments (${_assessments.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateAssessment(
                  courseId: widget.courseId, courseName: _course!.title)),
            ).then((_) => _fetchAssessments()),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create'),
          ),
        ]),
        const Divider(),
        _assessments.isEmpty
            ? const Text('No assessments yet.', style: TextStyle(color: Colors.grey))
            : Column(
          children: _assessments.map((a) => _ExamTile(
            title: a.title,
            questionCount: a.questions.length,
            passingMark: a.passingMark,
            deadline: a.deadline,
            onView: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ViewAssessment(assessment: a)),
            ),
            onDelete: () => _deleteAssessment(a),
          )).toList(),
        ),
      ]),
    ),
  );

  Widget _buildFinalExamsSection() => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Final Exams (${_finalExams.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateAssessment(
                  courseId: widget.courseId, courseName: _course!.title, isFinalExam: true)),
            ).then((_) => _fetchFinalExams()),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create'),
          ),
        ]),
        const Divider(),
        _finalExams.isEmpty
            ? const Text('No final exams yet.', style: TextStyle(color: Colors.grey))
            : Column(
          children: _finalExams.map((f) => _ExamTile(
            title: f.title,
            questionCount: f.questions.length,
            passingMark: f.passingMark,
            deadline: f.deadline,
            onView: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ViewAssessment(finalExam: f)),
            ),
            onDelete: () => _deleteFinalExam(f),
          )).toList(),
        ),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
      Expanded(child: Text(value)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isApproved, isRejected;
  const _StatusBadge({required this.isApproved, required this.isRejected});
  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    if (isRejected) { bg = const Color(0xFFF8D7DA); fg = const Color(0xFF721C24); label = 'Rejected'; }
    else if (isApproved) { bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); label = 'Approved'; }
    else { bg = const Color(0xFFFFF3CD); fg = const Color(0xFF856404); label = 'Pending Approval'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onEdit, onDelete;
  const _LessonTile({required this.lesson, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('📖 ${lesson.title}', style: const TextStyle(fontWeight: FontWeight.w600))),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
        TextButton(onPressed: onDelete, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
      ]),
      if (lesson.description.isNotEmpty)
        Text(lesson.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      if (lesson.meetLink.isNotEmpty)
        const Text('🔗 Meeting link attached', style: TextStyle(color: Color(0xFF5B6FF5), fontSize: 12)),
      if (lesson.scheduleDate != null)
        Text('📅 ${DateFormat('MMM dd, yyyy hh:mm a').format(lesson.scheduleDate!)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      if (lesson.files.isNotEmpty) ...[
        const SizedBox(height: 6),
        ...lesson.files.map((f) => Row(children: [
          Text(f.fileType == 'pdf' ? '📄 PDF' : '🎥 Video', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text('• ${DateFormat('MMM dd, yyyy').format(f.uploadedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
      ],
    ]),
  );
}

class _ExamTile extends StatelessWidget {
  final String title;
  final int questionCount, passingMark;
  final DateTime deadline;
  final VoidCallback onView, onDelete;
  const _ExamTile({
    required this.title, required this.questionCount, required this.passingMark,
    required this.deadline, required this.onView, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📝 $title', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('Questions: $questionCount  |  Passing: $passingMark%',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text('Deadline: ${DateFormat('MMM dd, yyyy hh:mm a').format(deadline)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ])),
      TextButton(onPressed: onView, child: const Text('View')),
      TextButton(onPressed: onDelete, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
    ]),
  );
}
