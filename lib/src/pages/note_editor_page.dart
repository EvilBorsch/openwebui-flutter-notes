import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';

class NoteEditorPage extends StatefulWidget {
  final String noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _controller = TextEditingController();
  bool _preview = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Content will be populated on first build when the note is available.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    // Note may not be in memory yet right after quick-add; handle gracefully.
    var note =
        provider.notes.where((n) => n.id == widget.noteId).isNotEmpty
            ? provider.notes.firstWhere((n) => n.id == widget.noteId)
            : null;
    if (note != null && _controller.text.isEmpty) {
      _controller.text = note.contentMd;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note?.title ?? 'Untitled'),
        actions: [
          IconButton(
            icon: Icon(_preview ? Icons.edit : Icons.visibility),
            tooltip: _preview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _preview = !_preview),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _saving
                ? null
                : () async {
                  setState(() => _saving = true);
                  await provider.updateNoteContent(
                    widget.noteId,
                    _controller.text,
                  );
                  if (!mounted) return;
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Saved')));
                },
        icon: const Icon(Icons.save),
        label: Text(_saving ? 'Saving...' : 'Save'),
      ),
      body:
          note == null
              ? const Center(child: CircularProgressIndicator())
              : (_preview
                  ? Markdown(
                    data: _controller.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(text: note.title),
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            provider.updateLocalTitle(
                              note.id,
                              v,
                              _controller.text,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Start typing...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ],
                    ),
                  )),
    );
  }
}
