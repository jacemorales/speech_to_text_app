import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  TextInput,
  ScrollView,
  SafeAreaView,
  StatusBar,
  Modal,
  Alert,
  Animated,
  Easing,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  useSpeechRecognition,
  SUPPORTED_LANGUAGES,
} from './src/hooks/useSpeechRecognition';
import {
  getTranscripts,
  saveTranscript,
  deleteTranscript,
  clearAllTranscripts,
} from './src/utils/storage';

export default function App() {
  const {
    transcript,
    setTranscript,
    isListening,
    isPaused,
    selectedLanguage,
    error,
    isSimulated,
    startListening,
    pauseListening,
    resumeListening,
    stopListening,
    clearTranscript,
    changeLanguage,
  } = useSpeechRecognition();

  const [savedTranscripts, setSavedTranscripts] = useState([]);
  const [noteTitle, setNoteTitle] = useState('');
  const [langModalVisible, setLangModalVisible] = useState(false);
  const [historyModalVisible, setHistoryModalVisible] = useState(false);
  const [copiedNotice, setCopiedNotice] = useState(false);
  const [selectedSavedNote, setSelectedSavedNote] = useState(null);

  // Pulse animation for recording status
  const [pulseAnim] = useState(new Animated.Value(1));

  useEffect(() => {
    loadSavedTranscripts();
  }, []);

  useEffect(() => {
    if (isListening) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.25,
            duration: 800,
            easing: Easing.ease,
            useNativeDriver: false,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 800,
            easing: Easing.ease,
            useNativeDriver: false,
          }),
        ])
      ).start();
    } else {
      pulseAnim.setValue(1);
    }
  }, [isListening]);

  const loadSavedTranscripts = async () => {
    const list = await getTranscripts();
    setSavedTranscripts(list);
  };

  const handleSave = async () => {
    if (!transcript.trim()) {
      if (Platform.OS === 'web') {
        window.alert('Please record or type some text before saving.');
      } else {
        Alert.alert('Empty Transcript', 'Please record or type some text before saving.');
      }
      return;
    }

    try {
      const updated = await saveTranscript({
        text: transcript,
        title: noteTitle,
        language: selectedLanguage,
      });
      setSavedTranscripts(updated);
      setNoteTitle('');
      if (Platform.OS === 'web') {
        window.alert('Your transcript has been saved successfully!');
      } else {
        Alert.alert('Saved!', 'Your transcript has been saved successfully.');
      }
    } catch (e) {
      Alert.alert('Error', 'Failed to save transcript.');
    }
  };

  const handleDelete = async (id) => {
    const updated = await deleteTranscript(id);
    setSavedTranscripts(updated);
    if (selectedSavedNote && selectedSavedNote.id === id) {
      setSelectedSavedNote(null);
    }
  };

  const handleClearAll = async () => {
    if (Platform.OS === 'web') {
      if (window.confirm('Are you sure you want to delete all saved transcripts?')) {
        const updated = await clearAllTranscripts();
        setSavedTranscripts(updated);
      }
    } else {
      Alert.alert('Confirm Delete', 'Are you sure you want to delete all saved transcripts?', [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete All',
          style: 'destructive',
          onPress: async () => {
            const updated = await clearAllTranscripts();
            setSavedTranscripts(updated);
          },
        },
      ]);
    }
  };

  const copyToClipboard = (text) => {
    if (navigator && navigator.clipboard) {
      navigator.clipboard.writeText(text);
      setCopiedNotice(true);
      setTimeout(() => setCopiedNotice(false), 2000);
    } else {
      Alert.alert('Copied', 'Transcript text copied to clipboard!');
    }
  };

  const currentLangObj = SUPPORTED_LANGUAGES.find((l) => l.code === selectedLanguage) || SUPPORTED_LANGUAGES[0];

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#f8f9fa" />

      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTitleRow}>
          <Ionicons name="mic-circle" size={32} color="#4A90E2" />
          <Text style={styles.headerTitle}>Speech to Text</Text>
        </View>

        <TouchableOpacity
          style={styles.historyButton}
          onPress={() => setHistoryModalVisible(true)}
          accessibilityLabel="View Saved History"
        >
          <Ionicons name="journal-outline" size={22} color="#4A90E2" />
          <Text style={styles.historyButtonText}>Saved ({savedTranscripts.length})</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.contentContainer} keyboardShouldPersistTaps="handled">
        {/* Language Selector Bar */}
        <View style={styles.langSelectorContainer}>
          <Text style={styles.sectionLabel}>Language:</Text>
          <TouchableOpacity
            style={styles.langPickerButton}
            onPress={() => setLangModalVisible(true)}
            accessibilityLabel="Language selector button"
          >
            <Ionicons name="globe-outline" size={18} color="#333" />
            <Text style={styles.langPickerText}>{currentLangObj.name}</Text>
            <Ionicons name="chevron-down" size={16} color="#666" />
          </TouchableOpacity>
        </View>

        {/* Status Indicator */}
        <View style={styles.statusContainer}>
          <Animated.View
            style={[
              styles.statusDot,
              isListening ? styles.statusDotActive : isPaused ? styles.statusDotPaused : styles.statusDotIdle,
              { transform: [{ scale: pulseAnim }] },
            ]}
          />
          <Text style={styles.statusText}>
            {isListening
              ? isSimulated
                ? 'Recording (Demo Simulation Active)...'
                : 'Listening... Speak into microphone'
              : isPaused
              ? 'Recording Paused'
              : 'Ready to Record'}
          </Text>
        </View>

        {error && (
          <View style={styles.errorBox}>
            <Ionicons name="alert-circle-outline" size={18} color="#D0021B" />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {/* Live Audio Visualizer Animation */}
        {isListening && (
          <View style={styles.visualizerContainer}>
            <View style={[styles.waveBar, { height: 20 }]} />
            <View style={[styles.waveBar, { height: 35 }]} />
            <View style={[styles.waveBar, { height: 18 }]} />
            <View style={[styles.waveBar, { height: 42 }]} />
            <View style={[styles.waveBar, { height: 25 }]} />
          </View>
        )}

        {/* Live Transcript Area */}
        <View style={styles.transcriptBox}>
          <View style={styles.transcriptHeader}>
            <Text style={styles.transcriptTitle}>Live Transcript</Text>
            <View style={styles.transcriptActions}>
              <TouchableOpacity
                onPress={() => copyToClipboard(transcript)}
                style={styles.iconBtn}
                accessibilityLabel="Copy Text"
              >
                <Ionicons name="copy-outline" size={20} color="#555" />
              </TouchableOpacity>
              <TouchableOpacity
                onPress={clearTranscript}
                style={styles.iconBtn}
                accessibilityLabel="Clear Text"
              >
                <Ionicons name="trash-outline" size={20} color="#555" />
              </TouchableOpacity>
            </View>
          </View>

          {copiedNotice && (
            <Text style={styles.copiedBanner}>✓ Copied to clipboard!</Text>
          )}

          <TextInput
            style={styles.transcriptInput}
            multiline
            placeholder="Your spoken text will appear here real-time... You can also edit text manually."
            placeholderTextColor="#999"
            value={transcript}
            onChangeText={setTranscript}
            textAlignVertical="top"
          />
        </View>

        {/* Control Buttons */}
        <View style={styles.controlsRow}>
          {!isListening && !isPaused && (
            <TouchableOpacity
              style={[styles.mainButton, styles.startButton]}
              onPress={startListening}
              accessibilityLabel="Start Recording Button"
              activeOpacity={0.7}
            >
              <Ionicons name="mic" size={24} color="#FFF" />
              <Text style={styles.mainButtonText}>Start Recording</Text>
            </TouchableOpacity>
          )}

          {isListening && (
            <>
              <TouchableOpacity
                style={[styles.mainButton, styles.pauseButton]}
                onPress={pauseListening}
                accessibilityLabel="Pause Recording Button"
                activeOpacity={0.7}
              >
                <Ionicons name="pause" size={24} color="#FFF" />
                <Text style={styles.mainButtonText}>Pause Recording</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.mainButton, styles.stopButton]}
                onPress={stopListening}
                accessibilityLabel="Stop Recording Button"
                activeOpacity={0.7}
              >
                <Ionicons name="square" size={22} color="#FFF" />
                <Text style={styles.mainButtonText}>Stop Recording</Text>
              </TouchableOpacity>
            </>
          )}

          {isPaused && (
            <>
              <TouchableOpacity
                style={[styles.mainButton, styles.startButton]}
                onPress={resumeListening}
                accessibilityLabel="Resume Recording Button"
                activeOpacity={0.7}
              >
                <Ionicons name="play" size={24} color="#FFF" />
                <Text style={styles.mainButtonText}>Resume Recording</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.mainButton, styles.stopButton]}
                onPress={stopListening}
                accessibilityLabel="Stop Recording Button"
                activeOpacity={0.7}
              >
                <Ionicons name="square" size={22} color="#FFF" />
                <Text style={styles.mainButtonText}>Stop Recording</Text>
              </TouchableOpacity>
            </>
          )}
        </View>

        {/* Save Transcript Section */}
        <View style={styles.saveSection}>
          <Text style={styles.sectionLabel}>Save Transcript</Text>
          <View style={styles.saveFormRow}>
            <TextInput
              style={styles.titleInput}
              placeholder="Title / Note Name (Optional)"
              value={noteTitle}
              onChangeText={setNoteTitle}
              placeholderTextColor="#999"
            />
            <TouchableOpacity
              style={styles.saveButton}
              onPress={handleSave}
              accessibilityLabel="Save Transcript Button"
              activeOpacity={0.7}
            >
              <Ionicons name="save-outline" size={20} color="#FFF" />
              <Text style={styles.saveButtonText}>Save Note</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Quick History Preview */}
        <View style={styles.recentSection}>
          <View style={styles.recentHeader}>
            <Text style={styles.sectionLabel}>Recent Transcripts</Text>
            {savedTranscripts.length > 0 && (
              <TouchableOpacity onPress={() => setHistoryModalVisible(true)}>
                <Text style={styles.seeAllText}>See All ({savedTranscripts.length})</Text>
              </TouchableOpacity>
            )}
          </View>

          {savedTranscripts.length === 0 ? (
            <Text style={styles.emptyText}>No saved transcripts yet. Start recording and save!</Text>
          ) : (
            savedTranscripts.slice(0, 3).map((item) => (
              <TouchableOpacity
                key={item.id}
                style={styles.recentCard}
                onPress={() => {
                  setSelectedSavedNote(item);
                  setHistoryModalVisible(true);
                }}
              >
                <View style={styles.recentCardHeader}>
                  <Text style={styles.recentCardTitle} numberOfLines={1}>
                    {item.title}
                  </Text>
                  <Text style={styles.recentCardDate}>
                    {new Date(item.date).toLocaleDateString()}
                  </Text>
                </View>
                <Text style={styles.recentCardText} numberOfLines={2}>
                  {item.text}
                </Text>
              </TouchableOpacity>
            ))
          )}
        </View>
      </ScrollView>

      {/* Language Selection Modal */}
      <Modal
        visible={langModalVisible}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setLangModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Select Speech Language</Text>
              <TouchableOpacity onPress={() => setLangModalVisible(false)}>
                <Ionicons name="close" size={24} color="#333" />
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.langList}>
              {SUPPORTED_LANGUAGES.map((lang) => (
                <TouchableOpacity
                  key={lang.code}
                  style={[
                    styles.langOption,
                    selectedLanguage === lang.code && styles.langOptionSelected,
                  ]}
                  onPress={() => {
                    changeLanguage(lang.code);
                    setLangModalVisible(false);
                  }}
                >
                  <Text
                    style={[
                      styles.langOptionText,
                      selectedLanguage === lang.code && styles.langOptionTextSelected,
                    ]}
                  >
                    {lang.name}
                  </Text>
                  {selectedLanguage === lang.code && (
                    <Ionicons name="checkmark" size={20} color="#4A90E2" />
                  )}
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* History & Note Detail Modal */}
      <Modal
        visible={historyModalVisible}
        animationType="slide"
        onRequestClose={() => setHistoryModalVisible(false)}
      >
        <SafeAreaView style={styles.fullModalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={() => setHistoryModalVisible(false)}>
              <Ionicons name="arrow-back" size={24} color="#333" />
            </TouchableOpacity>
            <Text style={styles.modalTitle}>
              {selectedSavedNote ? 'Transcript Detail' : 'Saved Transcripts'}
            </Text>
            {savedTranscripts.length > 0 && !selectedSavedNote ? (
              <TouchableOpacity onPress={handleClearAll}>
                <Text style={styles.clearAllText}>Clear All</Text>
              </TouchableOpacity>
            ) : (
              <View style={{ width: 24 }} />
            )}
          </View>

          {selectedSavedNote ? (
            <ScrollView style={styles.detailContainer}>
              <Text style={styles.detailTitle}>{selectedSavedNote.title}</Text>
              <Text style={styles.detailMeta}>
                Language: {selectedSavedNote.language} | Created:{' '}
                {new Date(selectedSavedNote.date).toLocaleString()}
              </Text>
              <View style={styles.detailBox}>
                <Text style={styles.detailText}>{selectedSavedNote.text}</Text>
              </View>
              <View style={styles.detailActions}>
                <TouchableOpacity
                  style={[styles.detailBtn, styles.copyBtn]}
                  onPress={() => copyToClipboard(selectedSavedNote.text)}
                >
                  <Ionicons name="copy-outline" size={18} color="#FFF" />
                  <Text style={styles.detailBtnText}>Copy Text</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.detailBtn, styles.deleteBtn]}
                  onPress={() => handleDelete(selectedSavedNote.id)}
                >
                  <Ionicons name="trash-outline" size={18} color="#FFF" />
                  <Text style={styles.detailBtnText}>Delete</Text>
                </TouchableOpacity>
              </View>
              <TouchableOpacity
                style={styles.backToListBtn}
                onPress={() => setSelectedSavedNote(null)}
              >
                <Text style={styles.backToListText}>← Back to Saved List</Text>
              </TouchableOpacity>
            </ScrollView>
          ) : (
            <ScrollView style={styles.historyListContainer}>
              {savedTranscripts.length === 0 ? (
                <View style={styles.emptyHistoryState}>
                  <Ionicons name="document-text-outline" size={60} color="#CCC" />
                  <Text style={styles.emptyHistoryText}>No saved transcripts found.</Text>
                </View>
              ) : (
                savedTranscripts.map((item) => (
                  <View key={item.id} style={styles.historyCard}>
                    <TouchableOpacity
                      style={styles.historyCardBody}
                      onPress={() => setSelectedSavedNote(item)}
                    >
                      <Text style={styles.historyCardTitle}>{item.title}</Text>
                      <Text style={styles.historyCardDate}>
                        {new Date(item.date).toLocaleString()}
                      </Text>
                      <Text style={styles.historyCardSnippet} numberOfLines={2}>
                        {item.text}
                      </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.historyDeleteIcon}
                      onPress={() => handleDelete(item.id)}
                    >
                      <Ionicons name="trash-outline" size={20} color="#D0021B" />
                    </TouchableOpacity>
                  </View>
                ))
              )}
            </ScrollView>
          )}
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 18,
    paddingVertical: 14,
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#EAEAEA',
  },
  headerTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1A1A1A',
    marginLeft: 8,
  },
  historyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0F4F8',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  historyButtonText: {
    fontSize: 13,
    color: '#4A90E2',
    fontWeight: '600',
    marginLeft: 4,
  },
  contentContainer: {
    padding: 16,
  },
  langSelectorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#555',
  },
  langPickerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginLeft: 8,
  },
  langPickerText: {
    fontSize: 14,
    color: '#333',
    marginHorizontal: 6,
    fontWeight: '500',
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    padding: 10,
    borderRadius: 8,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#EEE',
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: 8,
  },
  statusDotActive: {
    backgroundColor: '#2ECC71',
  },
  statusDotPaused: {
    backgroundColor: '#F39C12',
  },
  statusDotIdle: {
    backgroundColor: '#95A5A6',
  },
  statusText: {
    fontSize: 13,
    color: '#444',
    fontWeight: '500',
  },
  errorBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FADBD8',
    padding: 10,
    borderRadius: 8,
    marginBottom: 12,
  },
  errorText: {
    fontSize: 12,
    color: '#78281F',
    marginLeft: 6,
    flex: 1,
  },
  visualizerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 50,
    marginBottom: 12,
    gap: 6,
  },
  waveBar: {
    width: 6,
    backgroundColor: '#4A90E2',
    borderRadius: 3,
  },
  transcriptBox: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E1E4E8',
    padding: 14,
    minHeight: 180,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  transcriptHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
    paddingBottom: 6,
  },
  transcriptTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
  },
  transcriptActions: {
    flexDirection: 'row',
    gap: 12,
  },
  iconBtn: {
    padding: 4,
  },
  copiedBanner: {
    fontSize: 12,
    color: '#27AE60',
    fontWeight: '600',
    marginBottom: 6,
  },
  transcriptInput: {
    fontSize: 16,
    lineHeight: 24,
    color: '#222',
    minHeight: 130,
  },
  controlsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
    marginBottom: 20,
  },
  mainButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 25,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 3,
  },
  startButton: {
    backgroundColor: '#4A90E2',
  },
  pauseButton: {
    backgroundColor: '#F39C12',
  },
  stopButton: {
    backgroundColor: '#E74C3C',
  },
  mainButtonText: {
    color: '#FFF',
    fontSize: 15,
    fontWeight: '700',
    marginLeft: 6,
  },
  saveSection: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 14,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E1E4E8',
  },
  saveFormRow: {
    flexDirection: 'row',
    marginTop: 8,
    gap: 8,
  },
  titleInput: {
    flex: 1,
    backgroundColor: '#F8F9FA',
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 14,
    color: '#333',
  },
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2ECC71',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
  },
  saveButtonText: {
    color: '#FFF',
    fontWeight: '700',
    marginLeft: 4,
  },
  recentSection: {
    marginTop: 4,
  },
  recentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  seeAllText: {
    fontSize: 13,
    color: '#4A90E2',
    fontWeight: '600',
  },
  emptyText: {
    fontSize: 13,
    color: '#888',
    fontStyle: 'italic',
    textAlign: 'center',
    marginTop: 10,
  },
  recentCard: {
    backgroundColor: '#FFF',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#EAEAEA',
  },
  recentCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  recentCardTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    flex: 1,
  },
  recentCardDate: {
    fontSize: 12,
    color: '#999',
  },
  recentCardText: {
    fontSize: 13,
    color: '#666',
    lineHeight: 18,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFF',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    maxHeight: '70%',
    padding: 16,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#EEE',
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#333',
  },
  langList: {
    marginTop: 8,
  },
  langOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F5F5F5',
  },
  langOptionSelected: {
    backgroundColor: '#F0F7FF',
    borderRadius: 6,
  },
  langOptionText: {
    fontSize: 15,
    color: '#333',
  },
  langOptionTextSelected: {
    fontWeight: '700',
    color: '#4A90E2',
  },
  fullModalContainer: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  clearAllText: {
    fontSize: 14,
    color: '#D0021B',
    fontWeight: '600',
  },
  historyListContainer: {
    padding: 16,
  },
  emptyHistoryState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: 60,
  },
  emptyHistoryText: {
    fontSize: 15,
    color: '#999',
    marginTop: 12,
  },
  historyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#EAEAEA',
  },
  historyCardBody: {
    flex: 1,
  },
  historyCardTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#222',
  },
  historyCardDate: {
    fontSize: 11,
    color: '#888',
    marginVertical: 2,
  },
  historyCardSnippet: {
    fontSize: 13,
    color: '#555',
  },
  historyDeleteIcon: {
    padding: 8,
  },
  detailContainer: {
    padding: 16,
  },
  detailTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#222',
    marginBottom: 6,
  },
  detailMeta: {
    fontSize: 12,
    color: '#777',
    marginBottom: 16,
  },
  detailBox: {
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 10,
    padding: 16,
    minHeight: 150,
    marginBottom: 16,
  },
  detailText: {
    fontSize: 15,
    lineHeight: 22,
    color: '#333',
  },
  detailActions: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  detailBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 8,
  },
  copyBtn: {
    backgroundColor: '#4A90E2',
  },
  deleteBtn: {
    backgroundColor: '#E74C3C',
  },
  detailBtnText: {
    color: '#FFF',
    fontWeight: '600',
    marginLeft: 6,
  },
  backToListBtn: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  backToListText: {
    color: '#4A90E2',
    fontSize: 14,
    fontWeight: '600',
  },
});
