import 'package:flutter/foundation.dart';
import 'api_client.dart';

class KnowledgeService {
  final ApiClient api;
  KnowledgeService(this.api);

  Future<List<dynamic>> getKnowledgeList() async {
    final res = await api.get('/api/v1/knowledge/list');
    if (res is List) return res;
    return [];
  }

  Future<Map<String, dynamic>?> getKnowledgeById(String id) async {
    try {
      final res = await api.get('/api/v1/knowledge/$id');
      return res as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createKnowledge({
    required String name,
    String description = 'Notes collection',
  }) async {
    try {
      final res = await api.post(
        '/api/v1/knowledge/create',
        body: {
          'name': name,
          'description': description,
          'access_control': null,
        },
      );
      return res as Map<String, dynamic>;
    } catch (e) {
      debugPrint('createKnowledge error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> addFileToKnowledge({
    required String knowledgeId,
    required String fileId,
  }) async {
    final res = await api.post(
      '/api/v1/knowledge/$knowledgeId/file/add',
      body: {'file_id': fileId},
    );
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateFileInKnowledge({
    required String knowledgeId,
    required String fileId,
  }) async {
    final res = await api.post(
      '/api/v1/knowledge/$knowledgeId/file/update',
      body: {'file_id': fileId},
    );
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeFileFromKnowledge({
    required String knowledgeId,
    required String fileId,
  }) async {
    final res = await api.post(
      '/api/v1/knowledge/$knowledgeId/file/remove',
      body: {'file_id': fileId},
    );
    return res as Map<String, dynamic>;
  }
}
