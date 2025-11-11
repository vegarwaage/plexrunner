// ABOUTME: Settings screen for viewing and editing Plex configuration
// ABOUTME: Shows connection status and allows reconfiguration

import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useApp } from '../context/AppContext';
import { Button } from '../components/Button';

interface SettingsScreenProps {
  onBack: () => void;
  onReconfigure: () => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({
  onBack,
  onReconfigure,
}) => {
  const { plexConfig, currentDevice, connectedDevices, clearPlexConfig } = useApp();

  const handleReconfigure = async () => {
    await clearPlexConfig();
    onReconfigure();
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Settings</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Plex Server</Text>

        <View style={styles.field}>
          <Text style={styles.fieldLabel}>Server URL</Text>
          <Text style={styles.fieldValue}>
            {plexConfig?.serverUrl || 'Not configured'}
          </Text>
        </View>

        <View style={styles.field}>
          <Text style={styles.fieldLabel}>Auth Token</Text>
          <Text style={styles.fieldValue}>
            {plexConfig?.authToken ? '••••••••••••••••' : 'Not configured'}
          </Text>
        </View>

        <View style={styles.field}>
          <Text style={styles.fieldLabel}>Library Name</Text>
          <Text style={styles.fieldValue}>
            {plexConfig?.libraryName || 'Music'}
          </Text>
        </View>

        <Button
          title="Reconfigure"
          onPress={handleReconfigure}
          variant="secondary"
          style={styles.reconfigureButton}
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Watch Connection</Text>

        {currentDevice ? (
          <View style={styles.deviceInfo}>
            <View style={styles.statusRow}>
              <View style={styles.statusIndicatorConnected} />
              <Text style={styles.statusText}>Connected</Text>
            </View>
            <Text style={styles.deviceName}>{currentDevice.friendlyName}</Text>
            <Text style={styles.deviceId}>ID: {currentDevice.deviceId}</Text>
          </View>
        ) : (
          <View style={styles.deviceInfo}>
            <View style={styles.statusRow}>
              <View style={styles.statusIndicatorDisconnected} />
              <Text style={styles.statusText}>Not connected</Text>
            </View>
            <Text style={styles.hint}>
              Connect your Garmin watch via Garmin Connect app
            </Text>
          </View>
        )}

        {connectedDevices.length > 1 && (
          <View style={styles.multipleDevices}>
            <Text style={styles.hint}>
              {connectedDevices.length} devices connected
            </Text>
          </View>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <Text style={styles.aboutText}>
          PlexRunner Companion {'\n'}
          Version 1.0.0 {'\n\n'}
          Browse and sync audiobooks from your Plex server to your Garmin watch.
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    padding: 20,
    paddingTop: 40,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  backButton: {
    fontSize: 16,
    color: '#007AFF',
    marginBottom: 12,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
  },
  section: {
    backgroundColor: '#fff',
    marginTop: 20,
    padding: 20,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#e0e0e0',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
    color: '#000',
  },
  field: {
    marginBottom: 16,
  },
  fieldLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  fieldValue: {
    fontSize: 16,
    color: '#000',
  },
  reconfigureButton: {
    marginTop: 8,
  },
  deviceInfo: {
    gap: 8,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  statusIndicatorConnected: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#34C759',
  },
  statusIndicatorDisconnected: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#FF3B30',
  },
  statusText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  deviceName: {
    fontSize: 16,
    color: '#000',
  },
  deviceId: {
    fontSize: 12,
    color: '#999',
  },
  hint: {
    fontSize: 14,
    color: '#666',
  },
  multipleDevices: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  aboutText: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
});
