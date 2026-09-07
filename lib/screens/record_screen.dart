import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transcript_note.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../widgets/audio_waveform_visualizer.dart';

class RecordScreen extends StatefulWidget {
  final SpeechService speechService;
  final StorageService storageService;
  final VoidCallback onSavedNote;

  const RecordScreen({
    super.key,
    required this.speechService,
    required this.storageService,
    required this.onSavedNote,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late TextEditingController _textController;
  final TextEditingController _titleController = TextEditingController();
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Work',
    'Personal',
    'Ideas',
    'Meeting',
    'Study',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.speechService.words);
    widget.speechService.addListener(_onSpeechUpdated);
  }

  void _onSpeechUpdated() {
    if (_textController.text != widget.speechService.words) {
      _textController.text = widget.speechService.words;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.speechService.removeListener(_onSpeechUpdated);
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please speak or type some text before saving.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final note = TranscriptNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty
          ? 'Note ${DateTime.now().month}/${DateTime.now().day} ${TimeOfDay.now().format(context)}'
          : _titleController.text.trim(),
      text: text,
      language: widget.speechService.currentLocaleId,
      date: DateTime.now(),
      category: _selectedCategory,
    );

    await widget.storageService.saveTranscript(note);
    _titleController.clear();
    widget.speechService.clearTranscript();
    _textController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transcript saved to library!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onSavedNote();
    }
  }

  void _copyToClipboard() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Speech Language',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: supportedLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = supportedLanguages[index];
                      final isSelected =
                          lang.code == widget.speechService.currentLocaleId;

                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          lang.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                            : null,
                        onTap: () {
                          widget.speechService.setLocale(lang.code);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final speech = widget.speechService;
    final currentLang = supportedLanguages.firstWhere(
      (l) => l.code == speech.currentLocaleId,
      orElse: () => supportedLanguages[0],
    );

    final wordCount = _textController.text.trim().isEmpty
        ? 0
        : _textController.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _textController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header status & language bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _showLanguageSelector,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(currentLang.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        currentLang.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: speech.isListening
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : speech.isPaused
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: speech.isListening
                            ? const Color(0xFF10B981)
                            : speech.isPaused
                                ? const Color(0xFFF59E0B)
                                : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      speech.isListening
                          ? (speech.isSimulated ? 'Demo Mode' : 'Listening...')
                          : speech.isPaused
                              ? 'Paused'
                              : 'Ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: speech.isListening
                            ? const Color(0xFF10B981)
                            : speech.isPaused
                                ? const Color(0xFFF59E0B)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (speech.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      speech.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Audio waveform animation
          AudioWaveformVisualizer(
            isListening: speech.isListening,
            soundLevel: speech.soundLevel,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 16),

          // Live Transcript Card / Editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.subtitles, size: 18, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(
                            'Live Transcript',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: 'Copy',
                            onPressed: _copyToClipboard,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            tooltip: 'Clear',
                            onPressed: () {
                              speech.clearTranscript();
                              _textController.clear();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    onChanged: (val) => speech.setTranscriptText(val),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    decoration: const InputDecoration(
                      hintText:
                          'Tap the microphone below to start speaking, or edit text manually here...',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$wordCount words | $charCount chars',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        speech.isListening ? 'Live Recording Active' : 'Editable',
                        style: TextStyle(
                          fontSize: 12,
                          color: speech.isListening
                              ? const Color(0xFF10B981)
                              : Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Glowing Pulsing Microphone Control
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (speech.isListening) {
                      speech.pauseListening();
                    } else if (speech.isPaused) {
                      speech.resumeListening();
                    } else {
                      speech.startListening();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: speech.isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFF59E0B)]
                            : speech.isPaused
                                ? [const Color(0xFFF59E0B), const Color(0xFF10B981)]
                                : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (speech.isListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1))
                              .withValues(alpha: 0.4),
                          blurRadius: speech.isListening ? 20 : 10,
                          spreadRadius: speech.isListening ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      speech.isListening
                          ? Icons.pause_rounded
                          : speech.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.mic_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ).animate(target: speech.isListening ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      speech.isListening
                          ? 'Tap to Pause'
                          : speech.isPaused
                              ? 'Tap to Resume'
                              : 'Tap to Record',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (speech.isListening || speech.isPaused) ...[
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => speech.stopListening(),
                        icon: const Icon(Icons.stop_rounded, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Stop',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Save Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save Transcript Note',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Note Title (Optional)',
                      hintText: 'e.g. Weekly Standup Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleSave,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save Note',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
