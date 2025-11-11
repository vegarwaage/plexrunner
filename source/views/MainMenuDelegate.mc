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
            var downloadedView = new DownloadedView();
            WatchUi.pushView(downloadedView, new DownloadedDelegate(downloadedView), WatchUi.SLIDE_LEFT);
        } else if (id == :syncNow) {
            System.println("Sync Now selected");
            handleSyncNow();
        } else if (id == :settings) {
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() {
        // Exit app when back pressed from main menu
        System.exit();
    }

    // Handle Sync Now - show download queue and start downloads
    function handleSyncNow() {
        System.println("Initiating sync process");

        // Initialize DownloadManager
        DownloadManager.initialize();

        // Get queue to check if we have anything to sync
        var queue = DownloadManager.getDownloadQueue();
        var isDownloading = DownloadManager.isDownloading();

        System.println("Queue size: " + queue.size() + ", Is downloading: " + isDownloading);

        // Push download queue view
        var downloadQueueView = new DownloadQueueView();
        WatchUi.pushView(downloadQueueView, new DownloadQueueDelegate(downloadQueueView), WatchUi.SLIDE_LEFT);

        // Auto-start download if queue has items and not already downloading
        if (!isDownloading && queue.size() > 0) {
            System.println("Auto-starting download from sync");

            // Start download with callbacks
            DownloadManager.startDownload(
                method(:onSyncProgress),
                method(:onSyncComplete),
                method(:onSyncError)
            );
        } else if (isDownloading) {
            System.println("Download already in progress");
        } else {
            System.println("Queue is empty - nothing to sync");
        }
    }

    // Sync progress callback
    function onSyncProgress(bookKey, currentPart, totalParts, bytesDownloaded) {
        System.println("Sync progress: " + bookKey + " - Part " + currentPart + "/" + totalParts);
    }

    // Sync complete callback
    function onSyncComplete(bookKey, success) {
        System.println("Sync complete: " + bookKey + " - Success: " + success);
    }

    // Sync error callback
    function onSyncError(bookKey, error) {
        System.println("Sync error: " + bookKey + " - " + error);
    }
}
