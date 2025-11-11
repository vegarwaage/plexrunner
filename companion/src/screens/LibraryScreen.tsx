// ABOUTME: Main audiobook library browsing screen
// ABOUTME: Displays audiobooks with selection and sync to watch functionality

import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Image,
} from 'react-native';
import { useApp } from '../context/AppContext';
import { Button } from '../components/Button';
import { ErrorAlert } from '../components/ErrorAlert';
import { Audiobook } from '../types';
import { PlexApi } from '../api/plex';

interface LibraryScreenProps {
  onSettings: () => void;
}

export const LibraryScreen: React.FC<LibraryScreenProps> = ({ onSettings }) => {
  const {
    audiobooks,
    selectedRatingKeys,
    isLoading,
    error,
    syncStatus,
    currentDevice,
    loadAudiobooks,
    toggleAudiobookSelection,
    syncToWatch,
    clearError,
    refreshDevices,
  } = useApp();

  useEffect(() => {
    loadAudiobooks();
    refreshDevices();
  }, []);

  const handleSyncPress = () => {
    if (syncStatus === 'idle' || syncStatus === 'error') {
      syncToWatch();
    }
  };

  const getSyncButtonTitle = () => {
    switch (syncStatus) {
      case 'connecting':
        return 'Connecting...';
      case 'sending':
        return 'Sending...';
      case 'success':
        return 'Success!';
      case 'error':
        return 'Retry Sync';
      default:
        return `Sync to Watch (${selectedRatingKeys.length})`;
    }
  };

  const renderAudiobookCard = ({ item }: { item: Audiobook }) => {
    const isSelected = selectedRatingKeys.includes(item.ratingKey);

    return (
      <TouchableOpacity
        style={[styles.card, isSelected && styles.selectedCard]}
        onPress={() => toggleAudiobookSelection(item.ratingKey)}
        activeOpacity={0.7}
      >
        <View style={styles.checkbox}>
          {isSelected && <View style={styles.checkboxChecked} />}
        </View>

        {item.thumbUrl && (
          <Image
            source={{ uri: item.thumbUrl }}
            style={styles.cover}
            resizeMode="cover"
          />
        )}

        {!item.thumbUrl && (
          <View style={[styles.cover, styles.coverPlaceholder]}>
            <Text style={styles.coverPlaceholderText}>📚</Text>
          </View>
        )}

        <View style={styles.info}>
          <Text style={styles.title} numberOfLines={2}>
            {item.title}
          </Text>
          <Text style={styles.author} numberOfLines={1}>
            {item.author}
          </Text>
          <Text style={styles.duration}>
            {PlexApi.formatDuration(item.duration)}
          </Text>
        </View>
      </TouchableOpacity>
    );
  };

  const renderEmptyState = () => {
    if (isLoading) {
      return null;
    }

    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyStateText}>No audiobooks found</Text>
        <Text style={styles.emptyStateHint}>
          Check your Plex library configuration
        </Text>
      </View>
    );
  };

  const renderHeader = () => (
    <View style={styles.header}>
      <View style={styles.headerTop}>
        <TouchableOpacity onPress={onSettings}>
          <Text style={styles.settingsButton}>⚙️ Settings</Text>
        </TouchableOpacity>

        <View style={styles.deviceStatus}>
          {currentDevice ? (
            <View style={styles.deviceConnected}>
              <View style={styles.statusIndicator} />
              <Text style={styles.deviceName}>{currentDevice.friendlyName}</Text>
            </View>
          ) : (
            <Text style={styles.deviceDisconnected}>No watch connected</Text>
          )}
        </View>
      </View>

      <Text style={styles.headerTitle}>Audiobooks</Text>

      {audiobooks.length > 0 && (
        <Text style={styles.headerSubtitle}>
          {audiobooks.length} audiobook{audiobooks.length !== 1 ? 's' : ''} available
        </Text>
      )}
    </View>
  );

  return (
    <View style={styles.container}>
      {isLoading && audiobooks.length === 0 ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Loading audiobooks...</Text>
        </View>
      ) : (
        <>
          <FlatList
            data={audiobooks}
            renderItem={renderAudiobookCard}
            keyExtractor={(item) => item.ratingKey}
            ListHeaderComponent={renderHeader}
            ListEmptyComponent={renderEmptyState}
            contentContainerStyle={styles.listContent}
          />

          {selectedRatingKeys.length > 0 && (
            <View style={styles.footer}>
              <Button
                title={getSyncButtonTitle()}
                onPress={handleSyncPress}
                disabled={
                  syncStatus === 'connecting' ||
                  syncStatus === 'sending' ||
                  syncStatus === 'success' ||
                  !currentDevice
                }
                loading={syncStatus === 'connecting' || syncStatus === 'sending'}
                style={styles.syncButton}
              />
            </View>
          )}
        </>
      )}

      {error && (
        <ErrorAlert
          error={error}
          onDismiss={clearError}
          onRetry={error.category === 'plex' ? loadAudiobooks : syncToWatch}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 16,
  },
  loadingText: {
    fontSize: 16,
    color: '#666',
  },
  header: {
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  settingsButton: {
    fontSize: 16,
    color: '#007AFF',
  },
  deviceStatus: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  deviceConnected: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  statusIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#34C759',
  },
  deviceName: {
    fontSize: 12,
    color: '#666',
  },
  deviceDisconnected: {
    fontSize: 12,
    color: '#999',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#666',
  },
  listContent: {
    padding: 16,
    gap: 16,
  },
  card: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 12,
    borderWidth: 2,
    borderColor: 'transparent',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  selectedCard: {
    borderColor: '#007AFF',
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#ddd',
    marginRight: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxChecked: {
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: '#007AFF',
  },
  cover: {
    width: 60,
    height: 60,
    borderRadius: 8,
    marginRight: 12,
  },
  coverPlaceholder: {
    backgroundColor: '#e0e0e0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  coverPlaceholderText: {
    fontSize: 24,
  },
  info: {
    flex: 1,
    justifyContent: 'center',
    gap: 4,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  author: {
    fontSize: 14,
    color: '#666',
  },
  duration: {
    fontSize: 12,
    color: '#999',
  },
  emptyState: {
    padding: 40,
    alignItems: 'center',
    gap: 8,
  },
  emptyStateText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#666',
  },
  emptyStateHint: {
    fontSize: 14,
    color: '#999',
  },
  footer: {
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  syncButton: {
    width: '100%',
  },
});
