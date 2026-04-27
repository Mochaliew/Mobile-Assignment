import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final supabase = Supabase.instance.client;

  final platformName = TextEditingController();
  final primaryColor = TextEditingController();
  final storageType = TextEditingController();
  final maxUploadSize = TextEditingController();
  final allowedFileTypes = TextEditingController();
  final smtpHost = TextEditingController();
  final smtpPort = TextEditingController();
  final senderEmail = TextEditingController();

  bool enableEmailNotification = true;
  bool _isLoading = false;
  int? systemSettingId;

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  Future<void> addAuditLog(String action) async {
    await supabase.from('audit_logs').insert({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> fetchSettings() async {
    setState(() => _isLoading = true);

    try {
      final response =
      await supabase.from('system_settings').select().maybeSingle();

      if (response != null) {
        systemSettingId = response['system_setting_id'];
        platformName.text = response['platform_name'] ?? '';
        primaryColor.text = response['primary_color'] ?? '';
        storageType.text = response['storage_type'] ?? '';
        maxUploadSize.text = response['max_upload_size_mb'].toString();
        allowedFileTypes.text = response['allowed_file_types'] ?? '';
        smtpHost.text = response['smtp_host'] ?? '';
        smtpPort.text = response['smtp_port'].toString();
        senderEmail.text = response['sender_email'] ?? '';
        enableEmailNotification =
            response['enable_email_notification'] ?? true;
      }
    } catch (e) {
      showMessage('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> saveSettings() async {
    if (systemSettingId == null) {
      showMessage('System settings not found.');
      return;
    }

    try {
      await supabase.from('system_settings').update({
        'platform_name': platformName.text.trim(),
        'primary_color': primaryColor.text.trim(),
        'storage_type': storageType.text.trim(),
        'max_upload_size_mb': int.tryParse(maxUploadSize.text) ?? 50,
        'allowed_file_types': allowedFileTypes.text.trim(),
        'enable_email_notification': enableEmailNotification,
        'smtp_host': smtpHost.text.trim(),
        'smtp_port': int.tryParse(smtpPort.text) ?? 587,
        'sender_email': senderEmail.text.trim(),
      }).eq('system_setting_id', systemSettingId!);

      await addAuditLog('Updated system settings');

      showMessage('System settings updated successfully');
    } catch (e) {
      showMessage('Update failed: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    platformName.dispose();
    primaryColor.dispose();
    storageType.dispose();
    maxUploadSize.dispose();
    allowedFileTypes.dispose();
    smtpHost.dispose();
    smtpPort.dispose();
    senderEmail.dispose();
    super.dispose();
  }

  Widget input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchSettings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Platform Branding',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                input('Platform Name', platformName),
                input('Primary Color', primaryColor),

                const SizedBox(height: 16),
                const Text(
                  'Content Storage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                input('Storage Type', storageType),
                input('Max Upload Size MB', maxUploadSize),
                input('Allowed File Types', allowedFileTypes),

                const SizedBox(height: 16),
                const Text(
                  'Email Notification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Email Notification'),
                  value: enableEmailNotification,
                  onChanged: (value) {
                    setState(() => enableEmailNotification = value);
                  },
                ),
                input('SMTP Host', smtpHost),
                input('SMTP Port', smtpPort),
                input('Sender Email', senderEmail),

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}