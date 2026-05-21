import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pc_profile.dart';
import '../models/script_config.dart';
class PairingResult {
  final String token;
  final String? macAddress;
  final String? pcName;

  PairingResult({required this.token, this.macAddress, this.pcName});
}

class ApiService {
  final PcProfile profile;

  ApiService(this.profile);

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (profile.deviceToken != null) {
      h['Authorization'] = 'Bearer ${profile.deviceToken}';
    }
    return h;
  }

  /// Pair and return full result including MAC and PC name.
  Future<PairingResult?> pairFull(String code, String deviceName) async {
    try {
      final response = await http
          .post(
            Uri.parse('${profile.baseUrl}/api/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'device_name': deviceName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        return PairingResult(
          token: data['token'] as String,
          macAddress: data['mac_address'] as String?,
          pcName: data['pc_name'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Try to pair with a specific IP/port (static, no profile needed).
  static Future<PairingResult?> pairWithHost(
    String ip,
    int port,
    String code,
    String deviceName,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('http://$ip:$port/api/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'device_name': deviceName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        return PairingResult(
          token: data['token'] as String,
          macAddress: data['mac_address'] as String?,
          pcName: data['pc_name'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if the PC agent is reachable.
  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(
            Uri.parse('${profile.baseUrl}/api/status'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch the list of available scripts.
  Future<List<ScriptConfig>> getScripts() async {
    final response = await http
        .get(
          Uri.parse('${profile.baseUrl}/api/scripts'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to load scripts: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => ScriptConfig.fromJson(e)).toList();
  }

  /// Execute a script by its ID.
  Future<ScriptResult> runScript(String scriptId) async {
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/scripts/$scriptId/run'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Failed to run script: ${response.statusCode}');
    }

    return ScriptResult.fromJson(jsonDecode(response.body));
  }

  /// Fetch the list of script chains.
  Future<List<ScriptChain>> getChains() async {
    final response = await http
        .get(
          Uri.parse('${profile.baseUrl}/api/chains'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to load chains: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => ScriptChain.fromJson(e)).toList();
  }

  /// Execute a script chain by its ID.
  Future<Map<String, dynamic>> runChain(String chainId) async {
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/chains/$chainId/run'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 300));

    if (response.statusCode != 200) {
      throw Exception('Failed to run chain: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Save a new script order by sending an ordered list of IDs to the backend.
  Future<void> reorderScripts(List<String> orderedIds) async {
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/scripts/reorder'),
          headers: _headers,
          body: jsonEncode({'ordered_ids': orderedIds}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder scripts: ${response.statusCode}');
    }
  }

  /// Save a new chain order.
  Future<void> reorderChains(List<String> orderedIds) async {
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/chains/reorder'),
          headers: _headers,
          body: jsonEncode({'ordered_ids': orderedIds}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder chains: ${response.statusCode}');
    }
  }

  /// Save a new category order.
  Future<void> reorderCategories(List<String> orderedIds) async {
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/categories/reorder'),
          headers: _headers,
          body: jsonEncode({'ordered_ids': orderedIds}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder categories: ${response.statusCode}');
    }
  }

  /// Fetch the ordered list of category names.
  Future<List<String>> getCategories() async {
    final response = await http
        .get(
          Uri.parse('${profile.baseUrl}/api/categories'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['ordered'] as List<dynamic>).cast<String>();
  }

  /// Assign scripts to a group. Pass an empty list to clear a group.
  /// [oldGroup] is set when renaming a group.
  Future<void> assignGroup(
    String group,
    List<String> scriptIds, {
    String? oldGroup,
  }) async {
    final body = <String, dynamic>{
      'group': group,
      'script_ids': scriptIds,
      if (oldGroup != null && oldGroup != group) 'old_group': oldGroup,
    };
    final response = await http
        .post(
          Uri.parse('${profile.baseUrl}/api/scripts/assign-group'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to assign group: ${response.statusCode}');
    }
  }

  // --- Input control (mouse & keyboard) ---

  Future<void> mouseMoveRel(double dx, double dy) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/input/mouse/move'),
          headers: _headers,
          body: jsonEncode({'dx': dx, 'dy': dy}),
        )
        .timeout(const Duration(seconds: 2));
  }

  Future<void> mouseClick({String button = 'left', bool double_ = false}) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/input/mouse/click'),
          headers: _headers,
          body: jsonEncode({'button': button, 'double': double_}),
        )
        .timeout(const Duration(seconds: 2));
  }

  Future<void> mouseScroll({double dx = 0, double dy = 0}) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/input/mouse/scroll'),
          headers: _headers,
          body: jsonEncode({'dx': dx, 'dy': dy}),
        )
        .timeout(const Duration(seconds: 2));
  }

  Future<void> keyboardType(String text) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/input/keyboard/type'),
          headers: _headers,
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<void> keyboardKey(String key) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/input/keyboard/key'),
          headers: _headers,
          body: jsonEncode({'key': key}),
        )
        .timeout(const Duration(seconds: 2));
  }

  // --- Volume ---

  Future<Map<String, dynamic>> getVolume() async {
    final response = await http
        .get(Uri.parse('${profile.baseUrl}/api/volume/'), headers: _headers)
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) throw Exception('Failed to get volume');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setVolume(double level) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/volume/set'),
          headers: _headers,
          body: jsonEncode({'level': level}),
        )
        .timeout(const Duration(seconds: 2));
  }

  Future<void> setMute(bool muted) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/volume/mute'),
          headers: _headers,
          body: jsonEncode({'muted': muted}),
        )
        .timeout(const Duration(seconds: 2));
  }

  // --- Clipboard ---

  Future<String> getClipboard() async {
    final response = await http
        .get(Uri.parse('${profile.baseUrl}/api/clipboard/'), headers: _headers)
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) return '';
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<void> setClipboard(String text) async {
    await http
        .post(
          Uri.parse('${profile.baseUrl}/api/clipboard/set'),
          headers: _headers,
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 3));
  }

  // --- Files ---

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    final uri = Uri.parse('${profile.baseUrl}/api/files/list')
        .replace(queryParameters: {'path': path});
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Failed to list files');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  String fileDownloadUrl(String path) {
    final uri = Uri.parse('${profile.baseUrl}/api/files/download')
        .replace(queryParameters: {'path': path});
    return uri.toString();
  }

  Future<void> uploadFile(String destDir, String filename, List<int> bytes) async {
    final uri = Uri.parse('${profile.baseUrl}/api/files/upload')
        .replace(queryParameters: {'dest': destDir});
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final response = await request.send().timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) throw Exception('Upload failed');
  }

  Future<void> openFileOnPc(String path) async {
    final uri = Uri.parse('${profile.baseUrl}/api/files/open')
        .replace(queryParameters: {'path': path});
    await http.post(uri, headers: _headers).timeout(const Duration(seconds: 5));
  }

  // --- Screen ---

  String screenshotUrl({int quality = 50, double scale = 0.5}) {
    return '${profile.baseUrl}/api/screen/screenshot?quality=$quality&scale=$scale';
  }

  // --- History ---

  Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    final response = await http
        .get(
          Uri.parse('${profile.baseUrl}/api/history/?limit=$limit'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> clearHistory() async {
    await http
        .delete(Uri.parse('${profile.baseUrl}/api/history/'), headers: _headers)
        .timeout(const Duration(seconds: 5));
  }
}
