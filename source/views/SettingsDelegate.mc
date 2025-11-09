using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Settings menu input delegate
// ABOUTME: Handles authentication, server config, and data clearing

class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :status) {
            System.println("Status: " + (PlexConfig.isAuthenticated() ? "Authenticated" : "Not authenticated"));
        } else if (id == :server) {
            System.println("Server: " + PlexConfig.getServerUrl());
        } else if (id == :authenticate) {
            System.println("Starting authentication...");
            // TODO: Start PIN-based OAuth flow
        } else if (id == :clearData) {
            PlexConfig.clear();
            System.println("Data cleared");
            // Refresh menu to show updated status
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
