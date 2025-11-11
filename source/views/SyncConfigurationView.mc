using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Application;

// ABOUTME: SyncConfigurationView shows sync status and last sync time
// ABOUTME: Displayed in Music Player settings for PlexRunner

class SyncConfigurationView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Simple text-based layout
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.drawText(
            dc.getWidth() / 2,
            40,
            Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.SyncConfigTitle) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Last sync time
        var lastSync = Application.Storage.getValue("last_sync_time");
        var lastSyncText = WatchUi.loadResource(Rez.Strings.NeverSynced) as Lang.String;

        if (lastSync != null) {
            // TODO: Format timestamp
            lastSyncText = lastSync.toString();
        }

        dc.drawText(
            dc.getWidth() / 2,
            120,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.LastSync) as Lang.String + " " + lastSyncText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Server status
        var serverUrl = Application.Properties.getValue("serverUrl");
        var statusText = serverUrl != null ? "Configured" : "Not Configured";

        dc.drawText(
            dc.getWidth() / 2,
            180,
            Graphics.FONT_TINY,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }
}
