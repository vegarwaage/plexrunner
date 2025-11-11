using Toybox.Application.Storage;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Position tracker module for tracking playback positions locally
// ABOUTME: Manages position storage, completion status, and timestamps for each audiobook

module PositionTracker {

    // Storage key for playback positions
    const KEY_PLAYBACK_POSITIONS = "playback_positions";

    // Update playback position for an audiobook
    // ratingKey: Unique identifier for the audiobook
    // positionMs: Current playback position in milliseconds
    function updatePosition(ratingKey, positionMs) {
        if (ratingKey == null || positionMs == null) {
            System.println("ERROR: Cannot update position - invalid parameters");
            return false;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            positions = {};
        }

        // Get existing position data or create new
        var positionData = positions.get(ratingKey) as Lang.Dictionary;
        if (positionData == null) {
            positionData = {
                :position => 0,
                :timestamp => 0,
                :completed => false
            };
        }

        // Update position and timestamp
        positionData[:position] = positionMs;
        positionData[:timestamp] = System.getTimer();

        // Store updated position data
        positions.put(ratingKey, positionData);
        Storage.setValue(KEY_PLAYBACK_POSITIONS, positions);

        System.println("Updated position for " + ratingKey + " to " + positionMs + "ms");
        return true;
    }

    // Get current playback position for an audiobook
    // Returns: Position in milliseconds, or 0 if not found
    function getPosition(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot get position - ratingKey is null");
            return 0;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            return 0;
        }

        var positionData = positions.get(ratingKey) as Lang.Dictionary;
        if (positionData == null) {
            return 0;
        }

        var position = positionData[:position];
        if (position == null) {
            return 0;
        }

        return position;
    }

    // Mark audiobook as completed
    function markCompleted(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot mark completed - ratingKey is null");
            return false;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            positions = {};
        }

        // Get existing position data or create new
        var positionData = positions.get(ratingKey) as Lang.Dictionary;
        if (positionData == null) {
            positionData = {
                :position => 0,
                :timestamp => 0,
                :completed => false
            };
        }

        // Mark as completed and update timestamp
        positionData[:completed] = true;
        positionData[:timestamp] = System.getTimer();

        // Store updated position data
        positions.put(ratingKey, positionData);
        Storage.setValue(KEY_PLAYBACK_POSITIONS, positions);

        System.println("Marked " + ratingKey + " as completed");
        return true;
    }

    // Check if audiobook is completed
    function isCompleted(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot check completion - ratingKey is null");
            return false;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            return false;
        }

        var positionData = positions.get(ratingKey) as Lang.Dictionary;
        if (positionData == null) {
            return false;
        }

        var completed = positionData[:completed];
        if (completed == null) {
            return false;
        }

        return completed;
    }

    // Get the most recently played audiobook
    // Returns: ratingKey of last played book, or null if none
    function getLastPlayed() {
        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null || positions.size() == 0) {
            return null;
        }

        var lastRatingKey = null;
        var lastTimestamp = 0;

        var keys = positions.keys();
        for (var i = 0; i < keys.size(); i++) {
            var key = keys[i];
            var positionData = positions.get(key) as Lang.Dictionary;
            if (positionData != null) {
                var timestamp = positionData[:timestamp];
                if (timestamp != null && timestamp > lastTimestamp) {
                    lastTimestamp = timestamp;
                    lastRatingKey = key;
                }
            }
        }

        if (lastRatingKey != null) {
            System.println("Last played book: " + lastRatingKey);
        }

        return lastRatingKey;
    }

    // Get all tracked positions
    // Returns: Dictionary of {ratingKey => {position, timestamp, completed}}
    function getAllPositions() {
        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            return {};
        }

        System.println("Retrieved " + positions.size() + " position entries");
        return positions;
    }

    // Clear all position data (for testing/reset)
    function clearAll() {
        Storage.setValue(KEY_PLAYBACK_POSITIONS, {});
        System.println("All position data cleared");
    }

    // Get position data for specific audiobook
    // Returns: Dictionary with position, timestamp, completed or null if not found
    function getPositionData(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot get position data - ratingKey is null");
            return null;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            return null;
        }

        return positions.get(ratingKey);
    }

    // Remove position data for specific audiobook
    function removePosition(ratingKey) {
        if (ratingKey == null) {
            System.println("ERROR: Cannot remove position - ratingKey is null");
            return false;
        }

        var positions = Storage.getValue(KEY_PLAYBACK_POSITIONS);
        if (positions == null) {
            System.println("No position data to remove");
            return false;
        }

        var positionData = positions.get(ratingKey);
        if (positionData == null) {
            System.println("Position data for " + ratingKey + " not found");
            return false;
        }

        // Remove position data
        positions.remove(ratingKey);
        Storage.setValue(KEY_PLAYBACK_POSITIONS, positions);

        System.println("Removed position data for " + ratingKey);
        return true;
    }
}
