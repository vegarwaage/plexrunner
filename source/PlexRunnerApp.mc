using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Media;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;
using PlexConfig;
using PositionSync;

// ABOUTME: PlexRunner main application entry point for AudioContentProviderApp
// ABOUTME: Provides delegates and configuration views to Garmin's native Music Player

class PlexRunnerApp extends Application.AudioContentProviderApp {

    private var mPositionSyncTimer;

    function initialize() {
        AudioContentProviderApp.initialize();
        mPositionSyncTimer = null;
    }

    function onStart(state as Lang.Dictionary?) as Void {
        AudioContentProviderApp.onStart(state);

        // Register message listener for companion app
        Communications.registerForPhoneAppMessages(method(:onMessage));
        System.println("Registered for phone app messages");

        // Start periodic position sync (every 5 minutes)
        if (mPositionSyncTimer == null && PlexConfig.isAuthenticated()) {
            mPositionSyncTimer = new Timer.Timer();
            mPositionSyncTimer.start(method(:syncPositionsToPlexPeriodic), 300000, true); // 5 min
            System.println("Started periodic position sync timer");
        }

        // AUTO-SYNC FOR TESTING: Automatically trigger sync if there's a sync list
        var syncList = Application.Storage.getValue("syncList");
        if (syncList == null || !(syncList instanceof Lang.Array) || syncList.size() == 0) {
            // No sync list - create test list with Robot Novels
            System.println("AUTO-SYNC: No sync list found, creating test list with Robot Novels (9549)");
            syncList = ["9549"];
            Application.Storage.setValue("syncList", syncList);
        }

        System.println("AUTO-SYNC: Found " + syncList.size() + " audiobooks in sync list, triggering sync...");
        Communications.startSync2({:message => "Auto-syncing audiobooks..."});
    }

    // Handle messages from companion app
    function onMessage(msg as Communications.PhoneAppMessage) as Void {
        System.println("Received message from companion app");

        if (!(msg.data instanceof Lang.Dictionary)) {
            System.println("Error: Message data is not a Dictionary");
            return;
        }

        var payload = msg.data as Lang.Dictionary;

        // Check for syncList message type
        if (payload[:type] != null && payload[:type].equals("syncList")) {
            var syncList = payload[:data];

            if (syncList != null && syncList instanceof Lang.Array) {
                // Store syncList in Application.Properties for SyncDelegate
                Application.Properties.setValue("syncList", syncList);
                System.println("Stored syncList with " + syncList.size() + " audiobooks");

                // TODO: Could optionally trigger sync automatically here
                // For now, user will trigger sync manually from watch
            } else {
                System.println("Error: Invalid syncList data format");
            }
        } else {
            System.println("Error: Unknown message type: " + payload[:type]);
        }
    }

    function onStop(state as Lang.Dictionary?) as Void {
        // Stop position sync timer
        if (mPositionSyncTimer != null) {
            mPositionSyncTimer.stop();
            mPositionSyncTimer = null;
            System.println("Stopped position sync timer");
        }

        // Final sync before stopping
        syncPositionsToPlex();

        AudioContentProviderApp.onStop(state);
    }

    // Periodic position sync callback
    function syncPositionsToPlexPeriodic() as Void {
        syncPositionsToPlex();
    }

    // Sync all tracked positions to Plex
    private function syncPositionsToPlex() as Void {
        if (!PlexConfig.isAuthenticated()) {
            System.println("Skipping position sync - not authenticated");
            return;
        }

        System.println("Syncing positions to Plex...");
        PositionSync.syncAllPositions();
    }

    // Required: Return content delegate for catalog
    function getContentDelegate(args as Application.PersistableType) as Media.ContentDelegate {
        return new ContentDelegate();
    }

    // Required: Return sync delegate for downloads
    function getSyncDelegate() as Communications.SyncDelegate or Null {
        return new SyncDelegate();
    }

    // Required: Return playback configuration view
    function getPlaybackConfigurationView() {
        return [new PlaybackConfigurationView(), new PlaybackConfigurationDelegate()];
    }

    // Required: Return sync configuration view
    function getSyncConfigurationView() {
        return [new SyncConfigurationView(), new SyncConfigurationDelegate()];
    }

    // Optional: Return initial view when app is launched directly
    function getInitialView() {
        return [new SyncConfigurationView(), new SyncConfigurationDelegate()];
    }
}
