import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final base =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse(
      '$base$path',
    ).replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_u(path, query), headers: _headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body.isEmpty ? '{}' : res.body);
    }
    throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http.post(
      _u(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body.isEmpty ? '{}' : res.body);
    }
    throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_u(path), headers: _headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? {} : jsonDecode(res.body);
    }
    throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
  }
}
