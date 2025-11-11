// ABOUTME: Garmin Connect IQ SDK integration service
// ABOUTME: Handles device connection and message sending to watch app

import * as ConnectIQ from 'react-native-connect-iq-mobile-sdk';
import { GarminDevice } from '../types';

// PlexRunner watch app UUID (from manifest.xml)
const PLEXRUNNER_APP_ID = '7362c2a0f1805be30d6fdfa43b1178bb';

export class GarminService {
  private initialized = false;

  /**
   * Initialize the Garmin Connect IQ SDK
   * Must be called before any other operations
   */
  async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      await ConnectIQ.init({
        urlScheme: 'plexrunner', // Deep link scheme
      });

      // Register for app messages from watch
      await ConnectIQ.registerForAppMessages(PLEXRUNNER_APP_ID);

      this.initialized = true;
    } catch (error) {
      throw new Error(
        `Failed to initialize Garmin SDK: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Get list of connected Garmin devices
   * @returns Array of connected devices
   */
  async getConnectedDevices(): Promise<GarminDevice[]> {
    this.ensureInitialized();

    try {
      const devices = await ConnectIQ.getConnectedDevices();

      if (!devices || devices.length === 0) {
        return [];
      }

      return devices.map((device) => ({
        deviceId: device.deviceIdentifier,
        friendlyName: device.friendlyName,
        status: device.status === 'CONNECTED' ? 'connected' : 'disconnected',
      }));
    } catch (error) {
      console.error('Failed to get connected devices:', error);
      return [];
    }
  }

  /**
   * Check if PlexRunner app is installed on a device
   * @param device Device to check
   * @returns true if app is installed
   */
  async isPlexRunnerInstalled(device: GarminDevice): Promise<boolean> {
    this.ensureInitialized();

    try {
      // Set the device to check
      await ConnectIQ.setDevice({
        deviceIdentifier: device.deviceId,
        friendlyName: device.friendlyName,
        status: device.status === 'connected'
          ? ConnectIQ.CIQDeviceStatus.CONNECTED
          : ConnectIQ.CIQDeviceStatus.NOT_CONNECTED,
      });

      // Get application info
      const appInfo = await ConnectIQ.getApplicationInfo(PLEXRUNNER_APP_ID);

      // If we get info back, app is installed
      return appInfo !== null && appInfo !== undefined;
    } catch (error) {
      console.error('Failed to check app installation:', error);
      // If we get an error, assume app is not installed
      return false;
    }
  }

  /**
   * Send sync list to PlexRunner watch app
   * @param deviceId Device to send to
   * @param ratingKeys Array of Plex audiobook ratingKeys
   */
  async sendSyncList(
    deviceId: string,
    ratingKeys: string[]
  ): Promise<void> {
    this.ensureInitialized();

    if (ratingKeys.length === 0) {
      throw new Error('No audiobooks selected');
    }

    const message = {
      type: 'syncList',
      data: ratingKeys,
    };

    try {
      // Note: sendMessage doesn't need deviceId - it sends to the currently set device
      const result = await ConnectIQ.sendMessage(message, PLEXRUNNER_APP_ID);
      console.log('Message sent successfully:', result);
    } catch (error) {
      throw new Error(
        `Failed to send message to watch: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Get status of Garmin Connect IQ SDK
   * @returns SDK status info
   */
  async getSDKStatus(): Promise<{
    initialized: boolean;
    hasConnectedDevices: boolean;
    deviceCount: number;
  }> {
    const devices = this.initialized ? await this.getConnectedDevices() : [];

    return {
      initialized: this.initialized,
      hasConnectedDevices: devices.length > 0,
      deviceCount: devices.length,
    };
  }

  /**
   * Ensure SDK is initialized before operations
   * @throws Error if SDK not initialized
   */
  private ensureInitialized(): void {
    if (!this.initialized) {
      throw new Error(
        'Garmin SDK not initialized. Call initialize() first.'
      );
    }
  }
}

// Export singleton instance
export const garminService = new GarminService();
