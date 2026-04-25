// --- Create Assessment Screen ------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../DB.dart';

class CreateAssessment extends StatefulWidget {
  final int courseId;
  final String courseName;
  final bool isFinalExam;

  const CreateAssessment({
    super.key,
    required this.courseId,
    required this.courseName,
    this.isFinalExam = false,
  });

  @override
  State<CreateAssessment> createState() => _CreateAssessmentState();
}

class _CreateAssessmentState extends State<CreateAssessment> {
  final supabase = Supabase.instance.client;

  int _step = 1;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _passingMarkController = TextEditingController(text: '70');
  DateTime? _deadline;

  final List<QuestionForm> _questions = [QuestionForm()];

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passingMarkController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted) return;
    setState(() {
      _deadline = DateTime(d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59);
    });
  }

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) { snackbar('Title is required.', Colors.red); return false; }
    final pm = int.tryParse(_passingMarkController.text);
    if (pm == null || pm < 0 || pm > 100) { snackbar('Enter a valid passing mark (0–100).', Colors.red); return false; }
    if (_deadline == null) { snackbar('Please select a deadline.', Colors.red); return false; }
    return true;
  }

  bool _validateStep2() {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionDetail.isEmpty) { snackbar('Enter question text for Q${i + 1}.', Colors.red); return false; }
      if (q.answerA.isEmpty || q.answerB.isEmpty || q.answerC.isEmpty || q.answerD.isEmpty) { snackbar('Fill all 4 options for Q${i + 1}.', Colors.red); return false; }
      if (q.correctAnswer.isEmpty) { snackbar('Select correct answer for Q${i + 1}.', Colors.red); return false; }
    }
    return true;
  }

  Future<void> _publish() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isFinalExam) {
        final res = await supabase.from('final_exams').insert({
          'course_id': widget.courseId,
          'title': _titleController.text.trim(),
          'total_marks': _questions.length,
          'passing_mark': int.parse(_passingMarkController.text),
          'dead_line': _deadline!.toIso8601String(),
        }).select().single();

        final finalId = res['final_id'];
        for (final q in _questions) {
          await supabase.from('final_questions').insert({
            'final_id': finalId,
            'question_detail': q.questionDetail,
            'answer_a': q.answerA,
            'answer_b': q.answerB,
            'answer_c': q.answerC,
            'answer_d': q.answerD,
            'correct_answer': q.correctAnswer,
          });
        }
      } else {
        final res = await supabase.from('assessments').insert({
          'course_id': widget.courseId,
          'title': _titleController.text.trim(),
          'total_marks': _questions.length,
          'passing_mark': int.parse(_passingMarkController.text),
          'dead_line': _deadline!.toIso8601String(),
        }).select().single();

        final assessmentId = res['assessment_id'];
        for (final q in _questions) {
          await supabase.from('assessment_questions').insert({
            'assessment_id': assessmentId,
            'question_detail': q.questionDetail,
            'answer_a': q.answerA,
            'answer_b': q.answerB,
            'answer_c': q.answerC,
            'answer_d': q.answerD,
            'correct_answer': q.correctAnswer,
          });
        }
      }

      snackbar('${widget.isFinalExam ? "Final exam" : "Assessment"} published successfully!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      snackbar('Error publishing: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFinalExam ? 'Create Final Exam' : 'Create Assessment'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (i) {
                final stepNum = i + 1;
                final labels = ['Basic Info', 'Questions', 'Preview'];
                final done = stepNum <= _step;
                return Expanded(
                  child: Row(
                    children: [
                      Column(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: done ? const Color(0xFF5B6FF5) : Colors.grey.shade300,
                          child: Text('$stepNum', style: TextStyle(color: done ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Text(labels[i], style: TextStyle(fontSize: 11, color: done ? const Color(0xFF5B6FF5) : Colors.grey)),
                      ]),
                      if (i < 2)
                        Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20), color: stepNum < _step ? const Color(0xFF5B6FF5) : Colors.grey.shade300)),
                    ],
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _step == 1 ? _buildStep1() : _step == 2 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: widget.isFinalExam ? 'Final Exam Title' : 'Assessment Title',
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passingMarkController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Passing Mark (%)',
          suffixText: '%',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _pickDeadline,
        icon: const Icon(Icons.calendar_month),
        label: Text(_deadline == null
            ? 'Select Deadline Date & Time'
            : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () { if (_validateStep1()) setState(() => _step = 2); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B6FF5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Next: Add Questions'),
          ),
        ),
      ]),
    ],
  );

  Widget _buildStep2() => Column(
    children: [
      ..._questions.asMap().entries.map((e) => _QuestionCard(
        index: e.key,
        form: e.value,
        canRemove: _questions.length > 1,
        onRemove: () => setState(() => _questions.removeAt(e.key)),
      )),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _questions.add(QuestionForm())),
          icon: const Icon(Icons.add),
          label: const Text('+ Add Another Question'),
        ),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back'))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () { if (_validateStep2()) setState(() => _step = 3); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B6FF5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Next: Preview'),
          ),
        ),
      ]),
    ],
  );

  Widget _buildStep3() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        color: const Color(0xFFF0F2FF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _PreviewRow('Title', _titleController.text),
            _PreviewRow('Questions', _questions.length.toString()),
            _PreviewRow('Passing Mark', '${_passingMarkController.text}%'),
            _PreviewRow('Deadline', _deadline != null
                ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                : '-'),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      ..._questions.asMap().entries.map((e) {
        final q = e.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Q${e.key + 1}. ${q.questionDetail}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...['A', 'B', 'C', 'D'].map((opt) {
                final text = opt == 'A' ? q.answerA : opt == 'B' ? q.answerB : opt == 'C' ? q.answerC : q.answerD;
                final isCorrect = q.correctAnswer == opt;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFD4EDDA) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$opt. $text',
                      style: TextStyle(
                          color: isCorrect ? const Color(0xFF155724) : Colors.black87,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal)),
                );
              }),
            ]),
          ),
        );
      }),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 2), child: const Text('Back'))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _publish,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Publish ${widget.isFinalExam ? "Final Exam" : "Assessment"}'),
          ),
        ),
      ]),
    ],
  );
}

class _PreviewRow extends StatelessWidget {
  final String label, value;
  const _PreviewRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
      Expanded(flex: 3, child: Text(value)),
    ]),
  );
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final QuestionForm form;
  final bool canRemove;
  final VoidCallback onRemove;

  const _QuestionCard({
    required this.index,
    required this.form,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late TextEditingController _qCtrl, _aCtrl, _bCtrl, _cCtrl, _dCtrl;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.form.questionDetail);
    _aCtrl = TextEditingController(text: widget.form.answerA);
    _bCtrl = TextEditingController(text: widget.form.answerB);
    _cCtrl = TextEditingController(text: widget.form.answerC);
    _dCtrl = TextEditingController(text: widget.form.answerD);
  }

  @override
  void dispose() {
    _qCtrl.dispose(); _aCtrl.dispose(); _bCtrl.dispose();
    _cCtrl.dispose(); _dCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Question ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B6FF5), fontSize: 15)),
            if (widget.canRemove)
              TextButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _qCtrl,
            maxLines: 2,
            onChanged: (v) => widget.form.questionDetail = v,
            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          const Text('Options (select the correct answer):', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          ...['A', 'B', 'C', 'D'].map((opt) {
            final ctrl = opt == 'A' ? _aCtrl : opt == 'B' ? _bCtrl : opt == 'C' ? _cCtrl : _dCtrl;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Radio<String>(
                  value: opt,
                  groupValue: widget.form.correctAnswer,
                  activeColor: const Color(0xFF5B6FF5),
                  onChanged: (v) => setState(() => widget.form.correctAnswer = v ?? ''),
                ),
                SizedBox(width: 28, child: Text('$opt:', style: const TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onChanged: (v) {
                      if (opt == 'A') widget.form.answerA = v;
                      else if (opt == 'B') widget.form.answerB = v;
                      else if (opt == 'C') widget.form.answerC = v;
                      else widget.form.answerD = v;
                    },
                    decoration: InputDecoration(
                      hintText: 'Option $opt',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ]),
            );
          }),
          if (widget.form.correctAnswer.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFD4EDDA), borderRadius: BorderRadius.circular(4)),
              child: Text('✅ Correct: ${widget.form.correctAnswer}',
                  style: const TextStyle(color: Color(0xFF155724), fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}
