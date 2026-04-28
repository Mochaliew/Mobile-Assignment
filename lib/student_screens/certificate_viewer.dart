import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CertificateData {
  final String studentName;
  final String courseTitle;
  final String assessmentTitle;
  final String instructor;
  final String issueDate;

  const CertificateData({
    required this.studentName,
    required this.courseTitle,
    required this.assessmentTitle,
    required this.instructor,
    required this.issueDate,
  });
}

class CertificateViewer extends StatelessWidget {
  final CertificateData certificate;

  const CertificateViewer({super.key, required this.certificate});

  String _safeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'certificate' : sanitized;
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _html() {
    final studentName = _escapeHtml(certificate.studentName);
    final courseTitle = _escapeHtml(certificate.courseTitle);
    final assessmentTitle = _escapeHtml(certificate.assessmentTitle);
    final instructor = _escapeHtml(certificate.instructor);
    final issueDate = _escapeHtml(certificate.issueDate);

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Certificate - $studentName</title>
  <style>
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #f4f6fb; font-family: Arial, sans-serif; }
    .certificate { width: min(920px, 92vw); background: white; border: 12px solid #5B6FF5; padding: 56px; text-align: center; box-sizing: border-box; }
    .eyebrow { color: #5B6FF5; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; }
    h1 { margin: 18px 0 8px; font-size: 42px; color: #20243a; }
    .presented { margin-top: 36px; color: #6b7280; font-size: 18px; }
    .student { margin: 14px auto; font-size: 38px; font-weight: 700; color: #111827; border-bottom: 2px solid #d8dcff; width: fit-content; padding: 0 40px 8px; }
    .copy { color: #374151; font-size: 18px; line-height: 1.6; }
    .course { color: #5B6FF5; font-weight: 700; font-size: 22px; }
    .footer { display: flex; justify-content: space-between; gap: 24px; margin-top: 52px; color: #374151; text-align: left; }
    .line { border-top: 1px solid #9ca3af; padding-top: 8px; min-width: 210px; }
    @media print { body { background: white; } .certificate { width: 100%; border-color: #5B6FF5; } }
  </style>
</head>
<body>
  <section class="certificate">
    <div class="eyebrow">Certificate of Achievement</div>
    <h1>Certificate of Completion</h1>
    <p class="presented">This certificate is proudly presented to</p>
    <div class="student">$studentName</div>
    <p class="copy">for successfully passing <strong>$assessmentTitle</strong><br>in</p>
    <p class="course">$courseTitle</p>
    <div class="footer">
      <div class="line"><strong>$instructor</strong><br>Instructor</div>
      <div class="line"><strong>$issueDate</strong><br>Issue Date</div>
    </div>
  </section>
</body>
</html>
''';
  }

  Future<File> _saveCertificate() async {
    final dir = await getApplicationDocumentsDirectory();
    final certDir = Directory('${dir.path}/certificates');
    if (!await certDir.exists()) {
      await certDir.create(recursive: true);
    }

    final fileName =
        '${_safeFileName(certificate.studentName)}_${_safeFileName(certificate.assessmentTitle)}.html';
    final file = File('${certDir.path}/$fileName');
    return file.writeAsString(_html());
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await _saveCertificate();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Certificate saved: ${file.uri.pathSegments.last}'),
      ),
    );
  }

  Future<void> _share() async {
    final file = await _saveCertificate();
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Certificate'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _download(context),
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF5B6FF5), width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Certificate of Achievement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF5B6FF5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Certificate of Completion',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'This certificate is proudly presented to',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    certificate.studentName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'for successfully passing ${certificate.assessmentTitle} in',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    certificate.courseTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5B6FF5),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: _SignatureBlock(
                          label: 'Instructor',
                          value: certificate.instructor,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _SignatureBlock(
                          label: 'Issue Date',
                          value: certificate.issueDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String label;
  final String value;

  const _SignatureBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
