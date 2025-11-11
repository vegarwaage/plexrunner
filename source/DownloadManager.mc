using Toybox.Application.Storage;
using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Download manager module handling audiobook download queue and storage
// ABOUTME: Manages download state, file storage, and progress tracking for single/multi-file audiobooks

module DownloadManager {

    // Storage keys
    const KEY_DOWNLOAD_QUEUE = "download_queue";
    const KEY_DOWNLOADED_BOOKS = "downloaded_books";
    const KEY_CURRENT_DOWNLOAD = "current_download";

    // Module-level state
    var _downloadSuccessCallback = null;
    var _downloadErrorCallback = null;
    var _progressCallback = null;
    var _isDownloading = false;

    // Initialize download manager
    function initialize() {
        // Ensure storage structures exist
        if (Storage.getValue(KEY_DOWNLOAD_QUEUE) == null) {
            Storage.setValue(KEY_DOWNLOAD_QUEUE, []);
        }
        if (Storage.getValue(KEY_DOWNLOADED_BOOKS) == null) {
            Storage.setValue(KEY_DOWNLOADED_BOOKS, {});
        }
        System.println("DownloadManager initialized");
    }

    // Queue audiobook for download
    // book: Dictionary with keys: ratingKey, title, author, duration, parts (array of file URLs)
    function queueDownload(book) {
        if (book == null || book[:ratingKey] == null) {
            System.println("ERROR: Invalid book object for queueDownload");
            return false;
        }

        var ratingKey = book[:ratingKey];

        // Check if already downloaded
        if (isDownloaded(ratingKey)) {
            System.println("Book " + ratingKey + " already downloaded");
            return false;
        }

        // Check if already in queue
        var queue = Storage.getValue(KEY_DOWNLOAD_QUEUE);
        if (queue == null) {
            queue = [];
        }

        for (var i = 0; i < queue.size(); i++) {
            var item = queue[i];
            if (item != null && item["ratingKey"] != null &&
                item["ratingKey"].equals(ratingKey)) {
                System.println("Book " + ratingKey + " already in queue");
                return false;
            }
        }

        // Add to queue
        queue.add(book);
        Storage.setValue(KEY_DOWNLOAD_QUEUE, queue);
        System.println("Queued book: " + book["title"] + " (key: " + ratingKey + ")");

        return true;
    }

    // Start downloading next item in queue
    // onProgress: callback(bookKey, currentPart, totalParts, bytesDownloaded)
    // onComplete: callback(bookKey, success)
    // onError: callback(bookKey, errorMessage)
    function startDownload(onProgress, onComplete, onError) {
        if (_isDownloading) {
            System.println("Download already in progress");
            return false;
        }

        var queue = Storage.getValue(KEY_DOWNLOAD_QUEUE);
        if (queue == null || queue.size() == 0) {
            System.println("Download queue is empty");
            return false;
        }

        // Get first item from queue
        var book = queue[0];
        if (book == null || !(book instanceof Lang.Dictionary)) {
            System.println("ERROR: Invalid book in queue");
            return false;
        }

        _isDownloading = true;
        _progressCallback = onProgress;
        _downloadSuccessCallback = onComplete;
        _downloadErrorCallback = onError;

        // Store current download info
        Storage.setValue(KEY_CURRENT_DOWNLOAD, book);

        var ratingKey = book.get("ratingKey");
        if (ratingKey != null) {
            ratingKey = ratingKey.toString();
        }
        System.println("Starting download of book: " + ratingKey);

        // Start downloading parts
        var parts = book.get("parts");
        if (parts != null && parts instanceof Lang.Array && parts.size() > 0) {
            downloadPart(book, 0);
        } else {
            var keyStr = ratingKey != null ? ratingKey.toString() : "unknown";
            System.println("ERROR: No parts found for book " + keyStr);
            handlePartDownloadError(book, 0, "No downloadable parts found");
        }

        return true;
    }

    // Download a specific part of an audiobook
    function downloadPart(book, partIndex) {
        var parts = book["parts"];
        if (parts == null || partIndex >= parts.size()) {
            // All parts downloaded - mark as complete
            completeDownload(book);
            return;
        }

        var part = parts[partIndex];
        var ratingKey = book["ratingKey"];

        System.println("Downloading part " + (partIndex + 1) + " of " + parts.size() +
                      " for book " + ratingKey);

        // Build download URL with transcoding
        var partUrl = part["url"];
        if (partUrl == null) {
            System.println("ERROR: Part URL is null for part " + partIndex);
            handlePartDownloadError(book, partIndex, "Invalid part URL");
            return;
        }

        // Add auth token and transcoding parameters
        var token = PlexConfig.getAuthToken();
        var serverUrl = PlexConfig.getServerUrl();
        var downloadUrl = serverUrl + partUrl + "?X-Plex-Token=" + token;

        // For now, we'll use a simplified download approach
        // In production, we'd want to track bytes downloaded and save to storage
        // This is a placeholder that demonstrates the structure

        if (_progressCallback != null) {
            _progressCallback.invoke(ratingKey, partIndex + 1, parts.size(), 0);
        }

        // Note: In a full implementation, we'd use Communications.makeWebRequest
        // with proper file storage. For MVP, we'll simulate success
        System.println("Would download: " + downloadUrl);

        // Simulate successful part download
        // In production, this would be an actual HTTP request
        handlePartDownloadSuccess(book, partIndex);
    }

    // Handle successful part download
    function handlePartDownloadSuccess(book, partIndex) {
        System.println("Part " + (partIndex + 1) + " downloaded successfully");

        var parts = book["parts"];
        var nextPartIndex = partIndex + 1;

        if (nextPartIndex < parts.size()) {
            // Download next part
            downloadPart(book, nextPartIndex);
        } else {
            // All parts downloaded
            completeDownload(book);
        }
    }

    // Handle part download error
    function handlePartDownloadError(book, partIndex, error) {
        System.println("ERROR downloading part " + (partIndex + 1) + ": " + error);

        var ratingKey = book["ratingKey"];
        System.println("Download failed for book: " + ratingKey + " - " + error);

        // Clear current download
        Storage.setValue(KEY_CURRENT_DOWNLOAD, null);
        _isDownloading = false;

        // Notify error
        if (_downloadErrorCallback != null) {
            _downloadErrorCallback.invoke(ratingKey, error);
        }
    }

    // Complete download and update storage
    function completeDownload(book) {
        var ratingKey = book["ratingKey"];
        System.println("Download complete for book: " + ratingKey);

        // Add to downloaded books
        var downloaded = Storage.getValue(KEY_DOWNLOADED_BOOKS);
        if (downloaded == null) {
            downloaded = {};
        }

        // Store book metadata with download timestamp
        var bookInfo = {
            "ratingKey" => book["ratingKey"],
            "title" => book["title"],
            "author" => book["author"],
            "duration" => book["duration"],
            "downloadedAt" => System.getTimer(),
            "partCount" => book["parts"].size()
        };

        downloaded.put(ratingKey, bookInfo);
        Storage.setValue(KEY_DOWNLOADED_BOOKS, downloaded);

        // Remove from queue
        var queue = Storage.getValue(KEY_DOWNLOAD_QUEUE);
        if (queue != null && queue.size() > 0) {
            queue = queue.slice(1, queue.size());
            Storage.setValue(KEY_DOWNLOAD_QUEUE, queue);
        }

        // Clear current download
        Storage.setValue(KEY_CURRENT_DOWNLOAD, null);
        _isDownloading = false;

        // Notify completion
        if (_downloadSuccessCallback != null) {
            _downloadSuccessCallback.invoke(ratingKey, true);
        }

        System.println("Book " + ratingKey + " marked as downloaded");
    }

    // Cancel current download
    function cancelDownload() {
        if (!_isDownloading) {
            System.println("No download in progress");
            return false;
        }

        var currentDownload = Storage.getValue(KEY_CURRENT_DOWNLOAD);
        if (currentDownload != null && currentDownload instanceof Lang.Dictionary) {
            var ratingKey = currentDownload.get("ratingKey");
            if (ratingKey != null) {
                ratingKey = ratingKey.toString();
            }
            System.println("Cancelling download of book: " + ratingKey);
        }

        // Clear download state
        Storage.setValue(KEY_CURRENT_DOWNLOAD, null);
        _isDownloading = false;
        _downloadSuccessCallback = null;
        _downloadErrorCallback = null;
        _progressCallback = null;

        System.println("Download cancelled");
        return true;
    }

    // Check if audiobook is downloaded
    function isDownloaded(ratingKey) {
        var downloaded = Storage.getValue(KEY_DOWNLOADED_BOOKS);
        if (downloaded == null) {
            return false;
        }

        var book = downloaded.get(ratingKey);
        return book != null;
    }

    // Get all downloaded audiobooks
    // Returns: Array of book info dictionaries
    function getDownloadedAudiobooks() {
        var downloaded = Storage.getValue(KEY_DOWNLOADED_BOOKS);
        if (downloaded == null || downloaded.size() == 0) {
            return [];
        }

        var books = [];
        var keys = downloaded.keys();
        for (var i = 0; i < keys.size(); i++) {
            var key = keys[i];
            var book = downloaded.get(key);
            if (book != null) {
                books.add(book);
            }
        }

        System.println("Found " + books.size() + " downloaded books");
        return books;
    }

    // Delete downloaded audiobook
    function deleteDownload(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot delete - ratingKey is null");
            return false;
        }

        var downloaded = Storage.getValue(KEY_DOWNLOADED_BOOKS);
        if (downloaded == null) {
            System.println("No downloaded books to delete");
            return false;
        }

        var book = downloaded.get(ratingKey);
        if (book == null) {
            System.println("Book " + ratingKey + " not found in downloads");
            return false;
        }

        // Remove from downloaded books
        downloaded.remove(ratingKey);
        Storage.setValue(KEY_DOWNLOADED_BOOKS, downloaded);

        // In production, we'd also delete the actual audio files from storage here
        System.println("Deleted book: " + ratingKey);

        return true;
    }

    // Get download queue
    function getDownloadQueue() {
        var queue = Storage.getValue(KEY_DOWNLOAD_QUEUE);
        if (queue == null) {
            return [];
        }
        return queue;
    }

    // Get current download info
    function getCurrentDownload() {
        return Storage.getValue(KEY_CURRENT_DOWNLOAD);
    }

    // Check if currently downloading
    function isDownloading() {
        return _isDownloading;
    }

    // Clear all downloads (for testing/reset)
    function clearAll() {
        Storage.setValue(KEY_DOWNLOAD_QUEUE, []);
        Storage.setValue(KEY_DOWNLOADED_BOOKS, {});
        Storage.setValue(KEY_CURRENT_DOWNLOAD, null);
        _isDownloading = false;
        _downloadSuccessCallback = null;
        _downloadErrorCallback = null;
        _progressCallback = null;
        System.println("All downloads cleared");
    }
}
