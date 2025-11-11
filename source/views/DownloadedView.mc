using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Downloaded audiobooks view displaying list of locally stored audiobooks
// ABOUTME: Shows downloaded books with play and delete options

class DownloadedView extends WatchUi.Menu2 {

    private var _downloadedBooks;
    private var _menuBuilt;

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Downloaded");
        _downloadedBooks = [];
        _menuBuilt = false;
    }

    function onShow() {
        if (!_menuBuilt) {
            loadDownloadedBooks();
            _menuBuilt = true;
        }
    }

    function loadDownloadedBooks() {
        System.println("Loading downloaded audiobooks");

        // Initialize DownloadManager if needed
        DownloadManager.initialize();

        // Get downloaded books from DownloadManager
        _downloadedBooks = DownloadManager.getDownloadedAudiobooks();

        System.println("Found " + _downloadedBooks.size() + " downloaded books");

        buildMenu();
    }

    function buildMenu() {

        if (_downloadedBooks.size() == 0) {
            // Show empty state
            Menu2.addItem(new WatchUi.MenuItem(
                "No downloads",
                "Download from library",
                :empty,
                {}
            ));
        } else {
            // Add each downloaded book
            for (var i = 0; i < _downloadedBooks.size(); i++) {
                var book = _downloadedBooks[i];
                var title = book["title"];
                var author = book["author"];

                if (title == null) {
                    title = "Unknown";
                }
                if (author == null) {
                    author = "Unknown Author";
                }

                // Truncate for display
                if (title.length() > 18) {
                    title = title.substring(0, 15) + "...";
                }
                if (author.length() > 18) {
                    author = author.substring(0, 15) + "...";
                }

                Menu2.addItem(new WatchUi.MenuItem(
                    title,
                    author,
                    i,
                    {}
                ));
            }
        }
    }

    function getDownloadedBooks() {
        return _downloadedBooks;
    }
}
