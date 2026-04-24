// lib/screens/create_lesson.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../DB.dart';

class CreateLesson extends StatefulWidget {
  final int courseId;
  final String courseName;
  const CreateLesson({super.key, required this.courseId, required this.courseName});

  @override
  State<CreateLesson> createState() => _CreateLessonState();
}

class _CreateLessonState extends State<CreateLesson> {
  final supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _meetController = TextEditingController();
  bool _isLoading = false;
  String _lessonType = '';
  DateTime? _date;
  TimeOfDay? _time;

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _meetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      snackbar('Title is required.', Colors.red);
      return;
    }
    if (_lessonType.isEmpty) {
      snackbar('Please select a lesson type.', Colors.red);
      return;
    }
    if (_lessonType == 'online' && _meetController.text.trim().isEmpty) {
      snackbar('Meeting link is required for online lessons.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    DateTime? schedule;
    if (_date != null) {
      schedule = DateTime(
        _date!.year, _date!.month, _date!.day,
        _time?.hour ?? 0, _time?.minute ?? 0,
      );
    }

    try {
      await supabase.from('lessons').insert({
        'course_id': widget.courseId,
        'title': title,
        'description': _descController.text.trim(),
        'meet_link': _lessonType == 'online' ? _meetController.text.trim() : '',
        'schedule_date': schedule?.toIso8601String(),
      });

      snackbar('Lesson created successfully.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      snackbar('Error creating lesson: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Lesson'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course name hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('Course: ${widget.courseName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5B6FF5))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Lesson Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_date == null ? 'Select Date' : '${_date!.day}/${_date!.month}/${_date!.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_time == null ? 'Select Time' : _time!.format(context)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _lessonType.isEmpty ? null : _lessonType,
              decoration: const InputDecoration(labelText: 'Lesson Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'online', child: Text('Online Meeting (Google Meet/Zoom)')),
                DropdownMenuItem(value: 'materials', child: Text('Upload Materials (PDF/Video)')),
              ],
              onChanged: (v) => setState(() => _lessonType = v ?? ''),
            ),
            if (_lessonType == 'online') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _meetController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_lessonType == 'materials') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => snackbar('Add file_picker package to enable file uploads.'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose File (PDF or Video)'),
              ),
              const SizedBox(height: 4),
              const Text('Max: PDF 50MB, Video 500MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Lesson'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}