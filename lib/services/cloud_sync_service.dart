import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';

/// Transport primitives for the cloud sync API.
/// This does not alter your SQLite database or perform table-specific mapping.
/// Add per-user authentication and a stable UUID/cloud_id for each local row
/// before connecting it to real AshaSarthi records.
class CloudSyncService {
  CloudSyncService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ServerConfig.prototypeSyncToken}',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ServerConfig.baseUrl;
    if (base.contains('YOUR-SERVICE')) {
      throw StateError('Set the Railway URL in server_config.dart first.');
    }
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> pushRecord({
    required String ownerId,
    required String entity,
    required String recordId,
    required Map<String, dynamic> payload,
    bool deleted = false,
  }) async {
    final response = await _client.post(
      _uri('/sync/push'),
      headers: _headers,
      body: jsonEncode({
        'owner_id': ownerId,
        'entity': entity,
        'record_id': recordId,
        'payload': payload,
        'deleted': deleted,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloud push failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> pullRecords({
    required String ownerId,
    String? sinceIso8601,
    int limit = 500,
  }) async {
    final query = <String, String>{
      'owner_id': ownerId,
      'limit': '$limit',
    };
    if (sinceIso8601 != null && sinceIso8601.isNotEmpty) {
      query['since'] = sinceIso8601;
    }

    final response = await _client.get(
      _uri('/sync/pull', query),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloud pull failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['records'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void close() => _client.close();
}
