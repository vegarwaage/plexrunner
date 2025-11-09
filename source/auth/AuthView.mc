using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Authentication view displaying PIN code for plex.tv/link
// ABOUTME: Shows instructions and PIN for user to enter on web browser

class AuthView extends WatchUi.View {

    private var _pin;
    private var _status;

    function initialize() {
        View.initialize();
        _pin = "Loading...";
        _status = "Visit plex.tv/link";
    }

    function setPin(pin) {
        _pin = pin;
        WatchUi.requestUpdate();
    }

    function setStatus(status) {
        _status = status;
        WatchUi.requestUpdate();
    }

    function onLayout(dc) {
        // No layout file needed - custom drawing
    }

    function onShow() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();

        // Title - Visit plex.tv/link
        dc.drawText(
            width / 2,
            height / 4,
            Graphics.FONT_SMALL,
            "Visit plex.tv/link",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // PIN code (large and prominent)
        dc.drawText(
            width / 2,
            height / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            _pin != null ? _pin : "----",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Status message
        dc.drawText(
            width / 2,
            height * 3 / 4,
            Graphics.FONT_SMALL,
            _status != null ? _status : "",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() {
    }
}
