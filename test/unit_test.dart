import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_app/models/transcript_note.dart';
import 'package:speech_to_text_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranscriptNote Model Tests', () {
    test('Calculates word count and character count accurately', () {
      final note = TranscriptNote(
        id: '1',
        title: 'Test Note',
        text: 'Hello world! This is a test note.',
        language: 'en_US',
        date: DateTime(2025, 1, 1),
      );

      expect(note.wordCount, equals(7));
      expect(note.characterCount, equals(33));
    });

    test('JSON serialization and deserialization works seamlessly', () {
      final original = TranscriptNote(
        id: '100',
        title: 'Meeting Notes',
        text: 'Discussed project scope and deadlines.',
        language: 'en_US',
        date: DateTime(2025, 5, 10, 14, 30),
        isFavorite: true,
        category: 'Work',
      );

      final jsonStr = original.toJson();
      final restored = TranscriptNote.fromJson(jsonStr);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.text, equals(original.text));
      expect(restored.isFavorite, isTrue);
      expect(restored.category, equals('Work'));
    });
  });

  group('StorageService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and retrieves notes from local storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final note = TranscriptNote(
        id: '201',
        title: 'Sample Idea',
        text: 'A fantastic app idea.',
        language: 'en_US',
        date: DateTime.now(),
        category: 'Ideas',
      );

      await storage.saveTranscript(note);
      final notes = await storage.getTranscripts();

      expect(notes.length, equals(1));
      expect(notes.first.title, equals('Sample Idea'));
    });

    test('Toggles favorite status and updates transcript', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final note = TranscriptNote(
        id: '301',
        title: 'Toggle Test',
        text: 'Testing favorite toggle.',
        language: 'en_US',
        date: DateTime.now(),
        isFavorite: false,
      );

      await storage.saveTranscript(note);
      final updated = await storage.toggleFavorite('301');

      expect(updated.first.isFavorite, isTrue);
    });

    test('Deletes a transcript note by id', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final note1 = TranscriptNote(
        id: '401',
        title: 'Note 1',
        text: 'Text 1',
        language: 'en_US',
        date: DateTime.now(),
      );
      final note2 = TranscriptNote(
        id: '402',
        title: 'Note 2',
        text: 'Text 2',
        language: 'en_US',
        date: DateTime.now(),
      );

      await storage.saveTranscript(note1);
      await storage.saveTranscript(note2);

      final remaining = await storage.deleteTranscript('401');
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('402'));
    });
  });
}
