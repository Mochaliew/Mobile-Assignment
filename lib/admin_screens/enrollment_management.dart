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
  String filter = 'All';

  final filters = ['All', 'Paid', 'Unpaid'];

  @override
  void initState() {
    super.initState();
    fetchEnrollments();
  }

  Future<void> fetchEnrollments() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('enrollments').select(
          'enrollment_id, enrolled_at, payment_status, payment_method, amount_paid, students(users(full_name, email)), courses(title)');

      if (filter == 'Paid') {
        query = query.eq('payment_status', true);
      } else if (filter == 'Unpaid') {
        query = query.eq('payment_status', false);
      }

      final response =
      await query.order('enrolled_at', ascending: false);

      setState(() {
        enrollments = response;
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
            onPressed: fetchEnrollments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: filter,
              decoration: const InputDecoration(
                labelText: 'Filter Payment',
                border: OutlineInputBorder(),
              ),
              items: filters.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => filter = value);
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
                final student = e['students']?['users'];
                final course = e['courses'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: e['payment_status']
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        e['payment_status']
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(course?['title'] ?? 'Unknown Course'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student: ${student?['full_name'] ?? '-'}'),
                        Text('Email: ${student?['email'] ?? '-'}'),
                        Text('Payment: ${e['payment_method'] ?? '-'}'),
                        Text('Date: ${formatDate(e['enrolled_at'])}'),
                      ],
                    ),
                    trailing: Text(
                      'RM ${e['amount_paid'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e['payment_status']
                            ? Colors.green
                            : Colors.red,
                      ),
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