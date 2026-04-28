// --- Student Profile (Database-driven) ---------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db.dart';
import '../teacher_screens/teacher_login.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  final supabase = Supabase.instance.client;
  int _selectedTab = 0; // 0 = Achievements, 1 = Notes
  bool _isLoading = true;

  List<dynamic> _notes = [];
  List<dynamic> _certificates = [];

  String _name = '';
  String _about = '';
  final String _className = 'Class 9A';

  String _loginStreak = '0 days';
  String _weeklyStudyHours = '0 hrs';
  String _courseProgressPercent = '0%';

  int? _editingIndex; // null = not editing, -1 = adding new
  final TextEditingController _editController = TextEditingController();

  final List<Color> _noteColors = const [
    Color(0xFFFFF9C4),
    Color(0xFFFCE4EC),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final studentId = StudentSession.studentId;
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final studentData = await supabase
          .from('students')
          .select('*, users(full_name)')
          .eq('student_id', studentId)
          .maybeSingle();

      final notesData = await supabase
          .from('student_notes')
          .select('*')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      final certificatesData = await supabase
          .from('certificates')
          .select('''
            *,
            courses(title, teachers(user_id, users(full_name))),
            assessments(title)
          ''')
          .eq('student_id', studentId)
          .order('issue_date', ascending: false);

      // Calculate login streak from student_login_history
      String streakText = '0 days';
      try {
        final logins = await supabase
            .from('student_login_history')
            .select('login_date')
            .eq('student_id', studentId)
            .order('login_date', ascending: false);
        final dates = logins
            .map((l) => DateTime.parse(l['login_date'] as String))
            .toList();
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        int streak = 0;
        for (int i = 0; i < dates.length; i++) {
          final expected = today.subtract(Duration(days: i));
          if (dates[i].year == expected.year &&
              dates[i].month == expected.month &&
              dates[i].day == expected.day) {
            streak++;
          } else {
            break;
          }
        }
        streakText = '$streak day${streak == 1 ? '' : 's'}';
      } catch (_) {}

      // Calculate weekly study time from student_sessions
      String studyText = '0 hrs';
      try {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday % 7));
        final sessions = await supabase
            .from('student_sessions')
            .select('duration_seconds')
            .eq('student_id', studentId)
            .gte('week_start_date', weekStart.toIso8601String());
        final totalSeconds = sessions.fold<int>(
          0,
          (sum, s) => sum + ((s['duration_seconds'] ?? 0) as int),
        );
        final hours = totalSeconds / 3600;
        studyText = '${hours.toStringAsFixed(1)} hrs';
      } catch (_) {}

      // Calculate overall progress: completed assessments / total assessments
      String progressText = '0%';
      try {
        final totalRes = await supabase
            .from('assessments')
            .select('assessment_id');
        final total = totalRes.length;

        final completedRes = await supabase
            .from('certificates')
            .select('certificate_id')
            .eq('student_id', studentId)
            .not('assesment_id', 'is', null);
        final completed = completedRes.length;

        if (total > 0) {
          final pct = ((completed / total) * 100).round();
          progressText = '$pct%';
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _name =
              studentData?['users']?['full_name'] ??
              StudentSession.studentName ??
              'Student';
          _about = studentData?['about'] ?? '';
          _notes = notesData;
          _certificates = certificatesData;
          _loginStreak = streakText;
          _weeklyStudyHours = studyText;
          _courseProgressPercent = progressText;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _logout() async {
    final studentId = StudentSession.studentId;
    if (studentId != null) {
      try {
        final openSession = await supabase
            .from('student_sessions')
            .select('session_id, start_time')
            .eq('student_id', studentId)
            .isFilter('end_time', null)
            .order('start_time', ascending: false)
            .limit(1)
            .maybeSingle();
        if (openSession != null) {
          final start = DateTime.parse(openSession['start_time'] as String);
          final end = DateTime.now();
          final duration = end.difference(start).inSeconds;
          await supabase
              .from('student_sessions')
              .update({
                'end_time': end.toIso8601String(),
                'duration_seconds': duration,
              })
              .eq('session_id', openSession['session_id'] as int);
        }
      } catch (_) {}
    }
    StudentSession.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLogin()),
      (route) => false,
    );
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text = _notes[index]['content'] ?? '';
    });
  }

  void _startAdd() {
    setState(() {
      _editingIndex = -1;
      _editController.clear();
    });
  }

  Future<void> _saveNote() async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;

    final studentId = StudentSession.studentId;
    if (studentId == null) return;

    try {
      if (_editingIndex == -1) {
        // Insert new
        final colorHex = _hexFromColor(
          _noteColors[_notes.length % _noteColors.length],
        );
        await supabase.from('student_notes').insert({
          'student_id': studentId,
          'content': text,
          'color': colorHex,
        });
      } else if (_editingIndex != null && _editingIndex! >= 0) {
        // Update existing
        final noteId = _notes[_editingIndex!]['note_id'];
        await supabase
            .from('student_notes')
            .update({'content': text})
            .eq('note_id', noteId);
      }

      _editController.clear();
      _editingIndex = null;
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _editController.clear();
    });
  }

  Future<void> _deleteNote(int index) async {
    final noteId = _notes[index]['note_id'];
    try {
      await supabase.from('student_notes').delete().eq('note_id', noteId);
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  String _hexFromColor(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFFFF9C4);
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
              _certInfo('Course', course),
              const SizedBox(height: 16),
              _certInfo('Instructor', instructor),
              const SizedBox(height: 16),
              _certInfo('Issue Date', date),
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

  Widget _certInfo(String label, String value) {
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

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
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
          'Profile',
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
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 50),
              _buildAboutCard(),
              const SizedBox(height: 16),
              _buildTabSwitcher(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _selectedTab == 0 ? _buildAchievements() : _buildNotes(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: const Color(0xFF5B6FF5),
            padding: const EdgeInsets.only(left: 16, top: 0),
            child: const SafeArea(child: SizedBox.shrink()),
          ),
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, size: 32, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _className,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _about.isNotEmpty ? _about : 'No about information yet.',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? Colors.grey.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Achievements',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: _selectedTab == 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? Colors.grey.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Notes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: _selectedTab == 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsCard(),
        const SizedBox(height: 16),
        _buildCertificatesCard(),
      ],
    );
  }

  Widget _buildStatsCard() {
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
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                Icons.local_fire_department,
                Colors.orange,
                _loginStreak,
                'Login Streak',
              ),
              _statItem(
                Icons.access_time,
                Colors.blue,
                _weeklyStudyHours,
                'Weekly Study\nTime',
              ),
              _statItem(
                Icons.trending_up,
                Colors.green,
                _courseProgressPercent,
                'Course Progress',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCertificatesCard() {
    if (_certificates.isEmpty) return const SizedBox.shrink();

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
          const Text(
            'Certificates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._certificates.asMap().entries.map((entry) {
            final cert = entry.value;
            final assessmentTitle = cert['assessments']?['title'];
            final course = cert['courses'];
            final title = assessmentTitle ?? course?['title'] ?? 'Course';
            final instructor =
                course?['teachers']?['users']?['full_name'] ?? 'Unknown';
            final issueDate = cert['issue_date'] != null
                ? DateTime.tryParse(cert['issue_date'])
                : null;
            final dateText = issueDate != null ? _fmtDate(issueDate) : 'N/A';
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < _certificates.length - 1 ? 10 : 0,
              ),
              child: _certificateTile(title, instructor, dateText),
            );
          }),
        ],
      ),
    );
  }

  Widget _certificateTile(String title, String instructor, String date) {
    return GestureDetector(
      onTap: () => _showCertificateDialog(title, instructor, date),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF5B6FF5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._notes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              if (_editingIndex == index) {
                return _buildEditingCard(_colorFromHex(note['color']));
              }
              return _buildNoteCard(note, index);
            }),
            if (_editingIndex == -1) _buildEditingCard(Colors.grey.shade100),
            if (_editingIndex == null) _buildAddNoteCard(),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteCard(dynamic note, int index) {
    final color = _colorFromHex(note['color']);
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note['content'] ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _smallButton(
                icon: Icons.edit,
                label: 'Edit',
                foreground: Colors.grey.shade700,
                background: Colors.white.withOpacity(0.8),
                onTap: () => _startEdit(index),
              ),
              const SizedBox(width: 8),
              _smallButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                foreground: Colors.red,
                background: Colors.red.withOpacity(0.08),
                onTap: () => _deleteNote(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditingCard(Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _editController,
            maxLines: 3,
            decoration: const InputDecoration.collapsed(
              hintText: 'Type your note...',
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _smallButton(
                icon: Icons.check,
                label: _editingIndex == -1 ? 'Add' : 'Save',
                foreground: Colors.white,
                background: _editingIndex == -1
                    ? const Color(0xFF5B6FF5)
                    : Colors.green,
                onTap: _saveNote,
              ),
              const SizedBox(width: 8),
              _smallButton(
                icon: Icons.close,
                label: 'Cancel',
                foreground: Colors.white,
                background: Colors.grey.shade700,
                onTap: _cancelEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddNoteCard() {
    return GestureDetector(
      onTap: _startAdd,
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DashedBorder(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Add Note', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: foreground,
                fontWeight: FontWeight.w500,
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

// --- Dashed Border Widget ----------------------------------------------------
class DashedBorder extends StatelessWidget {
  final Widget child;
  const DashedBorder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}
