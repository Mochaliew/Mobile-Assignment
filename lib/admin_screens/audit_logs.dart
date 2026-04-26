import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  String selectedModule = 'All';
  List<dynamic> logs = [];

  final modules = ['All', 'Teacher', 'Student', 'Course', 'Category'];

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('audit_logs').select();

      if (selectedModule != 'All') {
        query = query.ilike('action', '%$selectedModule%');
      }

      final response = await query.order('timestamp', ascending: false).limit(200);

      setState(() {
        logs = response;
      });
    } catch (e) {
      showMessage('Error loading audit logs: $e');
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
        title: const Text('Audit Logs'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchLogs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedModule,
              decoration: const InputDecoration(
                labelText: 'Filter Module',
                border: OutlineInputBorder(),
              ),
              items: modules.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedModule = value);
                fetchLogs();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                ? const Center(child: Text('No audit logs found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF5B6FF5),
                      child: Icon(Icons.history, color: Colors.white),
                    ),
                    title: Text(log['action'] ?? 'No action'),
                    subtitle: Text(
                      'Time: ${formatDate(log['timestamp'])}',
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