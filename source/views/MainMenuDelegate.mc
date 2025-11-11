using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Main menu input delegate handling menu item selection
// ABOUTME: Routes to appropriate view based on user selection

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :continueReading) {
            System.println("Continue Reading selected");
            var continueReadingView = new ContinueReadingView();
            WatchUi.pushView(continueReadingView, new ContinueReadingDelegate(continueReadingView), WatchUi.SLIDE_LEFT);
        } else if (id == :collections) {
            System.println("Collections selected");
            var collectionsView = new CollectionsView();
            WatchUi.pushView(collectionsView, new CollectionsDelegate(collectionsView), WatchUi.SLIDE_LEFT);
        } else if (id == :allAudiobooks) {
            System.println("All Audiobooks selected");
            var audiobookListView = new AudiobookListView();
            WatchUi.pushView(audiobookListView, new AudiobookListDelegate(audiobookListView), WatchUi.SLIDE_LEFT);
        } else if (id == :downloaded) {
            System.println("Downloaded selected");
            // TODO: Show downloaded audiobooks view
        } else if (id == :syncNow) {
            System.println("Sync Now selected");
            // TODO: Start sync process
        } else if (id == :settings) {
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() {
        // Exit app when back pressed from main menu
        System.exit();
    }
}
