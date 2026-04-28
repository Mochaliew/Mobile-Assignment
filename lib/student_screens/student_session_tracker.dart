import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSessionTracker {
  static final _supabase = Supabase.instance.client;

  static String _dateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _weekStart(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday % 7));
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static int _durationSeconds(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    final seconds = end.difference(start).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  static Future<void> startSession(int studentId) async {
    final openSession = await _supabase
        .from('student_sessions')
        .select('session_id')
        .eq('student_id', studentId)
        .isFilter('end_time', null)
        .order('start_time', ascending: false)
        .limit(1)
        .maybeSingle();

    if (openSession != null) return;

    final now = DateTime.now().toUtc();
    await _supabase.from('student_sessions').insert({
      'student_id': studentId,
      'start_time': now.toIso8601String(),
      'week_start_date': _dateOnly(_weekStart(now)),
      'duration_seconds': 0,
    });
  }

  static Future<void> endCurrentSession(int studentId) async {
    final openSession = await _supabase
        .from('student_sessions')
        .select('session_id, start_time')
        .eq('student_id', studentId)
        .isFilter('end_time', null)
        .order('start_time', ascending: false)
        .limit(1)
        .maybeSingle();

    if (openSession == null) return;

    final end = DateTime.now().toUtc();
    final start = _parseDateTime(openSession['start_time']);
    await _supabase
        .from('student_sessions')
        .update({
          'end_time': end.toIso8601String(),
          'duration_seconds': _durationSeconds(start, end),
        })
        .eq('session_id', openSession['session_id'] as int);
  }

  static Future<int> weeklyStudyMinutes(int studentId) async {
    final now = DateTime.now().toUtc();
    final sessions = await _supabase
        .from('student_sessions')
        .select('start_time, end_time, duration_seconds')
        .eq('student_id', studentId)
        .gte('week_start_date', _dateOnly(_weekStart(now)));

    final totalSeconds = sessions.fold<int>(0, (sum, session) {
      final storedDuration = session['duration_seconds'];
      if (storedDuration is num && storedDuration > 0) {
        return sum + storedDuration.round();
      }

      final start = _parseDateTime(session['start_time']);
      final end = _parseDateTime(session['end_time']) ?? now;
      return sum + _durationSeconds(start, end);
    });

    return (totalSeconds / 60).round();
  }
}
