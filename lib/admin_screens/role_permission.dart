import 'package:flutter/material.dart';

class RolePermissionScreen extends StatelessWidget {
  const RolePermissionScreen({super.key});

  final List<Map<String, dynamic>> roles = const [
    {
      'role': 'Admin',
      'icon': Icons.admin_panel_settings,
      'permissions': [
        'Manage system settings',
        'Approve or reject courses',
        'Manage teachers and students',
        'View reports and statistics',
      ],
    },
    {
      'role': 'Teacher',
      'icon': Icons.person,
      'permissions': [
        'Create courses',
        'Upload learning materials',
        'Create assessments',
      ],
    },
    {
      'role': 'Student',
      'icon': Icons.school,
      'permissions': [
        'Enroll in courses',
        'Access learning materials',
        'Download certificates',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Role & Permission'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ExpansionTile(
              leading: Icon(role['icon']),
              title: Text(
                role['role'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                ...List<String>.from(role['permissions']).map(
                      (permission) => ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(permission),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}