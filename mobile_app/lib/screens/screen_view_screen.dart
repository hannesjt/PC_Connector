import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class ScreenViewScreen extends StatefulWidget {
  final ApiService api;
  const ScreenViewScreen({super.key, required this.api});

  @override
  State<ScreenViewScreen> createState() => _ScreenViewScreenState();
}

class _ScreenViewScreenState extends State<ScreenViewScreen> {
  Uint8List? _imageBytes;
  Timer? _timer;
  bool _loading = true;
  int _quality = 40;
  double _scale = 0.4;

  @override
  void initState() {
    super.initState();
    _capture();
    _timer =
        Timer.periodic(const Duration(milliseconds: 800), (_) => _capture());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final url = widget.api.screenshotUrl(quality: _quality, scale: _scale);
      final headers = <String, String>{};
      if (widget.api.profile.deviceToken != null) {
        headers['Authorization'] = 'Bearer ${widget.api.profile.deviceToken}';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _loading = false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.screen),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune),
            tooltip: l.quality,
            onSelected: (val) {
              setState(() {
                switch (val) {
                  case 0:
                    _quality = 25;
                    _scale = 0.3;
                    break;
                  case 1:
                    _quality = 40;
                    _scale = 0.4;
                    break;
                  case 2:
                    _quality = 70;
                    _scale = 0.6;
                    break;
                }
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 0, child: Text(l.qualityLow)),
              PopupMenuItem(value: 1, child: Text(l.qualityMedium)),
              PopupMenuItem(value: 2, child: Text(l.qualityHigh)),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imageBytes == null
              ? Center(child: Text(l.noImage))
              : InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      _imageBytes!,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
    );
  }
}
