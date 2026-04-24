// lib/screens/edit_lesson.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import '../DB.dart';

class EditLesson extends StatefulWidget {
  final Lesson lesson;
  final String courseName;
  const EditLesson({super.key, required this.lesson, required this.courseName});

  @override
  State<EditLesson> createState() => _EditLessonState();
}

class _EditLessonState extends State<EditLesson> {
  final supabase = Supabase.instance.client;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _meetController;
  bool _isLoading = false;
  DateTime? _date;
  TimeOfDay? _time;
  String _newFileType = '';

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson.title);
    _descController = TextEditingController(text: widget.lesson.description);
    _meetController = TextEditingController(text: widget.lesson.meetLink);
    if (widget.lesson.scheduleDate != null) {
      _date = widget.lesson.scheduleDate;
      _time = TimeOfDay.fromDateTime(widget.lesson.scheduleDate!);
    }
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
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      snackbar('Title is required.', Colors.red);
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
      await supabase.from('lessons').update({
        'title': title,
        'description': _descController.text.trim(),
        'meet_link': _meetController.text.trim(),
        'schedule_date': schedule?.toIso8601String(),
      }).eq('lesson_id', widget.lesson.lessonId);

      snackbar('Lesson updated successfully.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      snackbar('Error updating lesson: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lesson'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
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
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_date == null ? 'Select Date' : DateFormat('dd/MM/yyyy').format(_date!)),
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

            // Existing files
            if (widget.lesson.files.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Existing Files', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.lesson.files.map((f) => Card(
                child: ListTile(
                  leading: Icon(f.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.video_file,
                      color: f.fileType == 'pdf' ? Colors.red : Colors.blue),
                  title: Text(f.fileType.toUpperCase()),
                  subtitle: Text('Uploaded ${DateFormat('MMM dd, yyyy').format(f.uploadedAt)}'),
                ),
              )),
            ],

            // Add new file
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _newFileType.isEmpty ? null : _newFileType,
              decoration: const InputDecoration(
                  labelText: 'Add New File (Optional)', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                DropdownMenuItem(value: 'video', child: Text('Video File')),
              ],
              onChanged: (v) => setState(() => _newFileType = v ?? ''),
            ),
            if (_newFileType.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => snackbar('Add file_picker package to enable file uploads.'),
                icon: const Icon(Icons.upload_file),
                label: Text(_newFileType == 'pdf' ? 'Choose PDF (max 50MB)' : 'Choose Video (max 500MB)'),
              ),
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
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}