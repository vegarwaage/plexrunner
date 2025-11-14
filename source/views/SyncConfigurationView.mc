using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Application;

// ABOUTME: SyncConfigurationView shows sync status and test sync button
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
            30,
            Graphics.FONT_MEDIUM,
            "Test Sync",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Server status
        var serverUrl = Application.Properties.getValue("serverUrl");
        var statusText = serverUrl != null ? "Server: Connected" : "Server: Not Configured";

        dc.drawText(
            dc.getWidth() / 2,
            80,
            Graphics.FONT_TINY,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Test audiobook info
        dc.drawText(
            dc.getWidth() / 2,
            120,
            Graphics.FONT_SMALL,
            "Will sync:",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            dc.getWidth() / 2,
            150,
            Graphics.FONT_TINY,
            "Robot Novels",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Instructions
        dc.drawText(
            dc.getWidth() / 2,
            200,
            Graphics.FONT_XTINY,
            "Press SELECT to sync",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }
}
