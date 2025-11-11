using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Audiobook detail view displaying full metadata and download status
// ABOUTME: Fetches detailed audiobook info from Plex and shows title, author, year, duration, synopsis

class AudiobookDetailView extends WatchUi.View {

    private var _audiobook;
    private var _detailedMetadata;
    private var _loading;
    private var _error;

    function initialize(audiobook) {
        View.initialize();
        _audiobook = audiobook;
        _detailedMetadata = null;
        _loading = true;
        _error = null;
    }

    function onShow() {
        // Fetch full metadata from Plex
        fetchDetailedMetadata();
    }

    function fetchDetailedMetadata() {
        System.println("Fetching detailed metadata for: " + _audiobook[:title]);

        var path = "/library/metadata/" + _audiobook[:ratingKey];
        PlexApi.makeAuthenticatedRequest(
            path,
            method(:onMetadataSuccess),
            method(:onMetadataError)
        );
    }

    function onMetadataSuccess(responseCode, data) {
        System.println("Detailed metadata received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onMetadataError(responseCode, "Invalid response format");
            return;
        }

        _detailedMetadata = parseDetailedMetadata(data);
        _loading = false;
        _error = null;
        WatchUi.requestUpdate();
    }

    function onMetadataError(responseCode, error) {
        System.println("Failed to fetch detailed metadata: " + error);
        _loading = false;
        _error = error;
        WatchUi.requestUpdate();
    }

    function parseDetailedMetadata(data) {
        var metadata = {};

        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return metadata;
        }

        var metadataArray = mediaContainer.get("Metadata");
        if (metadataArray == null || !(metadataArray instanceof Lang.Dictionary)) {
            return metadata;
        }

        // Get first metadata item (should be the audiobook)
        var item = metadataArray.get(0);
        if (item == null || !(item instanceof Lang.Dictionary)) {
            return metadata;
        }

        // Extract metadata fields
        metadata[:title] = getStringValue(item, "title");
        metadata[:author] = getStringValue(item, "parentTitle");
        metadata[:year] = getStringValue(item, "year");
        metadata[:summary] = getStringValue(item, "summary");
        metadata[:duration] = getNumberValue(item, "duration");
        metadata[:ratingKey] = getStringValue(item, "ratingKey");

        // Check if downloaded using DownloadManager
        DownloadManager.initialize();
        var ratingKey = metadata[:ratingKey];
        metadata[:downloaded] = ratingKey != null ? DownloadManager.isDownloaded(ratingKey) : false;

        return metadata;
    }

    function getStringValue(dict, key) {
        var value = dict.get(key);
        if (value != null) {
            return value.toString();
        }
        return null;
    }

    function getNumberValue(dict, key) {
        var value = dict.get(key);
        if (value != null && value instanceof Lang.Number) {
            return value;
        }
        return null;
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

        if (_loading) {
            // Show loading state
            dc.drawText(
                width / 2,
                height / 2,
                Graphics.FONT_MEDIUM,
                "Loading...",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else if (_error != null) {
            // Show error state
            dc.drawText(
                width / 2,
                height / 2 - lineHeight,
                Graphics.FONT_MEDIUM,
                "Error",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            dc.drawText(
                width / 2,
                height / 2 + lineHeight,
                Graphics.FONT_SMALL,
                "Press MENU",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else if (_detailedMetadata != null) {
            // Show detailed metadata
            var title = _detailedMetadata[:title];
            var author = _detailedMetadata[:author];
            var year = _detailedMetadata[:year];
            var duration = _detailedMetadata[:duration];
            var downloaded = _detailedMetadata[:downloaded];

            // Title (bold/larger font)
            if (title != null) {
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_MEDIUM,
                    truncateString(title, 20),
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight;
            }

            // Author
            if (author != null) {
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_SMALL,
                    "by " + truncateString(author, 18),
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight - 5;
            }

            // Year
            if (year != null) {
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_TINY,
                    year,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight - 10;
            }

            // Duration
            if (duration != null) {
                var durationStr = formatDuration(duration);
                dc.drawText(
                    width / 2,
                    y,
                    Graphics.FONT_TINY,
                    durationStr,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                y += lineHeight - 5;
            }

            // Download status
            var statusText = downloaded ? "Downloaded" : "Not Downloaded";
            dc.drawText(
                width / 2,
                y,
                Graphics.FONT_SMALL,
                statusText,
                Graphics.TEXT_JUSTIFY_CENTER
            );
            y += lineHeight;

            // Menu hint
            dc.drawText(
                width / 2,
                height - 20,
                Graphics.FONT_TINY,
                "Press MENU for options",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function onHide() {
    }

    function truncateString(str, maxLength) {
        if (str.length() <= maxLength) {
            return str;
        }
        return str.substring(0, maxLength - 3) + "...";
    }

    function formatDuration(durationMs) {
        // Convert milliseconds to hours and minutes
        var totalSeconds = durationMs / 1000;
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;

        if (hours > 0) {
            return hours.format("%d") + "h " + minutes.format("%d") + "m";
        } else {
            return minutes.format("%d") + "m";
        }
    }

    function getDetailedMetadata() {
        return _detailedMetadata;
    }

    function getAudiobook() {
        return _audiobook;
    }
}
