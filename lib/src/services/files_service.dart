import 'api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class FilesService {
  final ApiClient api;
  FilesService(this.api);

  Future<Map<String, dynamic>> createEmptyMarkdownFile({
    required String name,
    String content = '',
  }) async {
    // Use process/file endpoint by first uploading a minimal text file? Simpler: create via /files/ by multipart
    // But we can set content via /files/{id}/data/content/update after upload.

    // Create an empty file record by uploading minimal content as text/plain
    final base =
        api.baseUrl.endsWith('/')
            ? api.baseUrl.substring(0, api.baseUrl.length - 1)
            : api.baseUrl;
    final uri = Uri.parse(
      '$base/api/v1/files/?process=false&process_in_background=false',
    );

    final body = (content.isEmpty) ? " " : content; // ensure non-empty payload
    final request = apiMultipartRequest(uri, name, body);
    if (api.token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${api.token}';
    }

    final streamed = await request.send();
    final response = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return jsonDecodeSafe(response) as Map<String, dynamic>;
    }
    throw Exception('Upload failed: ${streamed.statusCode} $response');
  }

  Future<Map<String, dynamic>> updateFileContent({
    required String fileId,
    required String content,
  }) async {
    final res = await api.post(
      '/api/v1/files/$fileId/data/content/update',
      body: {'content': content},
    );
    return res as Map<String, dynamic>;
  }
}

// Helpers

http.MultipartRequest apiMultipartRequest(
  Uri uri,
  String name,
  String content,
) {
  final req = http.MultipartRequest('POST', uri);
  // Headers are set at client level; using text file body
  req.headers['Accept'] = 'application/json';
  req.files.add(
    http.MultipartFile.fromString(
      'file',
      content,
      filename: 'untitled.md',
      contentType: MediaType('text', 'plain'),
    ),
  );
  return req;
}

dynamic jsonDecodeSafe(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return {};
  }
}

// MediaType is now imported from http_parser
