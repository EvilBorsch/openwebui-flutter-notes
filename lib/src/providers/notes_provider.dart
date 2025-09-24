import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note.dart';
import '../services/api_client.dart';
import '../services/files_service.dart';
import '../services/knowledge_service.dart';
import '../services/settings_service.dart';

class NotesProvider extends ChangeNotifier {
  final SettingsService settings;
  late final ApiClient _api;
  FilesService? _files;
  KnowledgeService? _knowledge;

  NotesProvider(this.settings) {
    _api = ApiClient(baseUrl: settings.baseUrl, token: settings.token);
    _files = FilesService(_api);
    _knowledge = KnowledgeService(_api);
  }

  List<NoteItem> _notes = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;
  Map<String, String> _titleOverrides = {};
  bool _titlesLoaded = false;
  Set<String> _pinned = {};
  bool _pinsLoaded = false;

  List<NoteItem> get notes => _filtered();
  List<NoteItem> get allNotes => _notes;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasSearch => _searchQuery.trim().isNotEmpty;

  List<NoteItem> _filtered() {
    final list = _notes;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.contentMd.toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void updateLocalTitle(String id, String title, String currentContent) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notes[idx] = NoteItem(
        id: _notes[idx].id,
        title: title,
        contentMd: currentContent,
        updatedAt: DateTime.now(),
        createdAt: _notes[idx].createdAt,
        pinned: _notes[idx].pinned,
      );
      notifyListeners();
    }
    _setTitleOverride(id, title);
  }

  String? _deriveTitle(String metaName, String content) {
    if (metaName.isNotEmpty &&
        !(metaName.toLowerCase().startsWith('untitled'))) {
      return metaName;
    }
    final lines = content.split('\n');
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        final heading = line.replaceFirst(RegExp(r'^#+'), '').trim();
        if (heading.isNotEmpty) return heading;
      }
      return line;
    }
    return null;
  }

  Future<void> ensureNotesCollection() async {
    if (settings.collectionId.isNotEmpty) return;
    final list = await _knowledge!.getKnowledgeList();
    final existing = list.cast<Map<String, dynamic>?>().firstWhere(
      (k) => (k?['name']?.toString().toLowerCase() ?? '') == 'notes',
      orElse: () => null,
    );
    if (existing != null) {
      await settings.update(collectionId: existing['id']?.toString() ?? '');
      return;
    }
    final created = await _knowledge!.createKnowledge(name: 'notes');
    if (created != null) {
      await settings.update(collectionId: created['id']?.toString() ?? '');
    }
  }

  Future<void> loadNotes() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_ensureTitleOverrides(), _ensurePins()]);
      await ensureNotesCollection();
      if (settings.collectionId.isEmpty) {
        _notes = [];
        _loading = false;
        notifyListeners();
        return;
      }
      final kb = await _knowledge!.getKnowledgeById(settings.collectionId);
      final files =
          (kb?['files'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      files.sort(
        (a, b) => (b['updated_at'] ?? 0).compareTo(a['updated_at'] ?? 0),
      );
      final items = <NoteItem>[];
      for (final f in files) {
        final id = f['id'] as String;
        final data = await _api.get('/api/v1/files/$id/data/content');
        final content =
            (data is Map<String, dynamic>)
                ? (data['content']?.toString() ?? '')
                : '';
        final metaName = (f['meta']?['name']?.toString() ?? '').trim();
        final override = _titleOverrides[id];
        final title =
            (override != null && override.isNotEmpty)
                ? override
                : (_deriveTitle(metaName, content) ??
                    (metaName.isNotEmpty
                        ? metaName
                        : (f['id']?.toString() ?? 'Note')));
        final updated = DateTime.fromMillisecondsSinceEpoch(
          ((f['updated_at'] ?? 0) as int) * 1000,
        );
        final created = DateTime.fromMillisecondsSinceEpoch(
          ((f['created_at'] ?? 0) as int) * 1000,
        );
        items.add(
          NoteItem(
            id: id,
            title: title,
            contentMd: content,
            updatedAt: updated,
            createdAt: created,
            pinned: _pinned.contains(id),
          ),
        );
      }
      items.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      _notes = items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> addNoteQuick({
    String title = 'Untitled',
    String content = '',
  }) async {
    await ensureNotesCollection();
    final file = await _files!.createEmptyMarkdownFile(
      name: title,
      content: content,
    );
    final fileId = file['id']?.toString() ?? '';
    if (fileId.isEmpty) return null;
    final now = DateTime.now();
    final local = NoteItem(
      id: fileId,
      title: title,
      contentMd: content,
      updatedAt: now,
      createdAt: now,
      pinned: false,
    );
    _notes = [local, ..._notes];
    notifyListeners();
    // Do not persist the placeholder title; final title is derived from content.
    return fileId;
  }

  Future<void> updateNoteContent(String id, String content) async {
    await _files!.updateFileContent(fileId: id, content: content);
    try {
      await _knowledge!.addFileToKnowledge(
        knowledgeId: settings.collectionId,
        fileId: id,
      );
    } catch (_) {
      try {
        await _knowledge!.updateFileInKnowledge(
          knowledgeId: settings.collectionId,
          fileId: id,
        );
      } catch (_) {}
    }
    // Clear any previous title override so derived title from content takes effect
    await _clearTitleOverride(id);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _knowledge!.removeFileFromKnowledge(
      knowledgeId: settings.collectionId,
      fileId: id,
    );
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> _ensureTitleOverrides() async {
    if (_titlesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('note_titles') ?? '{}';
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _titleOverrides = map.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      _titleOverrides = {};
    }
    _titlesLoaded = true;
  }

  Future<void> _setTitleOverride(String id, String title) async {
    await _ensureTitleOverrides();
    _titleOverrides[id] = title;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('note_titles', jsonEncode(_titleOverrides));
    } catch (_) {}
  }

  Future<void> _clearTitleOverride(String id) async {
    await _ensureTitleOverrides();
    if (_titleOverrides.remove(id) != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('note_titles', jsonEncode(_titleOverrides));
      } catch (_) {}
    }
  }

  Future<void> _ensurePins() async {
    if (_pinsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('note_pins') ?? '[]';
      final list = jsonDecode(raw) as List<dynamic>;
      _pinned = list.map((e) => e.toString()).toSet();
    } catch (_) {
      _pinned = {};
    }
    _pinsLoaded = true;
  }

  Future<void> _persistPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('note_pins', jsonEncode(_pinned.toList()));
    } catch (_) {}
  }

  Future<void> togglePin(String id) async {
    await _ensurePins();
    if (_pinned.contains(id)) {
      _pinned.remove(id);
    } else {
      _pinned.add(id);
    }
    await _persistPins();
    _notes =
        _notes
            .map(
              (n) =>
                  n.id == id
                      ? NoteItem(
                        id: n.id,
                        title: n.title,
                        contentMd: n.contentMd,
                        updatedAt: n.updatedAt,
                        createdAt: n.createdAt,
                        pinned: _pinned.contains(id),
                      )
                      : n,
            )
            .toList();
    _notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    notifyListeners();
  }
}
