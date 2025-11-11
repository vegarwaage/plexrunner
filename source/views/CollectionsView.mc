using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Collections view displaying available Plex Collections for audiobooks
// ABOUTME: Fetches and displays collections from the Music library for browsing

class CollectionsView extends WatchUi.Menu2 {

    private var _loading;
    private var _error;
    private var _collections;
    private var _musicSectionId;

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Collections");
        _loading = true;
        _error = null;
        _collections = [];
        _musicSectionId = null;

        // Show initial loading state
        Menu2.addItem(new WatchUi.MenuItem(
            "Loading...",
            null,
            :loading,
            {}
        ));
    }

    function onShow() {
        fetchCollections();
    }

    function fetchCollections() {
        System.println("Fetching Collections from Plex...");

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
        _musicSectionId = findMusicLibrary(data);
        if (_musicSectionId == null) {
            _loading = false;
            _error = "No Music library";
            refreshView();
            return;
        }

        System.println("Found Music library: " + _musicSectionId);

        // Fetch collections from Music library
        var path = "/library/sections/" + _musicSectionId + "/collections";
        PlexApi.makeAuthenticatedRequest(
            path,
            method(:onCollectionsSuccess),
            method(:onCollectionsError)
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

    function onCollectionsSuccess(responseCode, data) {
        System.println("Collections response received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onCollectionsError(responseCode, "Invalid response format");
            return;
        }

        _collections = parseCollections(data);
        _loading = false;
        _error = null;

        System.println("Parsed " + _collections.size() + " collections");
        refreshView();
    }

    function onCollectionsError(responseCode, error) {
        System.println("Failed to fetch collections: " + error);
        _loading = false;
        _error = "Load failed";
        refreshView();
    }

    function parseCollections(data) {
        var collections = [];

        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return collections;
        }

        var metadata = mediaContainer.get("Metadata");
        if (metadata == null || !(metadata instanceof Lang.Dictionary)) {
            return collections;
        }

        // Iterate through collections
        for (var i = 0; i < metadata.size(); i++) {
            var collection = metadata.get(i);
            if (collection != null && collection instanceof Lang.Dictionary) {
                var title = collection.get("title");
                var ratingKey = collection.get("ratingKey");
                var childCount = collection.get("childCount");

                if (title != null && ratingKey != null) {
                    var subtitle = null;
                    if (childCount != null) {
                        subtitle = childCount.toString() + " items";
                    }

                    collections.add({
                        :title => title.toString(),
                        :subtitle => subtitle,
                        :ratingKey => ratingKey.toString()
                    });
                }
            }
        }

        return collections;
    }

    function refreshView() {
        // Replace current view with updated content
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var newView = new CollectionsView();
        newView.setData(_collections, _loading, _error);
        WatchUi.pushView(newView, new CollectionsDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
    }

    function setData(collections, loading, error) {
        _collections = collections;
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
        } else if (_collections.size() == 0) {
            Menu2.addItem(new WatchUi.MenuItem(
                "No collections",
                "Create some in Plex",
                :empty,
                {}
            ));
        } else {
            // Add collection items
            for (var i = 0; i < _collections.size(); i++) {
                var collection = _collections[i];
                Menu2.addItem(new WatchUi.MenuItem(
                    collection[:title],
                    collection[:subtitle],
                    i,
                    {}
                ));
            }
        }
    }

    function getCollection(index) {
        if (index >= 0 && index < _collections.size()) {
            return _collections[index];
        }
        return null;
    }
}
