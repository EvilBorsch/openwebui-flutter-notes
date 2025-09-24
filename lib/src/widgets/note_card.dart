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
              if (snippet.isNotEmpty) _TruncatedMarkdown(data: snippet),
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

class _TruncatedMarkdown extends StatefulWidget {
  final String data;
  const _TruncatedMarkdown({required this.data});

  @override
  State<_TruncatedMarkdown> createState() => _TruncatedMarkdownState();
}

class _TruncatedMarkdownState extends State<_TruncatedMarkdown> {
  final ScrollController _controller = ScrollController();
  bool _overflowing = false;
  bool _atTop = true;
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  @override
  void didUpdateWidget(covariant _TruncatedMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  void _updateOverflow() {
    if (!mounted) return;
    if (_controller.hasClients) {
      final bool isOverflowing = _controller.position.maxScrollExtent > 0.0;
      if (isOverflowing != _overflowing) {
        setState(() => _overflowing = isOverflowing);
      }
      _updateEdgeFlags();
    }
  }

  void _onScroll() {
    if (!mounted || !_controller.hasClients) return;
    _updateEdgeFlags();
  }

  void _updateEdgeFlags() {
    final atTop = _controller.offset <= 0.5;
    final atBottom =
        _controller.offset >= (_controller.position.maxScrollExtent - 0.5);
    if (atTop != _atTop || atBottom != _atBottom) {
      setState(() {
        _atTop = atTop;
        _atBottom = atBottom;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final half = MediaQuery.of(context).size.height * 0.5;

    final content = SingleChildScrollView(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      child: MarkdownBody(
        data: widget.data,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyMedium,
          h1: Theme.of(context).textTheme.titleSmall,
          h2: Theme.of(context).textTheme.titleSmall,
          h3: Theme.of(context).textTheme.titleSmall,
          code: Theme.of(context).textTheme.bodySmall,
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 3),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: half),
      child: ClipRect(
        child:
            _overflowing
                ? ShaderMask(
                  shaderCallback: (rect) {
                    final double topFade = _atTop ? 0.0 : 0.06;
                    final double bottomFade = _atBottom ? 0.0 : 0.10;
                    final colors = <Color>[
                      _atTop ? Colors.white : Colors.transparent,
                      Colors.white,
                      Colors.white,
                      _atBottom ? Colors.white : Colors.transparent,
                    ];
                    final stops = <double>[0.0, topFade, 1.0 - bottomFade, 1.0];
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colors,
                      stops: stops,
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: content,
                )
                : content,
      ),
    );
  }
}
