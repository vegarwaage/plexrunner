using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Downloaded audiobooks delegate handling selection and actions
// ABOUTME: Provides play and delete options for downloaded audiobooks

class DownloadedDelegate extends WatchUi.Menu2InputDelegate {

    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();

        // Check if empty state
        if (id == :empty) {
            // Go back to main menu
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }

        // Get the selected book
        var books = _view.getDownloadedBooks();

        // id should be a Number (the index)
        if (!(id instanceof Lang.Number)) {
            System.println("Invalid book ID type");
            return;
        }

        if (id < 0 || id >= books.size()) {
            System.println("Invalid book selection");
            return;
        }

        var book = books[id];
        System.println("Selected downloaded book: " + book["title"]);

        // Show options menu
        showOptionsMenu(book);
    }

    function showOptionsMenu(book) {
        var menu = new WatchUi.Menu2({:title => "Options"});

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

        menu.addItem(new WatchUi.MenuItem(
            "Back",
            null,
            :back,
            {}
        ));

        WatchUi.pushView(menu, new DownloadedOptionsDelegate(book, _view), WatchUi.SLIDE_UP);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// ABOUTME: Options menu delegate for downloaded audiobook actions
// ABOUTME: Handles play and delete operations on downloaded books

class DownloadedOptionsDelegate extends WatchUi.Menu2InputDelegate {

    private var _book;

    function initialize(book, parentView) {
        Menu2InputDelegate.initialize();
        _book = book;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :play) {
            handlePlay();
        } else if (id == :delete) {
            handleDelete();
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function handlePlay() {
        System.println("Play selected for: " + _book["title"]);
        // TODO: Implement playback integration with media player (Task 16-17)
        // For now, just show a message and close menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function handleDelete() {
        var ratingKey = _book["ratingKey"];
        System.println("Deleting downloaded book: " + _book["title"] + " (key: " + ratingKey + ")");

        var success = DownloadManager.deleteDownload(ratingKey);

        if (success) {
            System.println("Book deleted successfully");
            // Close options menu and downloaded list, then push fresh downloaded list
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var newView = new DownloadedView();
            WatchUi.pushView(newView, new DownloadedDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
        } else {
            System.println("Failed to delete book");
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
