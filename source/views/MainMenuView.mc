using Toybox.WatchUi;
using Toybox.Graphics;

// ABOUTME: Main menu view displaying primary navigation options
// ABOUTME: Shows Continue Reading, Collections, All Audiobooks, Downloaded, Sync

class MainMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("PlexRunner");
    }

    function onShow() {
        buildMenu();
    }

    function buildMenu() {
        // Add menu items
        Menu2.addItem(new WatchUi.MenuItem(
            "Continue Reading",
            null,
            :continueReading,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "All Audiobooks",
            null,
            :allAudiobooks,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Downloaded",
            null,
            :downloaded,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Sync Now",
            null,
            :syncNow,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Settings",
            null,
            :settings,
            {}
        ));
    }
}
