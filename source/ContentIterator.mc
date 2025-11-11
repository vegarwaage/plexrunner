using Toybox.Application;
using Toybox.Lang;
using Toybox.Media;
using AudiobookStorage;

// ABOUTME: ContentIterator manages audiobook chapter navigation for native Music Player
// ABOUTME: Handles hierarchical structure (audiobooks -> chapters) and position tracking

class ContentIterator extends Media.ContentIterator {

    // Current audiobook index in catalog
    private var mAudiobookIndex;
    // Current chapter/track index within audiobook
    private var mChapterIndex;
    // All synced audiobooks
    private var mAudiobooks;
    // Chapters for current audiobook
    private var mCurrentChapters;

    function initialize() {
        ContentIterator.initialize();
        mAudiobookIndex = 0;
        mChapterIndex = 0;
        mAudiobooks = AudiobookStorage.getAudiobooks();

        if (mAudiobooks.size() > 0) {
            loadChaptersForCurrentAudiobook();
        } else {
            mCurrentChapters = [] as Lang.Array;
        }
    }

    // Get playback profile (controls available to user)
    function getPlaybackProfile() as Media.PlaybackProfile or Null {
        var profile = new Media.PlaybackProfile();

        profile.playbackControls = [
            Media.PLAYBACK_CONTROL_PLAYBACK,
            Media.PLAYBACK_CONTROL_PREVIOUS,
            Media.PLAYBACK_CONTROL_NEXT,
            Media.PLAYBACK_CONTROL_SKIP_FORWARD,
            Media.PLAYBACK_CONTROL_SKIP_BACKWARD
        ];

        profile.attemptSkipAfterThumbsDown = false;
        profile.requirePlaybackNotification = false;
        profile.skipPreviousThreshold = 4;

        return profile;
    }

    // Get current chapter
    function get() as Media.Content or Null {
        if (mCurrentChapters.size() == 0) {
            return null;
        }

        if (mChapterIndex >= 0 && mChapterIndex < mCurrentChapters.size()) {
            var chapter = mCurrentChapters[mChapterIndex] as Lang.Dictionary;
            var refId = chapter[:refId] as Lang.String;
            return Media.getCachedContentObj(new Media.ContentRef(refId, Media.CONTENT_TYPE_AUDIO));
        }

        return null;
    }

    // Advance to next chapter (or next audiobook if at end)
    function next() as Media.Content or Null {
        if (mCurrentChapters.size() == 0) {
            return null;
        }

        // Try next chapter in current audiobook
        if (mChapterIndex < (mCurrentChapters.size() - 1)) {
            mChapterIndex++;
            return get();
        }

        // Try next audiobook
        if (mAudiobookIndex < (mAudiobooks.size() - 1)) {
            mAudiobookIndex++;
            mChapterIndex = 0;
            loadChaptersForCurrentAudiobook();
            return get();
        }

        // No more content
        return null;
    }

    // Go to previous chapter (or previous audiobook if at beginning)
    function previous() as Media.Content or Null {
        if (mCurrentChapters.size() == 0) {
            return null;
        }

        // Try previous chapter in current audiobook
        if (mChapterIndex > 0) {
            mChapterIndex--;
            return get();
        }

        // Try previous audiobook (go to last chapter)
        if (mAudiobookIndex > 0) {
            mAudiobookIndex--;
            loadChaptersForCurrentAudiobook();
            mChapterIndex = mCurrentChapters.size() - 1;
            return get();
        }

        // No previous content
        return null;
    }

    // Peek at next chapter without advancing
    function peekNext() as Media.Content or Null {
        if (mCurrentChapters.size() == 0) {
            return null;
        }

        // Next chapter in current audiobook
        if (mChapterIndex < (mCurrentChapters.size() - 1)) {
            var chapter = mCurrentChapters[mChapterIndex + 1] as Lang.Dictionary;
            var refId = chapter[:refId] as Lang.String;
            return Media.getCachedContentObj(new Media.ContentRef(refId, Media.CONTENT_TYPE_AUDIO));
        }

        // First chapter of next audiobook
        if (mAudiobookIndex < (mAudiobooks.size() - 1)) {
            var nextAudiobook = mAudiobooks[mAudiobookIndex + 1] as Lang.Dictionary;
            var ratingKey = nextAudiobook[:ratingKey] as Lang.String;
            var tracks = AudiobookStorage.getTracks(ratingKey);
            if (tracks.size() > 0) {
                var chapter = tracks[0] as Lang.Dictionary;
                var refId = chapter[:refId] as Lang.String;
                return Media.getCachedContentObj(new Media.ContentRef(refId, Media.CONTENT_TYPE_AUDIO));
            }
        }

        return null;
    }

    // Peek at previous chapter without going back
    function peekPrevious() as Media.Content or Null {
        if (mCurrentChapters.size() == 0) {
            return null;
        }

        // Previous chapter in current audiobook
        if (mChapterIndex > 0) {
            var chapter = mCurrentChapters[mChapterIndex - 1] as Lang.Dictionary;
            var refId = chapter[:refId] as Lang.String;
            return Media.getCachedContentObj(new Media.ContentRef(refId, Media.CONTENT_TYPE_AUDIO));
        }

        // Last chapter of previous audiobook
        if (mAudiobookIndex > 0) {
            var prevAudiobook = mAudiobooks[mAudiobookIndex - 1] as Lang.Dictionary;
            var ratingKey = prevAudiobook[:ratingKey] as Lang.String;
            var tracks = AudiobookStorage.getTracks(ratingKey);
            if (tracks.size() > 0) {
                var chapter = tracks[tracks.size() - 1] as Lang.Dictionary;
                var refId = chapter[:refId] as Lang.String;
                return Media.getCachedContentObj(new Media.ContentRef(refId, Media.CONTENT_TYPE_AUDIO));
            }
        }

        return null;
    }

    // Can current chapter be skipped (always true for audiobooks)
    function canSkip() as Lang.Boolean {
        return true;
    }

    // Load chapters for current audiobook
    private function loadChaptersForCurrentAudiobook() as Void {
        if (mAudiobookIndex >= 0 && mAudiobookIndex < mAudiobooks.size()) {
            var audiobook = mAudiobooks[mAudiobookIndex] as Lang.Dictionary;
            var ratingKey = audiobook[:ratingKey] as Lang.String;
            mCurrentChapters = AudiobookStorage.getTracks(ratingKey);
        } else {
            mCurrentChapters = [] as Lang.Array;
        }
    }
}
