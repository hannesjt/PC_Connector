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

  /// Pair with the PC agent using a 6-digit code.
  /// Returns the device token on success, null on failure.
  Future<String?> pair(String code, String deviceName) async {
    final result = await pairFull(code, deviceName);
    return result?.token;
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
}
