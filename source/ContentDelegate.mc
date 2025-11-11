using Toybox.Application;
using Toybox.Lang;
using Toybox.Media;
using Toybox.System;
using PositionTracker;
using AudiobookStorage;

// ABOUTME: ContentDelegate handles media player interactions for audiobooks
// ABOUTME: Creates ContentIterator and responds to playback events

class ContentDelegate extends Media.ContentDelegate {

    // Iterator for playing audiobook chapters
    private var mIterator;

    // Song event names for logging
    private var mSongEvents = ["Start", "Skip Next", "Skip Previous", "Playback Notify", "Complete", "Stop", "Pause", "Resume"];

    function initialize() {
        ContentDelegate.initialize();
        resetContentIterator();
    }

    // Returns the iterator to navigate audiobook chapters
    function getContentIterator() as Media.ContentIterator or Null {
        return mIterator;
    }

    // Creates new iterator
    function resetContentIterator() as Media.ContentIterator or Null {
        mIterator = new ContentIterator();
        return mIterator;
    }

    // Called when song events occur (start, complete, skip, etc.)
    function onSong(refId as Lang.Object, songEvent as Media.SongEvent, playbackPosition as Lang.Number or Media.PlaybackPosition) as Void {
        System.println("Song Event (" + mSongEvents[songEvent] + "): " + refId.toString() + " at position " + playbackPosition);

        // Find which audiobook this chapter belongs to
        var audiobookInfo = findAudiobookForChapter(refId);
        if (audiobookInfo == null) {
            System.println("Warning: Could not find audiobook for chapter");
            return;
        }

        var ratingKey = audiobookInfo[:ratingKey] as Lang.String;
        var position = 0;
        if (playbackPosition instanceof Lang.Number) {
            position = playbackPosition as Lang.Number;
        }

        // Track position for Plex sync
        if (songEvent == Media.SONG_EVENT_START) {
            System.println("Chapter started for audiobook: " + ratingKey);
            PositionTracker.updatePosition(ratingKey, position);
        } else if (songEvent == Media.SONG_EVENT_COMPLETE) {
            System.println("Chapter completed");
            PositionTracker.updatePosition(ratingKey, position);
        } else if (songEvent == Media.SONG_EVENT_PAUSE) {
            System.println("Playback paused");
            PositionTracker.updatePosition(ratingKey, position);
        } else if (songEvent == Media.SONG_EVENT_STOP) {
            System.println("Playback stopped");
            PositionTracker.updatePosition(ratingKey, position);
        }
    }

    // Find which audiobook contains this chapter refId
    private function findAudiobookForChapter(refId as Lang.Object) as Lang.Dictionary or Null {
        var refIdString = refId.toString();
        var audiobooks = AudiobookStorage.getAudiobooks();

        for (var i = 0; i < audiobooks.size(); i++) {
            var audiobook = audiobooks[i] as Lang.Dictionary;
            var tracks = audiobook[:tracks];

            if (tracks != null && (tracks instanceof Lang.Array)) {
                for (var j = 0; j < tracks.size(); j++) {
                    var track = tracks[j] as Lang.Dictionary;
                    var trackRefId = track[:refId];
                    if (trackRefId != null && trackRefId.toString().equals(refIdString)) {
                        return {:ratingKey => audiobook[:ratingKey]};
                    }
                }
            }
        }

        return null;
    }

    // Since there's no good way to provide feedback, log thumbs up
    function onThumbsUp(refId as Lang.Object) as Void {
        System.println("Thumbs Up: " + refId.toString());
    }

    // Since there's no good way to provide feedback, log thumbs down
    function onThumbsDown(refId as Lang.Object) as Void {
        System.println("Thumbs Down: " + refId.toString());
    }
}
