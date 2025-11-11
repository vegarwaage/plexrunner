using Toybox.WatchUi;
using Toybox.Lang;

// ABOUTME: Delegate for SyncConfigurationView handling user input
// ABOUTME: Currently no interactive elements, but required by Garmin

class SyncConfigurationDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        // No action on select
        return true;
    }
}
