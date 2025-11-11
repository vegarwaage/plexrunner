// ABOUTME: Initial setup screen for configuring Plex server connection
// ABOUTME: Collects server URL, auth token, and library name with validation

import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useApp } from '../context/AppContext';
import { Button } from '../components/Button';
import { ErrorAlert } from '../components/ErrorAlert';

interface SetupScreenProps {
  onComplete: () => void;
}

export const SetupScreen: React.FC<SetupScreenProps> = ({ onComplete }) => {
  const { savePlexConfig, isLoading, error, clearError } = useApp();

  const [serverUrl, setServerUrl] = useState('');
  const [authToken, setAuthToken] = useState('');
  const [libraryName, setLibraryName] = useState('Music');

  const handleConnect = async () => {
    if (!serverUrl.trim()) {
      return;
    }

    if (!authToken.trim()) {
      return;
    }

    try {
      await savePlexConfig({
        serverUrl: serverUrl.trim(),
        authToken: authToken.trim(),
        libraryName: libraryName.trim() || 'Music',
      });

      // If successful, navigate to library
      onComplete();
    } catch (error) {
      // Error is handled by context
      console.error('Setup failed:', error);
    }
  };

  const canSubmit = serverUrl.trim().length > 0 && authToken.trim().length > 0;

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>PlexRunner Setup</Text>
          <Text style={styles.subtitle}>
            Connect to your Plex server to browse audiobooks
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.field}>
            <Text style={styles.label}>Plex Server URL</Text>
            <TextInput
              style={styles.input}
              placeholder="https://plex.example.com:32400"
              value={serverUrl}
              onChangeText={setServerUrl}
              autoCapitalize="none"
              autoCorrect={false}
              keyboardType="url"
            />
            <Text style={styles.hint}>
              Your Plex server address including port
            </Text>
          </View>

          <View style={styles.field}>
            <Text style={styles.label}>Auth Token</Text>
            <TextInput
              style={styles.input}
              placeholder="Enter your Plex auth token"
              value={authToken}
              onChangeText={setAuthToken}
              autoCapitalize="none"
              autoCorrect={false}
              secureTextEntry
            />
            <Text style={styles.hint}>
              Get from plex.tv → Account → View XML
            </Text>
          </View>

          <View style={styles.field}>
            <Text style={styles.label}>Library Name (optional)</Text>
            <TextInput
              style={styles.input}
              placeholder="Music"
              value={libraryName}
              onChangeText={setLibraryName}
              autoCapitalize="words"
              autoCorrect={false}
            />
            <Text style={styles.hint}>
              Name of your Music library containing audiobooks
            </Text>
          </View>

          <Button
            title="Connect"
            onPress={handleConnect}
            disabled={!canSubmit}
            loading={isLoading}
            style={styles.connectButton}
          />
        </View>
      </ScrollView>

      {error && (
        <ErrorAlert
          error={error}
          onDismiss={clearError}
          onRetry={handleConnect}
        />
      )}
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollContent: {
    flexGrow: 1,
    padding: 20,
  },
  header: {
    marginTop: 40,
    marginBottom: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#000',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  form: {
    gap: 24,
  },
  field: {
    gap: 8,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
  },
  hint: {
    fontSize: 12,
    color: '#999',
  },
  connectButton: {
    marginTop: 16,
  },
});
