using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Audiobook list view displaying available audiobooks from Plex Music library
// ABOUTME: Fetches albums from Plex and displays author (album artist) and title (album name)

class AudiobookListView extends WatchUi.Menu2 {

    private var _loading;
    private var _error;
    private var _audiobooks;

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Audiobooks");
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
        fetchAudiobooks();
    }

    function fetchAudiobooks() {
        System.println("Fetching audiobooks from Plex...");

        // First, get library sections to find Music library
        PlexApi.makeAuthenticatedRequest(
            "/library/sections",
            method(:onLibrarySectionsSuccess),
            method(:onLibrarySectionsError)
        );
    }

    function onLibrarySectionsSuccess(responseCode, data) {
        System.println("Library sections response received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onLibrarySectionsError(responseCode, "Invalid response format");
            return;
        }

        // Find Music library section
        var musicSectionId = findMusicLibrary(data);
        if (musicSectionId == null) {
            _loading = false;
            _error = "No Music library";
            refreshView();
            return;
        }

        System.println("Found Music library: " + musicSectionId);

        // Fetch audiobooks (albums) from Music library
        var path = "/library/sections/" + musicSectionId + "/all?type=9";
        PlexApi.makeAuthenticatedRequest(
            path,
            method(:onAudiobooksSuccess),
            method(:onAudiobooksError)
        );
    }

    function onLibrarySectionsError(responseCode, error) {
        System.println("Failed to fetch library sections: " + error);
        _loading = false;
        _error = "Connection failed";
        refreshView();
    }

    function findMusicLibrary(data) {
        // Plex returns MediaContainer with Directory array
        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return null;
        }

        var directories = mediaContainer.get("Directory");
        if (directories == null || !(directories instanceof Lang.Dictionary)) {
            return null;
        }

        // Iterate through directories to find music library
        for (var i = 0; i < directories.size(); i++) {
            var dir = directories.get(i);
            if (dir != null && dir instanceof Lang.Dictionary) {
                var type = dir.get("type");
                if (type != null && type instanceof Lang.String && type.equals("artist")) {
                    // This is the music library
                    var key = dir.get("key");
                    if (key != null) {
                        return key.toString();
                    }
                }
            }
        }

        return null;
    }

    function onAudiobooksSuccess(responseCode, data) {
        System.println("Audiobooks response received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onAudiobooksError(responseCode, "Invalid response format");
            return;
        }

        _audiobooks = parseAudiobooks(data);
        _loading = false;
        _error = null;

        System.println("Parsed " + _audiobooks.size() + " audiobooks");
        refreshView();
    }

    function onAudiobooksError(responseCode, error) {
        System.println("Failed to fetch audiobooks: " + error);
        _loading = false;
        _error = "Load failed";
        refreshView();
    }

    function parseAudiobooks(data) {
        var audiobooks = [];

        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        var metadata = mediaContainer.get("Metadata");
        if (metadata == null || !(metadata instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        // Iterate through albums (type=9)
        for (var i = 0; i < metadata.size(); i++) {
            var album = metadata.get(i);
            if (album != null && album instanceof Lang.Dictionary) {
                var title = album.get("title");
                var artist = album.get("parentTitle"); // Album artist
                var ratingKey = album.get("ratingKey");

                if (title != null && artist != null && ratingKey != null) {
                    audiobooks.add({
                        :title => title.toString(),
                        :author => artist.toString(),
                        :ratingKey => ratingKey.toString()
                    });
                }
            }
        }

        return audiobooks;
    }

    function refreshView() {
        // Replace current view with updated content
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var newView = new AudiobookListView();
        newView.setData(_audiobooks, _loading, _error);
        WatchUi.pushView(newView, new AudiobookListDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
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
                "No audiobooks",
                "Check library",
                :empty,
                {}
            ));
        } else {
            // Add audiobook items
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
