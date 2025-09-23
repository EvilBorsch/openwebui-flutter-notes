import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/api_client.dart';
import '../services/rag_service.dart';
import '../services/chat_service.dart';

class RagSearchPage extends StatefulWidget {
  const RagSearchPage({super.key});

  @override
  State<RagSearchPage> createState() => _RagSearchPageState();
}

class _RagSearchPageState extends State<RagSearchPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<_RagItem> _items = [];
  String? _llm;
  String? _llmAnswer;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });
    try {
      final settings = context.read<SettingsService>();
      final api = ApiClient(baseUrl: settings.baseUrl, token: settings.token);
      final rag = RagService(api);
      final result = await rag.queryCollection(
        collectionId: settings.collectionId,
        query: query,
        k: 12,
      );
      final docs = (result['documents']?[0] as List<dynamic>? ?? []);
      final metas = (result['metadatas']?[0] as List<dynamic>? ?? []);
      final dists = (result['distances']?[0] as List<dynamic>? ?? []);
      final items = <_RagItem>[];
      for (var i = 0; i < docs.length; i++) {
        final md = metas.length > i ? metas[i] as Map<String, dynamic>? : null;
        final dist = dists.length > i ? (dists[i] as num?)?.toDouble() : null;
        items.add(
          _RagItem(
            text: (docs[i] ?? '').toString(),
            name: md?['name']?.toString() ?? (md?['source']?.toString() ?? ''),
            score: dist,
          ),
        );
      }
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _askLLM() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _llm = null;
      _llmAnswer = null;
    });
    try {
      final settings = context.read<SettingsService>();
      final api = ApiClient(baseUrl: settings.baseUrl, token: settings.token);
      final chat = ChatService(api);
      final model =
          (settings.model.isNotEmpty) ? settings.model : 'gpt-4-turbo';
      final res = await chat.chatWithCollection(
        model: model,
        prompt: query,
        collectionId: settings.collectionId,
      );

      // Basic OpenAI-compatible parsing
      final choices = res['choices'] as List?;
      final content =
          choices != null && choices.isNotEmpty
              ? (choices.first['message']?['content']?.toString() ?? '')
              : '';
      setState(() {
        _llm = model;
        _llmAnswer = content;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAG Search'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _loading ? null : _askLLM,
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Ask LLM',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask across your notes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.travel_explore),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_llmAnswer != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LLM ($_llm) response',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_llmAnswer!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child:
                  _items.isEmpty
                      ? const Center(child: Text('No results'))
                      : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          return Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          it.name.isEmpty ? 'Note' : it.name,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (it.score != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            it.score!.toStringAsFixed(3),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    it.text,
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RagItem {
  final String name;
  final String text;
  final double? score;
  _RagItem({required this.name, required this.text, this.score});
}
