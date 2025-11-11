using Toybox.Application;
using Toybox.Lang;

// ABOUTME: AudiobookStorage manages locally synced audiobook metadata
// ABOUTME: Reads/writes audiobook catalog and track information

module AudiobookStorage {

    // Storage key for audiobook catalog
    const KEY_AUDIOBOOKS = "synced_audiobooks";

    // Get all synced audiobooks
    // Returns: Array of dictionaries with {:ratingKey, :title, :author, :duration, :tracks}
    function getAudiobooks() as Lang.Array {
        var audiobooks = Application.Storage.getValue(KEY_AUDIOBOOKS);
        if (audiobooks == null) {
            return [] as Lang.Array;
        }
        if (!(audiobooks instanceof Lang.Array)) {
            return [] as Lang.Array;
        }
        return audiobooks as Lang.Array;
    }

    // Get specific audiobook by ratingKey
    function getAudiobook(ratingKey as Lang.String) as Lang.Dictionary or Null {
        var audiobooks = getAudiobooks();
        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (book[:ratingKey].equals(ratingKey)) {
                return book;
            }
        }
        return null;
    }

    // Save audiobook metadata
    function saveAudiobook(metadata as Lang.Dictionary) as Void {
        var audiobooks = getAudiobooks();

        // Check if already exists, update or append
        var found = false;
        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (book[:ratingKey].equals(metadata[:ratingKey])) {
                audiobooks[i] = metadata;
                found = true;
                break;
            }
        }

        if (!found) {
            audiobooks.add(metadata);
        }

        Application.Storage.setValue(KEY_AUDIOBOOKS, audiobooks);
    }

    // Remove audiobook
    function removeAudiobook(ratingKey as Lang.String) as Void {
        var audiobooks = getAudiobooks();
        var filtered = [] as Lang.Array;

        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (!book[:ratingKey].equals(ratingKey)) {
                filtered.add(book);
            }
        }

        Application.Storage.setValue(KEY_AUDIOBOOKS, filtered);
    }

    // Get tracks for audiobook
    function getTracks(ratingKey as Lang.String) as Lang.Array {
        var book = getAudiobook(ratingKey);
        if (book == null) {
            return [] as Lang.Array;
        }
        var tracks = book[:tracks];
        if (tracks == null || !(tracks instanceof Lang.Array)) {
            return [] as Lang.Array;
        }
        return tracks as Lang.Array;
    }
}
