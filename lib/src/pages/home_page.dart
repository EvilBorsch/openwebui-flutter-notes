import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/notes_provider.dart';
import '../services/settings_service.dart';
import '../widgets/note_card.dart';
import 'settings_page.dart';
import 'note_editor_page.dart';
import 'rag_search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final NotesProvider notes;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    notes = NotesProvider(settings);
    // initial load
    WidgetsBinding.instance.addPostFrameCallback((_) => notes.loadNotes());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: notes,
      child: Consumer<NotesProvider>(
        builder: (context, state, _) {
          return WillPopScope(
            onWillPop: () async {
              if (state.hasSearch) {
                state.setSearch('');
                return false; // Consume back to return to home instead of closing app
              }
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Notes'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final q = await showSearch<String>(
                        context: context,
                        delegate: _NotesSearchDelegate(initial: ''),
                      );
                      if (q != null) state.setSearch(q);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.travel_explore),
                    tooltip: 'RAG Search',
                    onPressed: () {
                      final np = context.read<NotesProvider>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider.value(
                                value: np,
                                child: const RagSearchPage(),
                              ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                      await state.loadNotes();
                    },
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  final id = await state.addNoteQuick(
                    title: 'New note',
                    content: '',
                  );
                  if (!context.mounted) return;
                  if (id != null) {
                    final np = context.read<NotesProvider>();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => ChangeNotifierProvider.value(
                              value: np,
                              child: NoteEditorPage(noteId: id),
                            ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Quick Add'),
              ),
              body: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(NotesProvider state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    final notes = state.notes;
    if (notes.isEmpty) {
      return const Center(child: Text('No notes yet'));
    }

    final isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 4 : 2;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final n = notes[index];
          return NoteCard(
            note: n,
            onOpen: () {
              final np = context.read<NotesProvider>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => ChangeNotifierProvider.value(
                        value: np,
                        child: NoteEditorPage(noteId: n.id),
                      ),
                ),
              );
            },
            onDelete: () async {
              await state.deleteNote(n.id);
            },
            onTogglePin: () async {
              await state.togglePin(n.id);
            },
          );
        },
      ),
    );
  }
}

class _NotesSearchDelegate extends SearchDelegate<String> {
  _NotesSearchDelegate({String initial = ''}) {
    query = initial;
  }
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => close(context, ''),
        icon: const Icon(Icons.home_outlined),
        tooltip: 'Home',
      ),
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context).canPop()) {
        close(context, query);
      }
    });
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
