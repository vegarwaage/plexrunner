// ABOUTME: Plex API client for browsing audiobook library
// ABOUTME: Handles authentication, library fetching, and metadata parsing

import {
  PlexConfig,
  Audiobook,
  PlexLibrary,
  PlexMetadata,
  PlexResponse,
} from '../types';

export class PlexApi {
  constructor(private config: PlexConfig) {}

  /**
   * Test connection to Plex server
   * @returns true if connection successful, throws error otherwise
   */
  async testConnection(): Promise<boolean> {
    const url = `${this.config.serverUrl}/library/sections?X-Plex-Token=${this.config.authToken}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(
        `Plex connection failed: ${response.status} ${response.statusText}`
      );
    }

    return true;
  }

  /**
   * Get all library sections from Plex server
   * @returns Array of library objects
   */
  async getLibraries(): Promise<PlexLibrary[]> {
    const url = `${this.config.serverUrl}/library/sections?X-Plex-Token=${this.config.authToken}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch libraries: ${response.statusText}`);
    }

    const data: PlexResponse<never> = await response.json();

    if (!data.MediaContainer.Directory) {
      return [];
    }

    return data.MediaContainer.Directory;
  }

  /**
   * Find library ID by name
   * @param name Library name (e.g., "Music")
   * @returns Library key/ID or null if not found
   */
  async findLibraryByName(name: string): Promise<string | null> {
    const libraries = await this.getLibraries();
    const library = libraries.find(
      (lib) => lib.title.toLowerCase() === name.toLowerCase()
    );
    return library ? library.key : null;
  }

  /**
   * Get audiobooks from a specific library
   * @param libraryId Library section key
   * @returns Array of audiobook objects
   */
  async getAudiobooks(libraryId: string): Promise<Audiobook[]> {
    const url = `${this.config.serverUrl}/library/sections/${libraryId}/all?X-Plex-Token=${this.config.authToken}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch audiobooks: ${response.statusText}`);
    }

    const data: PlexResponse<PlexMetadata> = await response.json();

    if (!data.MediaContainer.Metadata) {
      return [];
    }

    return data.MediaContainer.Metadata.map((item) => this.parseAudiobook(item));
  }

  /**
   * Get audiobooks from configured library name
   * @returns Array of audiobook objects
   */
  async getAudiobooksFromConfiguredLibrary(): Promise<Audiobook[]> {
    const libraryId = await this.findLibraryByName(this.config.libraryName);

    if (!libraryId) {
      throw new Error(
        `Library "${this.config.libraryName}" not found. Available libraries can be viewed in Plex settings.`
      );
    }

    return this.getAudiobooks(libraryId);
  }

  /**
   * Parse Plex metadata into Audiobook object
   * @param metadata Raw Plex metadata
   * @returns Audiobook object
   */
  private parseAudiobook(metadata: PlexMetadata): Audiobook {
    // Author can be in parentTitle or grandparentTitle depending on Plex library structure
    const author =
      metadata.parentTitle || metadata.grandparentTitle || 'Unknown Author';

    const thumbUrl = metadata.thumb
      ? `${this.config.serverUrl}${metadata.thumb}?X-Plex-Token=${this.config.authToken}`
      : undefined;

    return {
      ratingKey: metadata.ratingKey,
      title: metadata.title,
      author,
      duration: metadata.duration,
      thumbUrl,
    };
  }

  /**
   * Format duration from milliseconds to human-readable string
   * @param ms Duration in milliseconds
   * @returns Formatted string (e.g., "12h 34m")
   */
  static formatDuration(ms: number): string {
    const hours = Math.floor(ms / 3600000);
    const minutes = Math.floor((ms % 3600000) / 60000);

    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }

    return `${minutes}m`;
  }
}
