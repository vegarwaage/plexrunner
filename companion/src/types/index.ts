// ABOUTME: PlexRunner Companion App - TypeScript type definitions
// ABOUTME: Shared interfaces and types for Plex integration and app state

export interface PlexConfig {
  serverUrl: string;
  authToken: string;
  libraryName: string;
}

export interface Audiobook {
  ratingKey: string;
  title: string;
  author: string;
  duration: number; // milliseconds
  thumbUrl?: string;
}

export interface PlexLibrary {
  key: string;
  title: string;
  type: string;
}

export interface PlexMetadata {
  ratingKey: string;
  title: string;
  parentTitle?: string; // author for audiobooks
  grandparentTitle?: string; // fallback author field
  duration: number;
  thumb?: string;
}

export interface PlexResponse<T> {
  MediaContainer: {
    Metadata?: T[];
    Directory?: PlexLibrary[];
  };
}

export type SyncStatus = 'idle' | 'connecting' | 'sending' | 'success' | 'error';

export interface AppError {
  title: string;
  message: string;
  category: 'plex' | 'garmin' | 'network' | 'user';
}

export interface GarminDevice {
  deviceId: string;
  friendlyName: string;
  status: 'connected' | 'disconnected';
}
