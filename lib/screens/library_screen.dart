import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transcript_note.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';

class LibraryScreen extends StatefulWidget {
  final StorageService storageService;

  const LibraryScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<TranscriptNote> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  final List<String> _categories = [
    'All',
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
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() => _isLoading = true);
    final list = await widget.storageService.getTranscripts();
    if (mounted) {
      setState(() {
        _notes = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(TranscriptNote note) async {
    final updated = await widget.storageService.toggleFavorite(note.id);
    if (mounted) {
      setState(() => _notes = updated);
    }
  }

  Future<void> _deleteNote(String id) async {
    final updated = await widget.storageService.deleteTranscript(id);
    if (mounted) {
      setState(() => _notes = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note deleted.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Transcripts'),
        content: const Text(
          'Are you sure you want to permanently delete all saved transcripts? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.storageService.clearAllTranscripts();
      await loadNotes();
    }
  }

  void _showNoteDetail(TranscriptNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textController = TextEditingController(text: note.text);
        final titleController = TextEditingController(text: note.title);

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            final lang = supportedLanguages.firstWhere(
              (l) => l.code == note.language,
              orElse: () => supportedLanguages[0],
            );

            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        avatar: Text(lang.flag),
                        label: Text(lang.name),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: textController.text),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied note text!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444)),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteNote(note.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: titleController,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: InputBorder.none,
                    ),
                  ),

                  Text(
                    'Created: ${DateFormat.yMMMd().add_jm().format(note.date)} • Category: ${note.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),

                  const Divider(height: 24),

                  TextField(
                    controller: textController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      labelText: 'Transcript Content',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final updated = note.copyWith(
                        title: titleController.text.trim(),
                        text: textController.text.trim(),
                      );
                      await widget.storageService.updateTranscript(updated);
                      if (context.mounted) Navigator.pop(context);
                      loadNotes();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.text.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || note.category == _selectedCategory;
      final matchesFavorite = !_showFavoritesOnly || note.isFavorite;

      return matchesSearch && matchesCategory && matchesFavorite;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter header
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search transcripts...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                selected: _showFavoritesOnly,
                onSelected: (val) => setState(() => _showFavoritesOnly = val),
              ),
              if (_notes.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                  tooltip: 'Clear All',
                  onPressed: _confirmClearAll,
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Categories horizontal scroll
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

          // Notes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _notes.isEmpty
                                  ? 'No saved transcripts yet.'
                                  : 'No matching notes found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadNotes,
                        child: ListView.builder(
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            final lang = supportedLanguages.firstWhere(
                              (l) => l.code == note.language,
                              orElse: () => supportedLanguages[0],
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showNoteDetail(note),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              note.isFavorite
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: note.isFavorite
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavorite(note),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(lang.flag,
                                                  style: const TextStyle(fontSize: 14)),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1)
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  note.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6366F1),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            DateFormat.yMMMd().format(note.date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
