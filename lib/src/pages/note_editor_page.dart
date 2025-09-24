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

  void _wrapSelection(String left, String right) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start < 0 ? 0 : sel.start;
    final end = sel.end < 0 ? start : sel.end;
    final selected = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$left$selected$right');
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + left.length + selected.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _insertAtLineStart(String token) {
    final text = _controller.text;
    final sel = _controller.selection;
    int start = sel.start < 0 ? 0 : sel.start;
    int end = sel.end < 0 ? start : sel.end;
    final before = text.substring(0, start);
    final selectionText = text.substring(start, end);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lines = text.substring(lineStart, end).split('\n');
    final updated = lines
        .map((l) => l.isEmpty ? token : (l.startsWith(token) ? l : '$token$l'))
        .join('\n');
    final newText = text.replaceRange(lineStart, end, updated);
    final cursor = lineStart + updated.length;
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  void _insertBlock(String block) {
    final text = _controller.text;
    final sel = _controller.selection;
    final pos = sel.start < 0 ? text.length : sel.start;
    final newText = text.replaceRange(pos, pos, block);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + block.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _promptLink({bool image = false}) async {
    final labelCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(image ? 'Insert image' : 'Insert link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!image)
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Text'),
                  ),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(c);
                  final text = labelCtrl.text.trim();
                  final url = urlCtrl.text.trim();
                  if (url.isEmpty) return;
                  if (image) {
                    _insertBlock('![${text.isEmpty ? 'image' : text}]($url)');
                  } else {
                    _insertBlock('[${text.isEmpty ? 'link' : text}]($url)');
                  }
                },
                child: const Text('Insert'),
              ),
            ],
          ),
    );
    labelCtrl.dispose();
    urlCtrl.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Content will be populated on first build when the note is available.
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
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

    String derivedTitle() {
      final text = _controller.text;
      final lines = text.split('\n');
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        if (line.startsWith('#')) {
          final heading = line.replaceFirst(RegExp(r'^#+'), '').trim();
          if (heading.isNotEmpty) return heading;
        }
        return line;
      }
      return note?.title ?? 'Untitled';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(derivedTitle()),
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
                        // Tip: use a Markdown heading (# Title) as your note title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tip: add a heading like "# Title" on the first line',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Toolbar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Heading 1',
                                icon: const Icon(Icons.title),
                                onPressed: () => _insertAtLineStart('# '),
                              ),
                              IconButton(
                                tooltip: 'Heading 2',
                                icon: const Icon(Icons.text_fields),
                                onPressed: () => _insertAtLineStart('## '),
                              ),
                              IconButton(
                                tooltip: 'Bold',
                                icon: const Icon(Icons.format_bold),
                                onPressed: () => _wrapSelection('**', '**'),
                              ),
                              IconButton(
                                tooltip: 'Italic',
                                icon: const Icon(Icons.format_italic),
                                onPressed: () => _wrapSelection('*', '*'),
                              ),
                              IconButton(
                                tooltip: 'Inline code',
                                icon: const Icon(Icons.code),
                                onPressed: () => _wrapSelection('`', '`'),
                              ),
                              IconButton(
                                tooltip: 'Code block',
                                icon: const Icon(Icons.developer_mode),
                                onPressed:
                                    () => _insertBlock(
                                      '\n```\n${_controller.selection.textInside(_controller.text)}\n```\n',
                                    ),
                              ),
                              IconButton(
                                tooltip: 'Quote',
                                icon: const Icon(Icons.format_quote),
                                onPressed: () => _insertAtLineStart('> '),
                              ),
                              IconButton(
                                tooltip: 'List',
                                icon: const Icon(Icons.format_list_bulleted),
                                onPressed: () => _insertAtLineStart('- '),
                              ),
                              IconButton(
                                tooltip: 'Task',
                                icon: const Icon(Icons.check_box_outline_blank),
                                onPressed: () => _insertAtLineStart('- [ ] '),
                              ),
                              IconButton(
                                tooltip: 'Link',
                                icon: const Icon(Icons.link),
                                onPressed: () => _promptLink(image: false),
                              ),
                              IconButton(
                                tooltip: 'Image',
                                icon: const Icon(Icons.image_outlined),
                                onPressed: () => _promptLink(image: true),
                              ),
                              IconButton(
                                tooltip: 'Divider',
                                icon: const Icon(Icons.horizontal_rule),
                                onPressed: () => _insertBlock('\n\n---\n\n'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_controller.text.characters.length} chars • ${_controller.text.split('\n').length} lines',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
    );
  }
}
