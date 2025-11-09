using Toybox.Application.Storage;
using Toybox.System;

// ABOUTME: Persistent configuration storage for Plex credentials and settings
// ABOUTME: Manages auth tokens, server URL, and user preferences

module PlexConfig {

    const KEY_AUTH_TOKEN = "auth_token";
    const KEY_SERVER_URL = "server_url";
    const KEY_CLIENT_ID = "client_id";

    // Get authentication token
    function getAuthToken() {
        return Storage.getValue(KEY_AUTH_TOKEN);
    }

    // Set authentication token
    function setAuthToken(token) {
        Storage.setValue(KEY_AUTH_TOKEN, token);
    }

    // Get Plex server URL
    function getServerUrl() {
        var url = Storage.getValue(KEY_SERVER_URL);
        if (url == null) {
            return "http://localhost:32400";  // Default
        }
        return url;
    }

    // Set Plex server URL
    function setServerUrl(url) {
        Storage.setValue(KEY_SERVER_URL, url);
    }

    // Get client identifier (generate once)
    function getClientId() {
        var id = Storage.getValue(KEY_CLIENT_ID);
        if (id == null) {
            // Generate unique client ID
            id = generateClientId();
            Storage.setValue(KEY_CLIENT_ID, id);
        }
        return id;
    }

    // Generate unique client identifier
    function generateClientId() {
        var timestamp = System.getTimer();
        var deviceId = System.getDeviceSettings().uniqueIdentifier;
        return "plexrunner_" + deviceId + "_" + timestamp;
    }

    // Check if authenticated
    function isAuthenticated() {
        var token = getAuthToken();
        return token != null && token.length() > 0;
    }

    // Clear all stored data
    function clear() {
        Storage.deleteValue(KEY_AUTH_TOKEN);
        Storage.deleteValue(KEY_SERVER_URL);
        // Keep client ID - it should persist
    }
}
