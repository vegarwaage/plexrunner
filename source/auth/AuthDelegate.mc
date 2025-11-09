using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;
using Toybox.Lang;

// ABOUTME: Authentication delegate handling PIN auth flow
// ABOUTME: Manages polling for token after PIN entry

class AuthDelegate extends WatchUi.BehaviorDelegate {

    private var _view;
    private var _pinId;
    private var _pollTimer;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
        _pinId = null;
        _pollTimer = null;
    }

    // Start polling for token with given PIN ID
    function startPolling(pinId) {
        if (pinId == null) {
            System.println("Cannot start polling - PIN ID is null");
            return;
        }

        _pinId = pinId;

        System.println("Starting token polling for PIN ID: " + _pinId);

        if (_view != null) {
            _view.setStatus("Waiting for auth...");
        }

        // Start polling timer (every 5 seconds)
        _pollTimer = new Timer.Timer();
        _pollTimer.start(new Lang.Method(self, :checkForToken), 5000, true);
    }

    // Check if token is available
    function checkForToken() as Void {
        if (_pinId == null) {
            System.println("Cannot check token - PIN ID is null");
            return;
        }

        System.println("Polling for token...");

        PlexApi.checkPinStatus(
            _pinId,
            new Lang.Method(self, :onTokenSuccess),
            new Lang.Method(self, :onTokenError)
        );
    }

    // Handle successful token check
    function onTokenSuccess(responseCode as Lang.Number, data as Lang.Dictionary) as Void {
        if (data == null) {
            System.println("Token check data is null");
            return;
        }

        var authToken = data["authToken"];

        if (authToken != null && authToken.length() > 0) {
            System.println("Token received!");

            // Stop polling
            if (_pollTimer != null) {
                _pollTimer.stop();
                _pollTimer = null;
            }

            // Save token
            PlexConfig.setAuthToken(authToken);

            // Update view
            if (_view != null) {
                _view.setStatus("Authenticated!");
            }

            // Wait briefly to show success message, then return to settings
            var successTimer = new Timer.Timer();
            successTimer.start(new Lang.Method(self, :returnToSettings), 1500, false);

            System.println("Authentication complete");
        } else {
            System.println("Token not yet available, continuing to poll...");
        }
    }

    // Handle token check error
    function onTokenError(responseCode as Lang.Number, error as Lang.String) as Void {
        System.println("Token check failed: " + error);

        // Stop polling on fatal errors
        if (responseCode == 404) {
            System.println("PIN not found - stopping polling");
            if (_pollTimer != null) {
                _pollTimer.stop();
                _pollTimer = null;
            }

            if (_view != null) {
                _view.setStatus("PIN expired");
            }
        }
    }

    // Return to settings view
    function returnToSettings() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onSelect() {
        // Placeholder - polling starts automatically now
        System.println("Select pressed during auth");
        return true;
    }

    function onBack() {
        // Cancel authentication and return to settings
        System.println("Authentication cancelled");

        // Stop polling timer
        if (_pollTimer != null) {
            _pollTimer.stop();
            _pollTimer = null;
        }

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
