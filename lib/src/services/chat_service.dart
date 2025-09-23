import 'api_client.dart';

class ChatService {
  final ApiClient api;
  ChatService(this.api);

  Future<Map<String, dynamic>> chatWithCollection({
    required String model,
    required String prompt,
    required String collectionId,
  }) async {
    final payload = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'files': [
        {'type': 'collection', 'id': collectionId},
      ],
    };
    final res = await api.post('/api/chat/completions', body: payload);
    return res as Map<String, dynamic>;
  }
}
