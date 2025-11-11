// ABOUTME: PlexRunner Companion App main entry point
// ABOUTME: Sets up navigation, context provider, and screen management

import React, { useState, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppProvider, useApp } from './src/context/AppContext';
import { SetupScreen } from './src/screens/SetupScreen';
import { LibraryScreen } from './src/screens/LibraryScreen';
import { SettingsScreen } from './src/screens/SettingsScreen';

type Screen = 'setup' | 'library' | 'settings';

function AppContent() {
  const { isConfigured } = useApp();
  const [currentScreen, setCurrentScreen] = useState<Screen>(
    isConfigured ? 'library' : 'setup'
  );

  useEffect(() => {
    if (isConfigured && currentScreen === 'setup') {
      setCurrentScreen('library');
    }
  }, [isConfigured]);

  const renderScreen = () => {
    switch (currentScreen) {
      case 'setup':
        return (
          <SetupScreen onComplete={() => setCurrentScreen('library')} />
        );

      case 'library':
        return (
          <LibraryScreen
            onSettings={() => setCurrentScreen('settings')}
          />
        );

      case 'settings':
        return (
          <SettingsScreen
            onBack={() => setCurrentScreen('library')}
            onReconfigure={() => setCurrentScreen('setup')}
          />
        );

      default:
        return null;
    }
  };

  return (
    <>
      {renderScreen()}
      <StatusBar style="auto" />
    </>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppProvider>
        <AppContent />
      </AppProvider>
    </SafeAreaProvider>
  );
}
