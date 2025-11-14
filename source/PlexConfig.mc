using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

// ABOUTME: PlexRunner configuration management reading from Garmin Connect settings
// ABOUTME: Settings synced via Application.Properties from phone app

module PlexConfig {

    // Read from Application.Properties (synced from settings file)
    function getServerUrl() as Lang.String {
        var url = Application.Properties.getValue("serverUrl");
        if (url == null || !(url instanceof Lang.String) || (url as Lang.String).length() == 0) {
            // FALLBACK: Use plain HTTP to local server (simpler, works on watch)
            return "http://192.168.10.10:32400";
        }
        return url as Lang.String;
    }

    function getAuthToken() as Lang.String {
        var token = Application.Properties.getValue("authToken");
        if (token == null || !(token instanceof Lang.String) || (token as Lang.String).length() == 0) {
            // SIMULATOR FALLBACK: Use hardcoded test token for simulator testing
            return "MvPZ56aMdg5xygacn9vk";
        }
        return token as Lang.String;
    }

    function getLibraryName() as Lang.String {
        var name = Application.Properties.getValue("libraryName");
        if (name == null) {
            return "Music"; // Default library name
        }
        return name as Lang.String;
    }

    // Client ID stored in app storage (not user-configurable)
    function getClientId() as Lang.String {
        var clientId = Application.Storage.getValue("client_id");
        if (clientId == null) {
            // Generate new UUID-like client ID
            clientId = "plexrunner-" + System.getTimer().toString();
            Application.Storage.setValue("client_id", clientId);
        }
        return clientId as Lang.String;
    }

    function isAuthenticated() as Lang.Boolean {
        var url = getServerUrl();
        var token = getAuthToken();
        return url.length() > 0 && token.length() > 0;
    }
}
