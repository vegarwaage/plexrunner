using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Download queue view displaying queued downloads and progress
// ABOUTME: Shows current download status, progress, and queued books

class DownloadQueueView extends WatchUi.View {

    private var _queue;
    private var _currentDownload;
    private var _isDownloading;

    function initialize() {
        View.initialize();
        _queue = [];
        _currentDownload = null;
        _isDownloading = false;
    }

    function onShow() {
        loadQueueState();
        WatchUi.requestUpdate();
    }

    function loadQueueState() {
        System.println("Loading download queue state");

        // Initialize DownloadManager
        DownloadManager.initialize();

        // Get queue and current download info
        _queue = DownloadManager.getDownloadQueue();
        _currentDownload = DownloadManager.getCurrentDownload();
        _isDownloading = DownloadManager.isDownloading();

        System.println("Queue size: " + _queue.size());
        System.println("Is downloading: " + _isDownloading);
    }

    function onLayout(dc) {
        // No layout file needed
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var y = 10;
        var lineHeight = 30;

        // Title
        dc.drawText(
            width / 2,
            y,
            Graphics.FONT_MEDIUM,
            "Download Queue",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += lineHeight + 10;

        if (_isDownloading && _currentDownload != null) {
            // Show current download
            dc.drawText(
                width / 2,
                y,
                Graphics.FONT_SMALL,
                "Downloading:",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            y += lineHeight - 5;

            var title = _currentDownload.get("title");
            if (title != null) {
                title = truncateString(title.toString(), 20);
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_TINY,
                    title,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight - 5;
            }

            // Progress indicator (simplified - just show "In Progress")
            dc.drawText(
                width / 2,
                y,
                Graphics.FONT_TINY,
                "In Progress...",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            y += lineHeight;

        } else if (_queue.size() > 0) {
            // Show queue count
            dc.drawText(
                width / 2,
                y,
                Graphics.FONT_SMALL,
                _queue.size() + " book(s) queued",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            y += lineHeight;

            // Show first queued item
            var firstBook = _queue[0];
            if (firstBook != null) {
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_TINY,
                    "Next:",
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight - 5;

                var title = firstBook.get("title");
                if (title != null) {
                    title = truncateString(title.toString(), 20);
                    dc.drawText(
                        width / 2,
                        y,
                        Graphics.FONT_TINY,
                        title,
                        Graphics.TEXT_JUSTIFY_CENTER
                    );
                }
            }
        } else {
            // Empty queue
            dc.drawText(
                width / 2,
                height / 2,
                Graphics.FONT_MEDIUM,
                "Queue Empty",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            y = height / 2 + lineHeight;
            dc.drawText(
                width / 2,
                y,
                Graphics.FONT_TINY,
                "No downloads pending",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // Menu hint at bottom
        dc.drawText(
            width / 2,
            height - 20,
            Graphics.FONT_TINY,
            "MENU for options",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() {
    }

    function truncateString(str, maxLength) {
        if (str.length() <= maxLength) {
            return str;
        }
        return str.substring(0, maxLength - 3) + "...";
    }

    function getQueue() {
        return _queue;
    }

    function getCurrentDownload() {
        return _currentDownload;
    }

    function isDownloading() {
        return _isDownloading;
    }
}
