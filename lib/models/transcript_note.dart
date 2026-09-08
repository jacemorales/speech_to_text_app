import 'dart:convert';

class TranscriptNote {
  final String id;
  final String title;
  final String text;
  final String language;
  final DateTime date;
  final bool isFavorite;
  final String category;

  TranscriptNote({
    required this.id,
    required this.title,
    required this.text,
    required this.language,
    required this.date,
    this.isFavorite = false,
    this.category = 'General',
  });

  int get wordCount {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  int get characterCount => text.length;

  TranscriptNote copyWith({
    String? id,
    String? title,
    String? text,
    String? language,
    DateTime? date,
    bool? isFavorite,
    String? category,
  }) {
    return TranscriptNote(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      language: language ?? this.language,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'language': language,
      'date': date.toIso8601String(),
      'isFavorite': isFavorite,
      'category': category,
    };
  }

  factory TranscriptNote.fromMap(Map<String, dynamic> map) {
    return TranscriptNote(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? 'Untitled Note',
      text: map['text'] ?? '',
      language: map['language'] ?? 'en-US',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      isFavorite: map['isFavorite'] ?? false,
      category: map['category'] ?? 'General',
    );
  }

  String toJson() => json.encode(toMap());

  factory TranscriptNote.fromJson(String source) =>
      TranscriptNote.fromMap(json.decode(source));
}
