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
            handleDownload(audiobook, metadata);
        } else if (id == :delete) {
            System.println("Delete selected for: " + audiobook[:title]);
            handleDelete(audiobook);
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

    function handleDownload(audiobook, metadata) {
        System.println("Queueing download for: " + audiobook[:title]);

        // Build book object for DownloadManager
        // DownloadManager expects: ratingKey, title, author, duration, parts (array of file URLs)
        var book = {
            :ratingKey => audiobook[:ratingKey],
            :title => audiobook[:title],
            :author => audiobook[:author],
            :duration => metadata != null ? metadata[:duration] : null,
            :parts => [] // Will be populated from metadata parts API in full implementation
        };

        // For MVP, we'll simulate with empty parts array
        // In production, this would fetch track URLs from /library/metadata/{ratingKey}
        // and populate the parts array with actual download URLs

        // Initialize DownloadManager
        DownloadManager.initialize();

        // Queue the download
        var success = DownloadManager.queueDownload(book);

        if (success) {
            System.println("Book queued for download: " + audiobook[:title]);
            // TODO: Show success message or navigate to download queue view
        } else {
            System.println("Failed to queue book (already queued or downloaded)");
            // TODO: Show appropriate message to user
        }

        // Close options menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);

        // Refresh detail view to show updated download status
        _view.onShow();
    }

    function handleDelete(audiobook) {
        var ratingKey = audiobook[:ratingKey];
        System.println("Deleting downloaded book: " + audiobook[:title] + " (key: " + ratingKey + ")");

        // Initialize DownloadManager
        DownloadManager.initialize();

        // Delete the download
        var success = DownloadManager.deleteDownload(ratingKey);

        if (success) {
            System.println("Book deleted successfully");
        } else {
            System.println("Failed to delete book");
        }

        // Close options menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);

        // Refresh detail view to show updated download status
        _view.onShow();
    }
}
