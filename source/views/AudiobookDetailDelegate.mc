using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Audiobook detail delegate handling menu actions
// ABOUTME: Provides download, delete, play, and back options

class AudiobookDetailDelegate extends WatchUi.BehaviorDelegate {

    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onMenu() {
        var metadata = _view.getDetailedMetadata();
        if (metadata == null) {
            // Metadata not loaded yet
            return true;
        }

        var downloaded = metadata[:downloaded];
        var menu = new WatchUi.Menu2({:title => "Options"});

        // Add menu items based on download status
        if (downloaded) {
            // Already downloaded - show delete and play
            menu.addItem(new WatchUi.MenuItem(
                "Play",
                null,
                :play,
                {}
            ));
            menu.addItem(new WatchUi.MenuItem(
                "Delete",
                null,
                :delete,
                {}
            ));
        } else {
            // Not downloaded - show download option
            menu.addItem(new WatchUi.MenuItem(
                "Download",
                null,
                :download,
                {}
            ));
        }

        menu.addItem(new WatchUi.MenuItem(
            "Back",
            null,
            :back,
            {}
        ));

        WatchUi.pushView(menu, new AudiobookDetailMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

// ABOUTME: Menu delegate for audiobook detail options menu
// ABOUTME: Handles download, delete, play actions (placeholders for now)

class AudiobookDetailMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();
        var audiobook = _view.getAudiobook();
        var metadata = _view.getDetailedMetadata();

        if (id == :download) {
            System.println("Download selected for: " + audiobook[:title]);
            // TODO: Implement download workflow (Task 11)
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :delete) {
            System.println("Delete selected for: " + audiobook[:title]);
            // TODO: Implement delete workflow
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :play) {
            System.println("Play selected for: " + audiobook[:title]);
            // TODO: Implement play workflow (integrate with media player)
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
