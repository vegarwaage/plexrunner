using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Communications;
using Toybox.Application;

// ABOUTME: Delegate for SyncConfigurationView handling user input
// ABOUTME: Triggers test sync when SELECT button is pressed

class SyncConfigurationDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        // Hardcode test audiobook for quick sync test
        // "The Complete Robot Novels" - ratingKey: 9549
        var testAudiobooks = ["9549"];

        // Store in storage for SyncDelegate to read
        Application.Storage.setValue("syncList", testAudiobooks);

        // Trigger sync with custom message
        Communications.startSync2({
            :message => "Syncing Robot Novels..."
        });

        return true;
    }
}
