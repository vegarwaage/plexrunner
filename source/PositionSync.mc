using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Position sync module for syncing playback positions to Plex server
// ABOUTME: Uses Plex Timeline API to update server-side playback positions

module PositionSync {

    // Shared callback storage (module-level state)
    var _syncSuccessCallback = null;
    var _syncErrorCallback = null;

    // Sync single audiobook position to Plex server
    // ratingKey: Audiobook's rating key
    // positionMs: Current position in milliseconds
    // durationMs: Total duration in milliseconds
    // state: Playback state ("playing", "paused", or "stopped")
    // Callback signature: onSuccess(responseCode, data), onError(responseCode, error)
    function syncPosition(ratingKey, positionMs, durationMs, state, onSuccess, onError) {
        if (ratingKey == null || positionMs == null || durationMs == null || state == null) {
            System.println("ERROR: Cannot sync position - invalid parameters");
            if (onError != null) {
                onError.invoke(400, "Invalid parameters");
            }
            return;
        }

        var token = PlexConfig.getAuthToken();
        if (token == null) {
            System.println("ERROR: Cannot sync position - not authenticated");
            if (onError != null) {
                onError.invoke(401, "Not authenticated");
            }
            return;
        }

        _syncSuccessCallback = onSuccess;
        _syncErrorCallback = onError;

        // Build timeline URL with query parameters
        var url = PlexConfig.getServerUrl() + "/:/timeline";
        url += "?ratingKey=" + ratingKey;
        url += "&key=/library/metadata/" + ratingKey;
        url += "&state=" + state;
        url += "&time=" + positionMs;
        url += "&duration=" + durationMs;

        var headers = {
            "X-Plex-Token" => token,
            "X-Plex-Client-Identifier" => PlexConfig.getClientId(),
            "X-Plex-Product" => "PlexRunner",
            "X-Plex-Version" => "0.1.0",
            "X-Plex-Platform" => "Garmin",
            "X-Plex-Device" => "Forerunner 970",
            "Accept" => "application/json"
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        System.println("Syncing position for " + ratingKey + ": " + positionMs + "ms / " + durationMs + "ms (" + state + ")");

        Communications.makeWebRequest(
            url,
            null,
            options,
            new Lang.Method(PositionSync, :handleSyncResponse)
        );
    }

    // Handle position sync response
    function handleSyncResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        System.println("Position Sync Response Code: " + responseCode);

        if (responseCode == 200) {
            System.println("Position synced successfully");
            if (_syncSuccessCallback != null) {
                _syncSuccessCallback.invoke(responseCode, data);
            }
        } else {
            var error = "Failed to sync position. Response code: " + responseCode;
            System.println(error);
            if (_syncErrorCallback != null) {
                _syncErrorCallback.invoke(responseCode, error);
            }
        }
    }

    // Sync all tracked positions to Plex server
    // Uses "stopped" state for all positions since they're not actively playing
    // Returns number of positions queued for sync (async operation)
    function syncAllPositions() {
        var positions = PositionTracker.getAllPositions();
        if (positions == null || positions.size() == 0) {
            System.println("No positions to sync");
            return 0;
        }

        System.println("Syncing " + positions.size() + " positions to Plex server");

        var keys = positions.keys();
        var syncCount = 0;

        for (var i = 0; i < keys.size(); i++) {
            var ratingKey = keys[i];
            var positionData = positions.get(ratingKey) as Lang.Dictionary;

            if (positionData != null) {
                var position = positionData[:position];

                // Only sync if we have a valid position
                if (position != null && position > 0) {
                    // For completed items, mark as stopped at end
                    // For in-progress items, mark as stopped at current position
                    // We can't get duration from stored data, so we'll use a high value
                    // that will be corrected by actual playback later
                    var duration = 999999999; // Placeholder - will be corrected during playback

                    // Note: This is a fire-and-forget sync
                    // Proper error handling would require queuing and retrying
                    syncPosition(
                        ratingKey,
                        position,
                        duration,
                        "stopped",
                        null,
                        null
                    );
                    syncCount++;
                }
            }
        }

        System.println("Queued " + syncCount + " positions for sync");
        return syncCount;
    }

    // Sync position with duration from PositionTracker data
    // This version is useful when you only have ratingKey and the duration stored separately
    function syncPositionForBook(ratingKey, durationMs, state, onSuccess, onError) {
        if (ratingKey == null || durationMs == null || state == null) {
            System.println("ERROR: Cannot sync position - invalid parameters");
            if (onError != null) {
                onError.invoke(400, "Invalid parameters");
            }
            return;
        }

        var positionMs = PositionTracker.getPosition(ratingKey);
        if (positionMs == 0) {
            System.println("No position data found for " + ratingKey);
            if (onError != null) {
                onError.invoke(404, "No position data found");
            }
            return;
        }

        syncPosition(ratingKey, positionMs, durationMs, state, onSuccess, onError);
    }
}
