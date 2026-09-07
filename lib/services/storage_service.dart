import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transcript_note.dart';

class StorageService {
  static const String _storageKey = 'speech_to_text_transcripts_v2';

  final SharedPreferences? _prefsOverride;

  StorageService([this._prefsOverride]);

  Future<SharedPreferences> get _prefs async {
    return _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<List<TranscriptNote>> getTranscripts() async {
    try {
      final p = await _prefs;
      final jsonString = p.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => TranscriptNote.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TranscriptNote>> saveTranscript(TranscriptNote note) async {
    final list = await getTranscripts();
    final updated = [note, ...list];
    await _saveList(updated);
    return updated;
  }

  Future<List<TranscriptNote>> updateTranscript(TranscriptNote updatedNote) async {
    final list = await getTranscripts();
    final updated = list.map((n) => n.id == updatedNote.id ? updatedNote : n).toList();
    await _saveList(updated);
    return updated;
  }

  Future<List<TranscriptNote>> deleteTranscript(String id) async {
    final list = await getTranscripts();
    final updated = list.where((n) => n.id != id).toList();
    await _saveList(updated);
    return updated;
  }

  Future<List<TranscriptNote>> toggleFavorite(String id) async {
    final list = await getTranscripts();
    final updated = list.map((n) {
      if (n.id == id) {
        return n.copyWith(isFavorite: !n.isFavorite);
      }
      return n;
    }).toList();
    await _saveList(updated);
    return updated;
  }

  Future<List<TranscriptNote>> clearAllTranscripts() async {
    final p = await _prefs;
    await p.remove(_storageKey);
    return [];
  }

  Future<void> _saveList(List<TranscriptNote> list) async {
    final p = await _prefs;
    final jsonList = list.map((n) => n.toMap()).toList();
    await p.setString(_storageKey, json.encode(jsonList));
  }
}
