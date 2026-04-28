// --- Downloaded Materials ----------------------------------------------------
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'file_opener.dart';
import 'material_viewer.dart';

class DownloadedMaterials extends StatefulWidget {
  const DownloadedMaterials({super.key});

  @override
  State<DownloadedMaterials> createState() => _DownloadedMaterialsState();
}

class _DownloadedMaterialsState extends State<DownloadedMaterials> {
  bool _isLoading = true;
  List<FileSystemEntity> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<Directory> _downloadedMaterialsDir() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${documentsDir.path}/downloaded_materials');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);

    final dir = await _downloadedMaterialsDir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) {
        final aModified = a.statSync().modified;
        final bModified = b.statSync().modified;
        return bModified.compareTo(aModified);
      });

    if (!mounted) return;
    setState(() {
      _materials = files;
      _isLoading = false;
    });
  }

  Future<void> _shareMaterial(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _openMaterial(File file) async {
    if (file.path.toLowerCase().endsWith('.pdf')) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MaterialViewer(file: file)),
      );
      return;
    }

    try {
      await FileOpener.open(file);
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to open this material')),
      );
    }
  }

  Future<void> _deleteMaterial(File file) async {
    await file.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${file.uri.pathSegments.last}')),
    );
    await _loadMaterials();
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Downloaded Material',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadMaterials,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
          ? const _EmptyDownloads()
          : RefreshIndicator(
              onRefresh: _loadMaterials,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _materials.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final file = _materials[index] as File;
                  final stat = file.statSync();
                  final fileName = file.uri.pathSegments.last;
                  return _MaterialTile(
                    fileName: fileName,
                    details:
                        '${_fileSize(stat.size)} • ${DateFormat('MMM d, yyyy h:mm a').format(stat.modified)}',
                    onOpen: () => _openMaterial(file),
                    onShare: () => _shareMaterial(file),
                    onDelete: () => _deleteMaterial(file),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 54, color: Color(0xFF9EA3B0)),
            SizedBox(height: 14),
            Text(
              'No downloaded material yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Downloaded PDFs and lesson files will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final String fileName;
  final String details;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _MaterialTile({
    required this.fileName,
    required this.details,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFF5B6FF5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Open',
          ),
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
