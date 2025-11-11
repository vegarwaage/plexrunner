using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Download queue delegate handling queue management actions
// ABOUTME: Provides start, cancel, and clear queue operations

class DownloadQueueDelegate extends WatchUi.BehaviorDelegate {

    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onMenu() {
        var menu = new WatchUi.Menu2({:title => "Queue Options"});

        var isDownloading = _view.isDownloading();
        var queue = _view.getQueue();

        if (isDownloading) {
            // Show cancel option if download in progress
            menu.addItem(new WatchUi.MenuItem(
                "Cancel Download",
                null,
                :cancel,
                {}
            ));
        } else if (queue.size() > 0) {
            // Show start option if queue has items
            menu.addItem(new WatchUi.MenuItem(
                "Start Download",
                null,
                :start,
                {}
            ));
            menu.addItem(new WatchUi.MenuItem(
                "Clear Queue",
                null,
                :clear,
                {}
            ));
        }

        menu.addItem(new WatchUi.MenuItem(
            "Refresh",
            null,
            :refresh,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Back",
            null,
            :back,
            {}
        ));

        WatchUi.pushView(menu, new DownloadQueueMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

// ABOUTME: Menu delegate for download queue options
// ABOUTME: Handles start, cancel, clear, and refresh actions

class DownloadQueueMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :start) {
            handleStartDownload();
        } else if (id == :cancel) {
            handleCancelDownload();
        } else if (id == :clear) {
            handleClearQueue();
        } else if (id == :refresh) {
            handleRefresh();
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function handleStartDownload() {
        System.println("Starting download from queue");

        // Initialize DownloadManager
        DownloadManager.initialize();

        // Start download with callbacks
        var success = DownloadManager.startDownload(
            method(:onDownloadProgress),
            method(:onDownloadComplete),
            method(:onDownloadError)
        );

        if (success) {
            System.println("Download started successfully");
        } else {
            System.println("Failed to start download");
        }

        // Close menu and refresh view
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        refreshView();
    }

    function handleCancelDownload() {
        System.println("Cancelling current download");

        var success = DownloadManager.cancelDownload();

        if (success) {
            System.println("Download cancelled");
        } else {
            System.println("Failed to cancel download");
        }

        // Close menu and refresh view
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        refreshView();
    }

    function handleClearQueue() {
        System.println("Clearing download queue");

        // Clear all downloads (including queue)
        DownloadManager.clearAll();
        DownloadManager.initialize();

        System.println("Queue cleared");

        // Close menu and refresh view
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        refreshView();
    }

    function handleRefresh() {
        System.println("Refreshing queue view");

        // Close menu and refresh view
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        refreshView();
    }

    function refreshView() {
        // Pop current view and push fresh one
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var newView = new DownloadQueueView();
        WatchUi.pushView(newView, new DownloadQueueDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
    }

    // Download progress callback
    function onDownloadProgress(bookKey, currentPart, totalParts, bytesDownloaded) {
        System.println("Download progress: " + bookKey + " - Part " + currentPart + "/" + totalParts);
        // Could update view here if we want live progress
    }

    // Download complete callback
    function onDownloadComplete(bookKey, success) {
        System.println("Download complete: " + bookKey + " - Success: " + success);
        // Refresh view to show updated state
        refreshView();
    }

    // Download error callback
    function onDownloadError(bookKey, error) {
        System.println("Download error: " + bookKey + " - " + error);
        // Could show error message to user
        refreshView();
    }
}
