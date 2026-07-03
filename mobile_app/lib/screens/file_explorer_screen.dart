import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class FileExplorerScreen extends StatefulWidget {
  final ApiService api;
  const FileExplorerScreen({super.key, required this.api});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  String _currentPath = '';
  final List<String> _pathHistory = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _downloadingPath;

  @override
  void initState() {
    super.initState();
    _loadDir('');
  }

  Future<void> _loadDir(String path) async {
    setState(() => _loading = true);
    try {
      final items = await widget.api.listFiles(path);
      if (!mounted) return;
      setState(() {
        _items = items;
        _currentPath = path;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).error(e))),
      );
    }
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _loadDir(path);
  }

  void _goBack() {
    if (_pathHistory.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final prev = _pathHistory.removeLast();
    _loadDir(prev);
  }

  void _openFile(Map<String, dynamic> item) {
    widget.api.openFileOnPc(item['path'] as String);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).fileOpeningOnPc)),
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> item) async {
    final l = AppLocalizations.of(context);
    final filePath = item['path'] as String;
    final fileName = item['name'] as String;

    setState(() => _downloadingPath = filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.downloading(fileName))),
    );

    try {
      final url = widget.api.fileDownloadUrl(filePath);
      final headers = <String, String>{};
      if (widget.api.profile.deviceToken != null) {
        headers['Authorization'] = 'Bearer ${widget.api.profile.deviceToken}';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw Exception(l.serverError(response.statusCode));
      }

      // Save to Downloads folder
      final dir = await getExternalStorageDirectory();
      final downloadsDir =
          Directory('${dir!.path.split('Android')[0]}Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Avoid name collisions
      var destFile = File('${downloadsDir.path}/$fileName');
      if (await destFile.exists()) {
        final base = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        final ext = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        final ts = DateTime.now().millisecondsSinceEpoch;
        destFile = File('${downloadsDir.path}/${base}_$ts$ext');
      }

      await destFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.savedAs(destFile.path.split('/').last)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.downloadFailed(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingPath = null);
    }
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> item) {
    final l = AppLocalizations.of(context);
    final isDir = item['is_dir'] == true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_iconForItem(item)),
              title: Text(
                item['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle:
                  isDir ? Text(l.folder) : Text(_formatSize(item['size'])),
            ),
            const Divider(height: 1),
            if (!isDir) ...[
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(l.download),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l.openOnPc),
                onTap: () {
                  Navigator.pop(context);
                  _openFile(item);
                },
              ),
            ],
            if (isDir)
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(l.openFolder),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(item['path'] as String);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconForItem(Map<String, dynamic> item) {
    if (item['is_dir'] == true) return Icons.folder;
    final name = (item['name'] as String).toLowerCase();
    if (name.endsWith('.jpg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp')) return Icons.image;
    if (name.endsWith('.mp4') || name.endsWith('.avi') || name.endsWith('.mkv'))
      return Icons.movie;
    if (name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.flac')) return Icons.audio_file;
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.zip') || name.endsWith('.rar') || name.endsWith('.7z'))
      return Icons.archive;
    return Icons.insert_drive_file;
  }

  String _formatSize(dynamic size) {
    if (size == null) return '';
    final bytes = size as int;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: _pathHistory.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentPath.isEmpty ? l.pcFiles : _currentPath),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(child: Text(l.empty))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      final isDir = item['is_dir'] == true;
                      final isDownloading = _downloadingPath == item['path'];
                      return ListTile(
                        leading: isDownloading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_iconForItem(item)),
                        title: Text(
                          item['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle:
                            isDir ? null : Text(_formatSize(item['size'])),
                        trailing:
                            isDir ? const Icon(Icons.chevron_right) : null,
                        onTap: () {
                          if (isDir) {
                            _navigateTo(item['path'] as String);
                          } else {
                            _openFile(item);
                          }
                        },
                        onLongPress: () => _showContextMenu(ctx, item),
                      );
                    },
                  ),
      ),
    );
  }
}
