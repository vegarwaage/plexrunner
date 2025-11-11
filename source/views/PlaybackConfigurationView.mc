using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// ABOUTME: PlaybackConfigurationView shows current audiobook and playback position
// ABOUTME: Optional view displayed in Music Player for PlexRunner

class PlaybackConfigurationView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.PlaybackConfigTitle) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // TODO: Show current audiobook and position from PositionTracker
    }

    function onHide() as Void {
    }
}
