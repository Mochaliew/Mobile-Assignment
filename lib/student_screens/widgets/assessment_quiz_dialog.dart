// --- Assessment Quiz Dialog --------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../DB.dart';

class AssessmentQuizDialog extends StatefulWidget {
  final int assessmentId;
  final int courseId;
  final String assessmentTitle;
  final int passingMark;

  const AssessmentQuizDialog({
    super.key,
    required this.assessmentId,
    required this.courseId,
    required this.assessmentTitle,
    required this.passingMark,
  });

  @override
  State<AssessmentQuizDialog> createState() => _AssessmentQuizDialogState();
}

class _AssessmentQuizDialogState extends State<AssessmentQuizDialog> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _questions = [];

  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool _wasCorrect = false;
  bool _finished = false;
  bool _passed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await supabase
          .from('assessment_questions')
          .select('*')
          .eq('assessment_id', widget.assessmentId)
          .order('question_id');

      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;
    setState(() => _selectedAnswer = answer);
  }

  void _confirmAnswer() {
    if (_selectedAnswer == null) return;
    final correct = _questions[_currentIndex]['correct_answer'] as String;
    final isCorrect = _selectedAnswer!.toUpperCase() == correct.toUpperCase();

    setState(() {
      _hasAnswered = true;
      _wasCorrect = isCorrect;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _wasCorrect = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final percent = _questions.isEmpty
        ? 0
        : ((_score / _questions.length) * 100).round();
    final passed = percent >= widget.passingMark;

    setState(() {
      _finished = true;
      _passed = passed;
    });

    if (passed) {
      _awardCertificate();
    }
  }

  Future<void> _awardCertificate() async {
    final studentId = StudentSession.studentId;
    if (studentId == null) return;

    setState(() => _saving = true);
    try {
      // Check if certificate already exists for this student + assessment
      final existing = await supabase
          .from('certificates')
          .select('certificate_id')
          .eq('student_id', studentId)
          .eq('assesment_id', widget.assessmentId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('certificates').insert({
          'student_id': studentId,
          'course_id': widget.courseId,
          'assesment_id': widget.assessmentId,
          'issue_date': DateTime.now().toIso8601String(),
        });
      }

      // Record submission
      await supabase.from('assessment_submissions').insert({
        'student_id': studentId,
        'assessment_id': widget.assessmentId,
        'score': _score,
        'passed': true,
        'submitted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore errors
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _recordFailure() async {
    final studentId = StudentSession.studentId;
    if (studentId == null) return;
    try {
      await supabase.from('assessment_submissions').insert({
        'student_id': studentId,
        'assessment_id': widget.assessmentId,
        'score': _score,
        'passed': false,
        'submitted_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _finished
            ? _buildResult()
            : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.assessmentTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF5B6FF5)),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),
        // Question
        Text(
          q['question_detail'] ?? '',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        // Options
        _optionCard('A', q['answer_a'] ?? ''),
        const SizedBox(height: 10),
        _optionCard('B', q['answer_b'] ?? ''),
        const SizedBox(height: 10),
        _optionCard('C', q['answer_c'] ?? ''),
        const SizedBox(height: 10),
        _optionCard('D', q['answer_d'] ?? ''),
        const SizedBox(height: 20),
        // Feedback
        if (_hasAnswered)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _wasCorrect
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _wasCorrect ? Icons.check_circle : Icons.cancel,
                  color: _wasCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  _wasCorrect
                      ? 'Correct!'
                      : 'Incorrect. Correct answer: ${q['correct_answer']}',
                  style: TextStyle(
                    color: _wasCorrect
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hasAnswered
                ? _nextQuestion
                : (_selectedAnswer != null ? _confirmAnswer : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B6FF5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _hasAnswered
                  ? (_currentIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish')
                  : 'Confirm Answer',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionCard(String key, String text) {
    final isSelected = _selectedAnswer == key;
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;

    if (_hasAnswered) {
      final correct = _questions[_currentIndex]['correct_answer'] as String;
      if (key.toUpperCase() == correct.toUpperCase()) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.08);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.08);
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF5B6FF5);
      bgColor = const Color(0xFFEDE9FE);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(key),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected && !_hasAnswered
                    ? const Color(0xFF5B6FF5)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    color: isSelected && !_hasAnswered
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final percent = _questions.isEmpty
        ? 0
        : ((_score / _questions.length) * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _passed
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _passed ? Icons.emoji_events : Icons.school,
            size: 48,
            color: _passed ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _passed ? 'Congratulations!' : 'Assessment Completed',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'You scored $_score / ${_questions.length} ($percent%)',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          _passed
              ? 'You passed the assessment! A certificate has been awarded.'
              : 'You did not meet the passing score of ${widget.passingMark}%.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _passed ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        if (!_passed) ...[
          const SizedBox(height: 12),
          const Text(
            'You can retake this assessment later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () {
                    if (!_passed) _recordFailure();
                    Navigator.pop(context, _passed);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B6FF5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
