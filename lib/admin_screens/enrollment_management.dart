import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnrollmentManagement extends StatefulWidget {
  const EnrollmentManagement({super.key});

  @override
  State<EnrollmentManagement> createState() => _EnrollmentManagementState();
}

class _EnrollmentManagementState extends State<EnrollmentManagement> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> enrollments = [];

  String selectedCourse = 'All Courses';
  List<String> courseFilters = ['All Courses'];

  @override
  void initState() {
    super.initState();
    fetchCourses();
    fetchEnrollments();
  }

  Future<void> fetchCourses() async {
    try {
      final response = await supabase
          .from('courses')
          .select('title')
          .order('title', ascending: true);

      setState(() {
        courseFilters = [
          'All Courses',
          ...response.map<String>((c) => c['title'].toString()).toList(),
        ];
      });
    } catch (e) {
      showMessage('Error loading courses: $e');
    }
  }

  Future<void> fetchEnrollments() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('enrollments').select('''
        enrollment_id,
        enrolled_at,
        users(full_name, email),
        courses(title)
      ''');

      final response = await query.order('enrolled_at', ascending: false);

      List<dynamic> filtered = response;

      if (selectedCourse != 'All Courses') {
        filtered = response.where((e) {
          final course = e['courses'];
          return course?['title'] == selectedCourse;
        }).toList();
      }

      setState(() {
        enrollments = filtered;
      });
    } catch (e) {
      showMessage('Error loading enrollments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(String? value) {
    if (value == null) return '-';
    return value.replaceFirst('T', ' ').split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Enrollment Management'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              fetchCourses();
              fetchEnrollments();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedCourse,
              decoration: const InputDecoration(
                labelText: 'Filter Course',
                border: OutlineInputBorder(),
              ),
              items: courseFilters.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedCourse = value);
                fetchEnrollments();
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : enrollments.isEmpty
                ? const Center(child: Text('No enrollments found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final e = enrollments[index];
                final student = e['users'];
                final course = e['courses'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF5B6FF5),
                      child: Icon(Icons.school, color: Colors.white),
                    ),
                    title: Text(course?['title'] ?? 'Unknown Course'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student: ${student?['full_name'] ?? '-'}'),
                        Text('Email: ${student?['email'] ?? '-'}'),
                        Text('Date: ${formatDate(e['enrolled_at'])}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}