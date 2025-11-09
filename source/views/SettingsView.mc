using Toybox.WatchUi;
using Toybox.Graphics;

// ABOUTME: Settings view for Plex server configuration
// ABOUTME: Displays server URL, auth status, and configuration options

class SettingsView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");
        buildMenu();
    }

    function buildMenu() {
        // Show authentication status
        var authStatus = PlexConfig.isAuthenticated() ? "Connected" : "Not Connected";
        Menu2.addItem(new WatchUi.MenuItem(
            "Plex Status",
            authStatus,
            :status,
            {}
        ));

        // Show server URL
        var serverUrl = PlexConfig.getServerUrl();
        Menu2.addItem(new WatchUi.MenuItem(
            "Server",
            serverUrl,
            :server,
            {}
        ));

        // Authenticate option
        Menu2.addItem(new WatchUi.MenuItem(
            "Authenticate",
            null,
            :authenticate,
            {}
        ));

        // Clear data option
        Menu2.addItem(new WatchUi.MenuItem(
            "Clear Data",
            null,
            :clearData,
            {}
        ));
    }
}
