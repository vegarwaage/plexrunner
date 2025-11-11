// ABOUTME: Global application state management using React Context
// ABOUTME: Manages Plex config, audiobooks, selection state, and sync status

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { PlexConfig, Audiobook, SyncStatus, AppError, GarminDevice } from '../types';
import { PlexApi } from '../api/plex';
import { garminService } from '../services/garmin';

const STORAGE_KEY_PLEX_CONFIG = '@PlexRunner:plexConfig';

interface AppState {
  // Configuration
  plexConfig: PlexConfig | null;
  isConfigured: boolean;

  // Data
  audiobooks: Audiobook[];
  selectedRatingKeys: string[];

  // Status
  isLoading: boolean;
  error: AppError | null;
  syncStatus: SyncStatus;

  // Garmin
  connectedDevices: GarminDevice[];
  currentDevice: GarminDevice | null;
}

interface AppActions {
  // Config
  savePlexConfig: (config: PlexConfig) => Promise<void>;
  loadPlexConfig: () => Promise<void>;
  clearPlexConfig: () => Promise<void>;

  // Audiobooks
  loadAudiobooks: () => Promise<void>;
  toggleAudiobookSelection: (ratingKey: string) => void;
  clearSelection: () => void;

  // Garmin
  initializeGarmin: () => Promise<void>;
  refreshDevices: () => Promise<void>;
  selectDevice: (device: GarminDevice) => void;

  // Sync
  syncToWatch: () => Promise<void>;

  // Error handling
  clearError: () => void;
}

type AppContextType = AppState & AppActions;

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, setState] = useState<AppState>({
    plexConfig: null,
    isConfigured: false,
    audiobooks: [],
    selectedRatingKeys: [],
    isLoading: false,
    error: null,
    syncStatus: 'idle',
    connectedDevices: [],
    currentDevice: null,
  });

  // Load Plex config on mount
  useEffect(() => {
    loadPlexConfig();
    initializeGarmin();
  }, []);

  const savePlexConfig = async (config: PlexConfig): Promise<void> => {
    try {
      setState((prev) => ({ ...prev, isLoading: true, error: null }));

      // Validate config by testing connection
      const api = new PlexApi(config);
      await api.testConnection();

      // Save to storage
      await AsyncStorage.setItem(STORAGE_KEY_PLEX_CONFIG, JSON.stringify(config));

      setState((prev) => ({
        ...prev,
        plexConfig: config,
        isConfigured: true,
        isLoading: false,
      }));
    } catch (error) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: {
          title: 'Connection Failed',
          message: error instanceof Error ? error.message : 'Failed to connect to Plex server',
          category: 'plex',
        },
      }));
      throw error;
    }
  };

  const loadPlexConfig = async (): Promise<void> => {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEY_PLEX_CONFIG);
      if (stored) {
        const config: PlexConfig = JSON.parse(stored);
        setState((prev) => ({
          ...prev,
          plexConfig: config,
          isConfigured: true,
        }));
      }
    } catch (error) {
      console.error('Failed to load Plex config:', error);
    }
  };

  const clearPlexConfig = async (): Promise<void> => {
    try {
      await AsyncStorage.removeItem(STORAGE_KEY_PLEX_CONFIG);
      setState((prev) => ({
        ...prev,
        plexConfig: null,
        isConfigured: false,
        audiobooks: [],
        selectedRatingKeys: [],
      }));
    } catch (error) {
      console.error('Failed to clear Plex config:', error);
    }
  };

  const loadAudiobooks = async (): Promise<void> => {
    if (!state.plexConfig) {
      setState((prev) => ({
        ...prev,
        error: {
          title: 'Not Configured',
          message: 'Please configure Plex server connection first',
          category: 'user',
        },
      }));
      return;
    }

    try {
      setState((prev) => ({ ...prev, isLoading: true, error: null }));

      const api = new PlexApi(state.plexConfig);
      const audiobooks = await api.getAudiobooksFromConfiguredLibrary();

      setState((prev) => ({
        ...prev,
        audiobooks,
        isLoading: false,
      }));
    } catch (error) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: {
          title: 'Load Failed',
          message: error instanceof Error ? error.message : 'Failed to load audiobooks',
          category: 'plex',
        },
      }));
    }
  };

  const toggleAudiobookSelection = (ratingKey: string): void => {
    setState((prev) => {
      const isSelected = prev.selectedRatingKeys.includes(ratingKey);
      const newSelection = isSelected
        ? prev.selectedRatingKeys.filter((key) => key !== ratingKey)
        : [...prev.selectedRatingKeys, ratingKey];

      return {
        ...prev,
        selectedRatingKeys: newSelection,
      };
    });
  };

  const clearSelection = (): void => {
    setState((prev) => ({
      ...prev,
      selectedRatingKeys: [],
    }));
  };

  const initializeGarmin = async (): Promise<void> => {
    try {
      await garminService.initialize();
      await refreshDevices();
    } catch (error) {
      console.error('Failed to initialize Garmin:', error);
      setState((prev) => ({
        ...prev,
        error: {
          title: 'Garmin SDK Error',
          message: error instanceof Error ? error.message : 'Failed to initialize Garmin SDK',
          category: 'garmin',
        },
      }));
    }
  };

  const refreshDevices = async (): Promise<void> => {
    try {
      const devices = await garminService.getConnectedDevices();
      setState((prev) => ({
        ...prev,
        connectedDevices: devices,
        currentDevice: devices.length > 0 ? devices[0] : null,
      }));
    } catch (error) {
      console.error('Failed to refresh devices:', error);
    }
  };

  const selectDevice = (device: GarminDevice): void => {
    setState((prev) => ({
      ...prev,
      currentDevice: device,
    }));
  };

  const syncToWatch = async (): Promise<void> => {
    if (!state.currentDevice) {
      setState((prev) => ({
        ...prev,
        error: {
          title: 'No Device',
          message: 'No Garmin device connected. Please connect your watch via Garmin Connect app.',
          category: 'garmin',
        },
      }));
      return;
    }

    if (state.selectedRatingKeys.length === 0) {
      setState((prev) => ({
        ...prev,
        error: {
          title: 'No Selection',
          message: 'Please select at least one audiobook to sync',
          category: 'user',
        },
      }));
      return;
    }

    try {
      setState((prev) => ({ ...prev, syncStatus: 'connecting', error: null }));

      // Check if PlexRunner is installed
      const isInstalled = await garminService.isPlexRunnerInstalled(state.currentDevice);
      if (!isInstalled) {
        throw new Error('PlexRunner app not found on watch. Please install it first.');
      }

      setState((prev) => ({ ...prev, syncStatus: 'sending' }));

      // Send sync list
      await garminService.sendSyncList(
        state.currentDevice.deviceId,
        state.selectedRatingKeys
      );

      setState((prev) => ({
        ...prev,
        syncStatus: 'success',
        selectedRatingKeys: [], // Clear selection after successful sync
      }));

      // Reset status after 3 seconds
      setTimeout(() => {
        setState((prev) => ({ ...prev, syncStatus: 'idle' }));
      }, 3000);
    } catch (error) {
      setState((prev) => ({
        ...prev,
        syncStatus: 'error',
        error: {
          title: 'Sync Failed',
          message: error instanceof Error ? error.message : 'Failed to sync to watch',
          category: 'garmin',
        },
      }));
    }
  };

  const clearError = (): void => {
    setState((prev) => ({ ...prev, error: null }));
  };

  const contextValue: AppContextType = {
    ...state,
    savePlexConfig,
    loadPlexConfig,
    clearPlexConfig,
    loadAudiobooks,
    toggleAudiobookSelection,
    clearSelection,
    initializeGarmin,
    refreshDevices,
    selectDevice,
    syncToWatch,
    clearError,
  };

  return <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>;
};

export const useApp = (): AppContextType => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
};
