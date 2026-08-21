import { useState, useEffect, useRef, useCallback } from 'react';
import { Platform } from 'react-native';

export const SUPPORTED_LANGUAGES = [
  { code: 'en-US', name: 'English (US)' },
  { code: 'en-GB', name: 'English (UK)' },
  { code: 'es-ES', name: 'Spanish (Spain)' },
  { code: 'es-MX', name: 'Spanish (Mexico)' },
  { code: 'fr-FR', name: 'French' },
  { code: 'de-DE', name: 'German' },
  { code: 'it-IT', name: 'Italian' },
  { code: 'pt-BR', name: 'Portuguese (Brazil)' },
  { code: 'zh-CN', name: 'Chinese (Mandarin)' },
  { code: 'ja-JP', name: 'Japanese' },
  { code: 'hi-IN', name: 'Hindi' },
];

const SAMPLE_PHRASES = {
  'en-US': [
    'Welcome to the Speech to Text application.',
    'This real-time voice transcription allows seamless note taking.',
    'You can start, pause, resume, or stop recording at any time.',
    'Save your notes locally and review them whenever you like.',
  ],
  'es-ES': [
    'Bienvenido a la aplicación de reconocimiento de voz.',
    'Esta transcripción en tiempo real facilita la toma de notas.',
    'Puedes iniciar, pausar, reanudar o detener la grabación.',
    'Guarda tus notas localmente y consúltalas en cualquier momento.',
  ],
  'fr-FR': [
    'Bienvenue dans l\'application de retranscription vocale.',
    'Cette transcription en temps réel facilite la prise de notes.',
    'Vous pouvez démarrer, mettre en pause, reprendre ou arrêter.',
    'Enregistrez vos notes localement et consultez-les à tout moment.',
  ],
  'de-DE': [
    'Willkommen bei der Spracherkennungs-App.',
    'Echtzeit-Sprachtranskription macht Notizen ganz einfach.',
    'Sie können die Aufnahme jederzeit starten, pausieren oder stoppen.',
    'Speichern Sie Ihre Notizen lokal und überprüfen Sie sie jederzeit.',
  ],
};

export function useSpeechRecognition() {
  const [transcript, setTranscript] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [selectedLanguage, setSelectedLanguage] = useState('en-US');
  const [error, setError] = useState(null);
  const [hasBrowserSupport, setHasBrowserSupport] = useState(true);
  const [isSimulated, setIsSimulated] = useState(false);

  const recognitionRef = useRef(null);
  const simulationTimerRef = useRef(null);
  const simulationIndexRef = useRef(0);

  // Initialize SpeechRecognition if available on Web
  useEffect(() => {
    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      const SpeechRecognition =
        window.SpeechRecognition || window.webkitSpeechRecognition;

      if (!SpeechRecognition) {
        setHasBrowserSupport(false);
        console.warn('Web Speech API is not supported in this browser. Simulation mode active.');
      }
    } else {
      setHasBrowserSupport(false);
    }
  }, []);

  // Cleanup timers on unmount
  useEffect(() => {
    return () => {
      if (simulationTimerRef.current) {
        clearInterval(simulationTimerRef.current);
      }
      if (recognitionRef.current) {
        try {
          recognitionRef.current.stop();
        } catch (e) {
          // ignore cleanup errors
        }
      }
    };
  }, []);

  const startSimulation = useCallback((lang) => {
    setIsSimulated(true);
    setIsListening(true);
    setIsPaused(false);
    setError(null);

    const phrases = SAMPLE_PHRASES[lang] || SAMPLE_PHRASES['en-US'];
    simulationIndexRef.current = 0;

    if (simulationTimerRef.current) clearInterval(simulationTimerRef.current);

    simulationTimerRef.current = setInterval(() => {
      const currentPhrase = phrases[simulationIndexRef.current % phrases.length];
      simulationIndexRef.current += 1;

      setTranscript((prev) => {
        const prefix = prev ? prev + ' ' : '';
        return prefix + currentPhrase;
      });
    }, 2500);
  }, []);

  const startListening = useCallback(() => {
    setError(null);

    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      const SpeechRecognition =
        window.SpeechRecognition || window.webkitSpeechRecognition;

      if (SpeechRecognition) {
        try {
          if (recognitionRef.current) {
            recognitionRef.current.abort();
          }

          const recognition = new SpeechRecognition();
          recognition.continuous = true;
          recognition.interimResults = true;
          recognition.lang = selectedLanguage;

          recognition.onstart = () => {
            setIsListening(true);
            setIsPaused(false);
            setIsSimulated(false);
          };

          recognition.onresult = (event) => {
            let finalTranscript = '';
            for (let i = 0; i < event.results.length; i++) {
              finalTranscript += event.results[i][0].transcript;
            }
            setTranscript(finalTranscript);
          };

          recognition.onerror = (event) => {
            console.error('Speech recognition error:', event.error);
            if (event.error === 'not-allowed' || event.error === 'service-not-allowed' || event.error === 'no-speech') {
              setError(`Speech recognition notice: ${event.error}. Switching to demo simulation.`);
              // Fallback to simulation mode if mic fails or permission denied
              startSimulation(selectedLanguage);
            } else {
              setError(`Error: ${event.error}`);
            }
          };

          recognition.onend = () => {
            // Keep state synchronized
          };

          recognition.start();
          recognitionRef.current = recognition;
          return;
        } catch (e) {
          console.error('Failed to start Web Speech API:', e);
        }
      }
    }

    // Fallback simulation mode
    startSimulation(selectedLanguage);
  }, [selectedLanguage, startSimulation]);

  const pauseListening = useCallback(() => {
    if (simulationTimerRef.current) {
      clearInterval(simulationTimerRef.current);
      simulationTimerRef.current = null;
    }

    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (e) {
        // ignore
      }
    }

    setIsListening(false);
    setIsPaused(true);
  }, []);

  const resumeListening = useCallback(() => {
    if (isSimulated || !hasBrowserSupport) {
      startSimulation(selectedLanguage);
    } else {
      startListening();
    }
  }, [isSimulated, hasBrowserSupport, selectedLanguage, startSimulation, startListening]);

  const stopListening = useCallback(() => {
    if (simulationTimerRef.current) {
      clearInterval(simulationTimerRef.current);
      simulationTimerRef.current = null;
    }

    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (e) {
        // ignore
      }
    }

    setIsListening(false);
    setIsPaused(false);
  }, []);

  const clearTranscript = useCallback(() => {
    setTranscript('');
  }, []);

  const changeLanguage = useCallback((langCode) => {
    setSelectedLanguage(langCode);
    if (isListening) {
      stopListening();
      setTimeout(() => {
        setSelectedLanguage(langCode);
      }, 100);
    }
  }, [isListening, stopListening]);

  return {
    transcript,
    setTranscript,
    isListening,
    isPaused,
    selectedLanguage,
    error,
    hasBrowserSupport,
    isSimulated,
    startListening,
    pauseListening,
    resumeListening,
    stopListening,
    clearTranscript,
    changeLanguage,
  };
}
