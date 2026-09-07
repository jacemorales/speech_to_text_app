import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AppLanguage {
  final String code;
  final String name;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en_US', name: 'English (US)', flag: '🇺🇸'),
  AppLanguage(code: 'en_GB', name: 'English (UK)', flag: '🇬🇧'),
  AppLanguage(code: 'es_ES', name: 'Spanish (Spain)', flag: '🇪🇸'),
  AppLanguage(code: 'es_MX', name: 'Spanish (Mexico)', flag: '🇲🇽'),
  AppLanguage(code: 'fr_FR', name: 'French', flag: '🇫🇷'),
  AppLanguage(code: 'de_DE', name: 'German', flag: '🇩🇪'),
  AppLanguage(code: 'it_IT', name: 'Italian', flag: '🇮🇹'),
  AppLanguage(code: 'pt_BR', name: 'Portuguese (Brazil)', flag: '🇧🇷'),
  AppLanguage(code: 'zh_CN', name: 'Chinese (Mandarin)', flag: '🇨🇳'),
  AppLanguage(code: 'ja_JP', name: 'Japanese', flag: '🇯🇵'),
  AppLanguage(code: 'hi_IN', name: 'Hindi', flag: '🇮🇳'),
];

const Map<String, List<String>> samplePhrases = {
  'en_US': [
    'Welcome to Speech to Text Studio!',
    'Real-time voice transcription built with Flutter.',
    'You can tap to record, pause, or resume effortlessly.',
    'Organize notes into categories and search through your history.',
  ],
  'es_ES': [
    '¡Bienvenido a Speech to Text Studio!',
    'Transcripción de voz en tiempo real creada con Flutter.',
    'Puedes tocar para grabar, pausar o reanudar fácilmente.',
    'Organiza tus notas en categorías y busca en tu historial.',
  ],
  'fr_FR': [
    'Bienvenue sur Speech to Text Studio !',
    'Transcription vocale en temps réel créée avec Flutter.',
    'Vous pouvez appuyer pour enregistrer, mettre en pause ou reprendre.',
    'Organisez vos notes par catégories et recherchez dans votre historique.',
  ],
  'de_DE': [
    'Willkommen bei Speech to Text Studio!',
    'Echtzeit-Sprachtranskription mit Flutter entwickelt.',
    'Sie können einfach tippen, um aufzunehmen, zu pausieren oder fortzufahren.',
    'Organisieren Sie Ihre Notizen in Kategorien und durchsuchen Sie Ihren Verlauf.',
  ],
};

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isPaused = false;
  bool _isSimulated = false;
  String _currentLocaleId = 'en_US';
  String _words = '';
  double _soundLevel = 0.0;
  String? _errorMessage;

  Timer? _simulationTimer;
  int _simulationIndex = 0;

  bool get isListening => _isListening;
  bool get isPaused => _isPaused;
  bool get isSimulated => _isSimulated;
  String get currentLocaleId => _currentLocaleId;
  String get words => _words;
  double get soundLevel => _soundLevel;
  String? get errorMessage => _errorMessage;

  SpeechService() {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          _errorMessage = 'Speech recognition error: ${val.errorMsg}';
          notifyListeners();
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (!_isPaused && _isListening) {
              _isListening = false;
              notifyListeners();
            }
          }
        },
      );
    } catch (e) {
      _isInitialized = false;
    }
  }

  void setLocale(String localeCode) {
    _currentLocaleId = localeCode;
    notifyListeners();
  }

  void setTranscriptText(String text) {
    _words = text;
    notifyListeners();
  }

  void clearTranscript() {
    _words = '';
    notifyListeners();
  }

  Future<void> startListening() async {
    _errorMessage = null;

    if (!_isInitialized) {
      await _initSpeech();
    }

    if (_isInitialized) {
      try {
        _isListening = true;
        _isPaused = false;
        _isSimulated = false;
        notifyListeners();

        await _speech.listen(
          onResult: (result) {
            _words = result.recognizedWords;
            notifyListeners();
          },
          onSoundLevelChange: (level) {
            _soundLevel = level;
            notifyListeners();
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
            onDevice: false,
          ),
        );
        return;
      } catch (e) {
        _errorMessage = 'Native speech unavailable, starting demo mode.';
      }
    }

    // Fallback simulation mode
    _startSimulation();
  }

  void _startSimulation() {
    _isSimulated = true;
    _isListening = true;
    _isPaused = false;
    _errorMessage = null;
    notifyListeners();

    _simulationTimer?.cancel();
    final phrases = samplePhrases[_currentLocaleId] ?? samplePhrases['en_US']!;
    _simulationIndex = 0;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      final phrase = phrases[_simulationIndex % phrases.length];
      _simulationIndex++;
      if (_words.isEmpty) {
        _words = phrase;
      } else {
        _words = '$_words $phrase';
      }
      _soundLevel = (_simulationIndex % 5 + 1) * 2.0;
      notifyListeners();
    });
  }

  void pauseListening() {
    _simulationTimer?.cancel();
    if (_speech.isListening) {
      _speech.stop();
    }
    _isListening = false;
    _isPaused = true;
    _soundLevel = 0.0;
    notifyListeners();
  }

  void resumeListening() {
    if (_isSimulated || !_isInitialized) {
      _startSimulation();
    } else {
      startListening();
    }
  }

  void stopListening() {
    _simulationTimer?.cancel();
    if (_speech.isListening) {
      _speech.stop();
    }
    _isListening = false;
    _isPaused = false;
    _soundLevel = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}
