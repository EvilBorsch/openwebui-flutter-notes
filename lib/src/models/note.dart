class NoteItem {
  final String id;
  final String title;
  final String contentMd;
  final DateTime updatedAt;
  final DateTime createdAt;
  final bool pinned;

  NoteItem({
    required this.id,
    required this.title,
    required this.contentMd,
    required this.updatedAt,
    required this.createdAt,
    this.pinned = false,
  });
}
