using Toybox.Application;
using Toybox.Lang;
using Toybox.Media;
using Toybox.System;
using PositionTracker;

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

        // Track position for Plex sync
        if (songEvent == Media.SONG_EVENT_START) {
            // TODO: Extract ratingKey from refId and start tracking
            System.println("Chapter started");
        } else if (songEvent == Media.SONG_EVENT_COMPLETE) {
            // TODO: Update position tracker
            System.println("Chapter completed");
        } else if (songEvent == Media.SONG_EVENT_PAUSE) {
            // TODO: Save current position
            System.println("Playback paused");
        }
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
