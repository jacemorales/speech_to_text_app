import { useState, useEffect, useRef, useCallback } from 'react';
import { Platform } from 'react-native';
import {
  ExpoSpeechRecognitionModule,
  useSpeechRecognitionEvent,
} from 'expo-speech-recognition';

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

  // ExpoSpeechRecognition Event Listeners
  useSpeechRecognitionEvent('result', (event) => {
    if (event && event.results && event.results.length > 0) {
      const latestText = event.results[0]?.transcript || '';
      if (latestText) {
        setTranscript(latestText);
        setIsSimulated(false);
      }
    }
  });

  useSpeechRecognitionEvent('start', () => {
    setIsListening(true);
    setIsPaused(false);
    setIsSimulated(false);
  });

  useSpeechRecognitionEvent('end', () => {
    setIsListening(false);
  });

  useSpeechRecognitionEvent('error', (event) => {
    console.error('Expo Speech Recognition error:', event);
    if (event?.error === 'not-allowed' || event?.error === 'service-not-allowed') {
      setError(`Permission or service error: ${event.message || event.error}. Fallback to simulation mode.`);
      startSimulation(selectedLanguage);
    } else if (event?.error !== 'aborted') {
      setError(`Speech error: ${event.message || event.error}`);
    }
  });

  // Initialize Web Speech API as fallback for Web browser
  useEffect(() => {
    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      const SpeechRecognition =
        window.SpeechRecognition || window.webkitSpeechRecognition;

      if (!SpeechRecognition) {
        setHasBrowserSupport(false);
      }
    }
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (simulationTimerRef.current) {
        clearInterval(simulationTimerRef.current);
      }
      if (recognitionRef.current) {
        try {
          recognitionRef.current.stop();
        } catch (e) {
          // ignore
        }
      }
      try {
        ExpoSpeechRecognitionModule.abort();
      } catch (e) {
        // ignore
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

  const startListening = useCallback(async () => {
    setError(null);

    // 1. Try Native / Expo Speech Recognition module first
    try {
      if (ExpoSpeechRecognitionModule) {
        const perm = await ExpoSpeechRecognitionModule.requestPermissionsAsync();
        if (perm.granted) {
          setIsSimulated(false);
          setIsListening(true);
          setIsPaused(false);
          ExpoSpeechRecognitionModule.start({
            lang: selectedLanguage,
            interimResults: true,
            continuous: true,
            addsPunctuation: true,
          });
          return;
        } else {
          setError('Microphone or Speech Recognition permission was denied.');
        }
      }
    } catch (e) {
      console.warn('ExpoSpeechRecognitionModule error/unavailable:', e);
    }

    // 2. Try Web Speech API if running on web
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
            console.error('Web Speech recognition error:', event.error);
            if (
              event.error === 'not-allowed' ||
              event.error === 'service-not-allowed' ||
              event.error === 'no-speech'
            ) {
              setError(`Speech recognition notice: ${event.error}. Switching to demo simulation.`);
              startSimulation(selectedLanguage);
            } else {
              setError(`Error: ${event.error}`);
            }
          };

          recognition.start();
          recognitionRef.current = recognition;
          return;
        } catch (e) {
          console.error('Failed to start Web Speech API:', e);
        }
      }
    }

    // 3. Fallback simulation mode if speech recognition unavailable
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

    try {
      ExpoSpeechRecognitionModule.stop();
    } catch (e) {
      // ignore
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

    try {
      ExpoSpeechRecognitionModule.stop();
    } catch (e) {
      // ignore
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
