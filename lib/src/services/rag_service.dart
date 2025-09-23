import 'api_client.dart';

class RagService {
  final ApiClient api;
  RagService(this.api);

  Future<Map<String, dynamic>> queryCollection({
    required String collectionId,
    required String query,
    int k = 8,
  }) async {
    final res = await api.post(
      '/api/v1/retrieval/query/collection',
      body: {
        'collection_names': [collectionId],
        'query': query,
        'k': k,
      },
    );
    return res as Map<String, dynamic>;
  }
}
