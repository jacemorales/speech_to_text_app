import 'package:flutter/material.dart';
import 'screens/library_screen.dart';
import 'screens/record_screen.dart';
import 'services/speech_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SpeechToTextApp());
}

class SpeechToTextApp extends StatefulWidget {
  const SpeechToTextApp({super.key});

  @override
  State<SpeechToTextApp> createState() => _SpeechToTextAppState();
}

class _SpeechToTextAppState extends State<SpeechToTextApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: MainHomeScreen(
        onToggleTheme: toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  final SpeechService _speechService = SpeechService();
  final StorageService _storageService = StorageService();
  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey<LibraryScreenState>();

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Text('Speech Studio'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecordScreen(
            speechService: _speechService,
            storageService: _storageService,
            onSavedNote: () {
              _libraryKey.currentState?.loadNotes();
            },
          ),
          LibraryScreen(
            key: _libraryKey,
            storageService: _storageService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: Color(0xFF6366F1)),
            label: 'Recorder',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon:
                Icon(Icons.collections_bookmark_rounded, color: Color(0xFF6366F1)),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
