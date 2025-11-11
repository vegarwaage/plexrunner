using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Continue Reading view displaying Plex On Deck audiobooks (in-progress books)
// ABOUTME: Fetches On Deck items from Plex and displays them for quick access to resume listening

class ContinueReadingView extends WatchUi.Menu2 {

    private var _loading;
    private var _error;
    private var _audiobooks;

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Continue Reading");
        _loading = true;
        _error = null;
        _audiobooks = [];

        // Show initial loading state
        Menu2.addItem(new WatchUi.MenuItem(
            "Loading...",
            null,
            :loading,
            {}
        ));
    }

    function onShow() {
        fetchOnDeck();
    }

    function fetchOnDeck() {
        System.println("Fetching On Deck audiobooks from Plex...");

        // Fetch On Deck items from Plex
        PlexApi.makeAuthenticatedRequest(
            "/library/onDeck",
            method(:onOnDeckSuccess),
            method(:onOnDeckError)
        );
    }

    function onOnDeckSuccess(responseCode, data) {
        System.println("On Deck response received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onOnDeckError(responseCode, "Invalid response format");
            return;
        }

        _audiobooks = parseOnDeckItems(data);
        _loading = false;
        _error = null;

        System.println("Parsed " + _audiobooks.size() + " on deck items");
        refreshView();
    }

    function onOnDeckError(responseCode, error) {
        System.println("Failed to fetch On Deck: " + error);
        _loading = false;
        _error = "Load failed";
        refreshView();
    }

    function parseOnDeckItems(data) {
        var audiobooks = [];

        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        var metadata = mediaContainer.get("Metadata");
        if (metadata == null || !(metadata instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        // Iterate through On Deck items
        for (var i = 0; i < metadata.size(); i++) {
            var item = metadata.get(i);
            if (item != null && item instanceof Lang.Dictionary) {
                // Check if this is an audiobook (track type=10 or album type=9)
                var type = item.get("type");
                if (type != null && type instanceof Lang.String) {
                    var title = null;
                    var author = null;
                    var ratingKey = item.get("ratingKey");

                    if (type.equals("track")) {
                        // Track - show track title and grandparent (album) as author
                        title = item.get("title");
                        author = item.get("grandparentTitle");
                    } else if (type.equals("album")) {
                        // Album - show album title and parent (artist) as author
                        title = item.get("title");
                        author = item.get("parentTitle");
                    }

                    if (title != null && ratingKey != null) {
                        audiobooks.add({
                            :title => title.toString(),
                            :author => author != null ? author.toString() : "Unknown",
                            :ratingKey => ratingKey.toString()
                        });
                    }
                }
            }
        }

        return audiobooks;
    }

    function refreshView() {
        // Replace current view with updated content
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var newView = new ContinueReadingView();
        newView.setData(_audiobooks, _loading, _error);
        WatchUi.pushView(newView, new ContinueReadingDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
    }

    function setData(audiobooks, loading, error) {
        _audiobooks = audiobooks;
        _loading = loading;
        _error = error;

        // Build menu based on state
        if (_loading) {
            Menu2.addItem(new WatchUi.MenuItem(
                "Loading...",
                null,
                :loading,
                {}
            ));
        } else if (_error != null) {
            Menu2.addItem(new WatchUi.MenuItem(
                "Error",
                _error,
                :error,
                {}
            ));
            Menu2.addItem(new WatchUi.MenuItem(
                "Retry",
                null,
                :retry,
                {}
            ));
        } else if (_audiobooks.size() == 0) {
            Menu2.addItem(new WatchUi.MenuItem(
                "Nothing to resume",
                "Start listening first",
                :empty,
                {}
            ));
        } else {
            // Add on deck items
            for (var i = 0; i < _audiobooks.size(); i++) {
                var audiobook = _audiobooks[i];
                Menu2.addItem(new WatchUi.MenuItem(
                    audiobook[:title],
                    audiobook[:author],
                    i,
                    {}
                ));
            }
        }
    }

    function getAudiobook(index) {
        if (index >= 0 && index < _audiobooks.size()) {
            return _audiobooks[index];
        }
        return null;
    }
}
