import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = '@speech_to_text_transcripts';

/**
 * Fetch all saved transcripts
 * @returns {Promise<Array<{id: string, text: string, title: string, language: string, date: string}>>}
 */
export const getTranscripts = async () => {
  try {
    const jsonValue = await AsyncStorage.getItem(STORAGE_KEY);
    return jsonValue != null ? JSON.parse(jsonValue) : [];
  } catch (error) {
    console.error('Error reading transcripts from storage:', error);
    return [];
  }
};

/**
 * Save a new transcript
 * @param {Object} transcriptData
 * @param {string} transcriptData.text
 * @param {string} [transcriptData.title]
 * @param {string} [transcriptData.language]
 * @returns {Promise<Array>} Updated transcripts list
 */
export const saveTranscript = async ({ text, title, language = 'en-US' }) => {
  if (!text || !text.trim()) return await getTranscripts();

  try {
    const existingTranscripts = await getTranscripts();
    const newEntry = {
      id: Date.now().toString(),
      text: text.trim(),
      title: title && title.trim() ? title.trim() : `Note ${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`,
      language,
      date: new Date().toISOString(),
    };

    const updatedTranscripts = [newEntry, ...existingTranscripts];
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedTranscripts));
    return updatedTranscripts;
  } catch (error) {
    console.error('Error saving transcript to storage:', error);
    throw error;
  }
};

/**
 * Delete a transcript by ID
 * @param {string} id
 * @returns {Promise<Array>} Updated transcripts list
 */
export const deleteTranscript = async (id) => {
  try {
    const existingTranscripts = await getTranscripts();
    const updatedTranscripts = existingTranscripts.filter(item => item.id !== id);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedTranscripts));
    return updatedTranscripts;
  } catch (error) {
    console.error('Error deleting transcript from storage:', error);
    throw error;
  }
};

/**
 * Update an existing transcript
 * @param {string} id
 * @param {Object} updates - Fields to update (e.g. { title, text })
 * @returns {Promise<Array>} Updated transcripts list
 */
export const updateTranscript = async (id, updates) => {
  try {
    const existingTranscripts = await getTranscripts();
    const updatedTranscripts = existingTranscripts.map(item => {
      if (item.id === id) {
        return {
          ...item,
          ...updates,
          updatedAt: new Date().toISOString(),
        };
      }
      return item;
    });
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedTranscripts));
    return updatedTranscripts;
  } catch (error) {
    console.error('Error updating transcript:', error);
    throw error;
  }
};

/**
 * Clear all saved transcripts
 */
export const clearAllTranscripts = async () => {
  try {
    await AsyncStorage.removeItem(STORAGE_KEY);
    return [];
  } catch (error) {
    console.error('Error clearing transcripts:', error);
    throw error;
  }
};
