using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Settings menu input delegate
// ABOUTME: Handles authentication, server config, and data clearing

class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    private var _currentAuthView;
    private var _currentAuthDelegate;

    function initialize() {
        Menu2InputDelegate.initialize();
        _currentAuthView = null;
        _currentAuthDelegate = null;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :status) {
            System.println("Status: " + (PlexConfig.isAuthenticated() ? "Authenticated" : "Not authenticated"));
        } else if (id == :server) {
            System.println("Server: " + PlexConfig.getServerUrl());
        } else if (id == :authenticate) {
            System.println("Requesting PIN from Plex...");

            // Create auth view and delegate
            _currentAuthView = new AuthView();
            _currentAuthDelegate = new AuthDelegate(_currentAuthView);
            WatchUi.pushView(_currentAuthView, _currentAuthDelegate, WatchUi.SLIDE_LEFT);

            // Request PIN from Plex
            PlexApi.requestPin(
                new Lang.Method(self, :onPinSuccess),
                new Lang.Method(self, :onPinError)
            );
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

    // Handle successful PIN request
    function onPinSuccess(responseCode as Lang.Number, data as Lang.Dictionary) as Void {
        System.println("PIN request successful");

        if (data != null && _currentAuthView != null && _currentAuthDelegate != null) {
            // Extract PIN and ID from response
            var pin = data["code"];
            var pinId = data["id"];

            if (pin != null && pinId != null) {
                System.println("PIN: " + pin + ", ID: " + pinId);

                // Update view with real PIN
                _currentAuthView.setPin(pin);

                // Start polling for token
                _currentAuthDelegate.startPolling(pinId);
            } else {
                System.println("PIN or ID is null in response");
                if (_currentAuthView != null) {
                    _currentAuthView.setStatus("Error: Invalid PIN data");
                }
            }
        }
    }

    // Handle PIN request error
    function onPinError(responseCode as Lang.Number, error as Lang.String) as Void {
        System.println("PIN request failed: " + error);

        if (_currentAuthView != null) {
            _currentAuthView.setStatus("Error: " + responseCode);
        }
    }
}
