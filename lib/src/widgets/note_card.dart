import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onTogglePin;
  const NoteCard({
    super.key,
    required this.note,
    required this.onOpen,
    required this.onDelete,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final snippet = _buildSnippet(note.contentMd);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onOpen,
        onLongPress: onTogglePin,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'note-title-${note.id}',
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (note.pinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.push_pin, size: 16),
                    ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (snippet.isNotEmpty)
                MarkdownBody(
                  data: snippet,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    Theme.of(context),
                  ).copyWith(
                    p: Theme.of(context).textTheme.bodyMedium,
                    h1: Theme.of(context).textTheme.titleSmall,
                    h2: Theme.of(context).textTheme.titleSmall,
                    h3: Theme.of(context).textTheme.titleSmall,
                    code: Theme.of(context).textTheme.bodySmall,
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatWhen(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSnippet(String md) {
    return md.trim();
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return DateFormat('y-MM-dd').format(dt);
  }
}
