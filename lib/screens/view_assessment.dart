// lib/screens/view_assessment.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DB.dart';

class ViewAssessment extends StatelessWidget {
  final Assessment? assessment;
  final FinalExam? finalExam;

  const ViewAssessment({super.key, this.assessment, this.finalExam})
      : assert(assessment != null || finalExam != null,
  'Must provide either assessment or finalExam');

  // Helpers to unify access
  bool get _isFinal => finalExam != null;
  String get _title => _isFinal ? finalExam!.title : assessment!.title;
  int get _totalMarks => _isFinal ? finalExam!.totalMarks : assessment!.totalMarks;
  int get _passingMark => _isFinal ? finalExam!.passingMark : assessment!.passingMark;
  DateTime get _deadline => _isFinal ? finalExam!.deadline : assessment!.deadline;
  List<Question> get _questions => _isFinal ? finalExam!.questions : assessment!.questions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFinal ? 'Final Exam Details' : 'Assessment Details'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary card ────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isFinal ? '📋 ' : '📝 ',
                          style: const TextStyle(fontSize: 24),
                        ),
                        Expanded(
                          child: Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Deadline',
                        DateFormat('MMM dd, yyyy hh:mm a').format(_deadline)),
                    _InfoRow('Total Marks', '$_totalMarks'),
                    _InfoRow('Passing Mark', '$_passingMark%'),
                    _InfoRow('Total Questions', _questions.length.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Questions ───────────────────────────────────────────────
            Text(
              'Questions (${_questions.length})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _questions.isEmpty
                ? const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No questions found.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
                : Column(
              children: _questions.asMap().entries.map((e) {
                final q = e.value;
                final num = e.key + 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q$num. ${q.questionDetail}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        ...['A', 'B', 'C', 'D'].map((opt) {
                          final text = opt == 'A'
                              ? q.answerA
                              : opt == 'B'
                              ? q.answerB
                              : opt == 'C'
                              ? q.answerC
                              : q.answerD;
                          final isCorrect = q.correctAnswer == opt;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFFD4EDDA)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCorrect
                                    ? const Color(0xFFC3E6CB)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isCorrect
                                      ? const Color(0xFF155724)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$opt. $text',
                                    style: TextStyle(
                                      color: isCorrect
                                          ? const Color(0xFF155724)
                                          : Colors.black87,
                                      fontWeight: isCorrect
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Course'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}