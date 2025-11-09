using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Authentication delegate handling PIN auth flow
// ABOUTME: Manages user interactions during authentication process

class AuthDelegate extends WatchUi.BehaviorDelegate {

    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() {
        // Placeholder for future token polling trigger
        System.println("Select pressed - will check auth status");
        if (_view != null) {
            _view.setStatus("Checking...");
        }
        return true;
    }

    function onBack() {
        // Cancel authentication and return to settings
        System.println("Authentication cancelled");
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
