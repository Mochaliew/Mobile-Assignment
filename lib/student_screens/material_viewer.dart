import 'dart:io';

import 'package:flutter/material.dart';

import 'file_opener.dart';

class MaterialViewer extends StatefulWidget {
  final File file;

  const MaterialViewer({super.key, required this.file});

  @override
  State<MaterialViewer> createState() => _MaterialViewerState();
}

class _MaterialViewerState extends State<MaterialViewer> {
  bool _isLoading = true;
  String? _error;
  List<String> _pagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (!widget.file.path.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _isLoading = false;
        _error = 'This material type can only be opened with another app.';
      });
      return;
    }

    try {
      final pages = await FileOpener.renderPdfPages(widget.file);
      if (!mounted) return;
      setState(() {
        _pagePaths = pages;
        _isLoading = false;
        _error = pages.isEmpty ? 'No PDF pages were found.' : null;
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to preview this PDF.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.uri.pathSegments.last;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(fileName, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => FileOpener.open(widget.file),
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open externally',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _pagePaths.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.file(
                    File(_pagePaths[index]),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
    );
  }
}
