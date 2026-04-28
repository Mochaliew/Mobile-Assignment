// --- Edit Lesson Screen ------------------------------------------------------
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../db.dart';

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
  
  PlatformFile? _pickedFile;

  List<CourseFile> _existingFiles = [];
  final List<CourseFile> _filesToDelete = [];

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
    _existingFiles = List.from(widget.lesson.files);
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

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _newFileType == 'pdf' ? ['pdf'] : ['mp4', 'mkv', 'mov'],
      );

      if (result != null) {
        setState(() => _pickedFile = result.files.first);
      }
    } catch (e) {
      snackbar('Error picking file: $e', Colors.red);
    }
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

  void _removeFileLocally(CourseFile file) {
    setState(() {
      _existingFiles.removeWhere((f) => f.courseFileId == file.courseFileId);
      _filesToDelete.add(file);
    });
    snackbar('File removed from list. Click Save Changes to confirm deletion.');
  }

  Future<void> _deleteLesson() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Text('Delete "${widget.lesson.title}" and all its materials? This cannot be undone.'),
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

    setState(() => _isLoading = true);
    try {
      // 1. Delete all materials from storage
      for (final file in widget.lesson.files) {
        try {
          final uri = Uri.parse(file.filePath);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('course-materials');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await supabase.storage.from('course-materials').remove([storagePath]);
          }
        } catch (_) {}
      }

      await supabase.from('course_files').delete().eq('lesson_id', widget.lesson.lessonId);
      await supabase.from('lessons').delete().eq('lesson_id', widget.lesson.lessonId);

      snackbar('Lesson deleted.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      snackbar('Error deleting lesson: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      for (final file in _filesToDelete) {
        await supabase.from('course_files').delete().eq('course_file_id', file.courseFileId);
        try {
          final uri = Uri.parse(file.filePath);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('course-materials');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await supabase.storage.from('course-materials').remove([storagePath]);
          }
        } catch (_) {}
      }

      await supabase.from('lessons').update({
        'title': title,
        'description': _descController.text.trim(),
        'meet_link': _meetController.text.trim(),
        'schedule_date': schedule?.toIso8601String(),
      }).eq('lesson_id', widget.lesson.lessonId);

      if (_pickedFile != null) {
        final lessonId = widget.lesson.lessonId;
        final fileExt = _pickedFile!.extension ?? '';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'lesson_$lessonId/$fileName';

        if (kIsWeb) {
          await supabase.storage.from('course-materials').uploadBinary(
            filePath,
            _pickedFile!.bytes!,
            fileOptions: FileOptions(contentType: _pickedFile!.extension == 'pdf' ? 'application/pdf' : 'video/mp4'),
          );
        } else {
          final file = File(_pickedFile!.path!);
          await supabase.storage.from('course-materials').upload(
            filePath,
            file,
            fileOptions: FileOptions(contentType: _pickedFile!.extension == 'pdf' ? 'application/pdf' : 'video/mp4'),
          );
        }

        final publicUrl = supabase.storage.from('course-materials').getPublicUrl(filePath);

        await supabase.from('course_files').insert({
          'lesson_id': lessonId,
          'file_path': publicUrl,
          'file_type': _newFileType,
          'file_name': _pickedFile!.name,
        });
      }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _deleteLesson,
            tooltip: 'Delete Lesson',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                if (_existingFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Existing Files', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._existingFiles.map((f) => Card(
                    child: ListTile(
                      leading: Icon(f.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.video_file,
                          color: f.fileType == 'pdf' ? Colors.red : Colors.blue),
                      title: Text(f.fileType.toUpperCase()),
                      subtitle: Text('Uploaded ${DateFormat('MMM dd, yyyy').format(f.uploadedAt)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => _removeFileLocally(f),
                        tooltip: 'Remove locally',
                      ),
                    ),
                  )),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _newFileType.isEmpty ? null : _newFileType,
                  decoration: const InputDecoration(
                      labelText: 'Add New File (Optional)', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                    DropdownMenuItem(value: 'video', child: Text('Video File')),
                  ],
                  onChanged: (v) => setState(() {
                    _newFileType = v ?? '';
                    _pickedFile = null;
                  }),
                ),
                if (_newFileType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_pickedFile == null 
                        ? (_newFileType == 'pdf' ? 'Choose PDF (max 50MB)' : 'Choose Video (max 500MB)')
                        : 'Selected: ${_pickedFile!.name}'),
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
                      child: const Text('Save Changes'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
