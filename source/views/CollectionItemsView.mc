using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Collection items view displaying audiobooks within a specific collection
// ABOUTME: Fetches and displays items from a Plex Collection by rating key

class CollectionItemsView extends WatchUi.Menu2 {

    private var _loading;
    private var _error;
    private var _audiobooks;
    private var _collectionKey;
    private var _collectionTitle;

    function initialize(collectionKey, collectionTitle) {
        Menu2.initialize(null);
        Menu2.setTitle(collectionTitle);
        _loading = true;
        _error = null;
        _audiobooks = [];
        _collectionKey = collectionKey;
        _collectionTitle = collectionTitle;

        // Show initial loading state
        Menu2.addItem(new WatchUi.MenuItem(
            "Loading...",
            null,
            :loading,
            {}
        ));
    }

    function onShow() {
        fetchCollectionItems();
    }

    function fetchCollectionItems() {
        System.println("Fetching items for collection: " + _collectionKey);

        // Fetch collection items
        var path = "/library/collections/" + _collectionKey + "/children";
        PlexApi.makeAuthenticatedRequest(
            path,
            method(:onItemsSuccess),
            method(:onItemsError)
        );
    }

    function onItemsSuccess(responseCode, data) {
        System.println("Collection items response received");

        if (data == null || !(data instanceof Lang.Dictionary)) {
            onItemsError(responseCode, "Invalid response format");
            return;
        }

        _audiobooks = parseCollectionItems(data);
        _loading = false;
        _error = null;

        System.println("Parsed " + _audiobooks.size() + " items");
        refreshView();
    }

    function onItemsError(responseCode, error) {
        System.println("Failed to fetch collection items: " + error);
        _loading = false;
        _error = "Load failed";
        refreshView();
    }

    function parseCollectionItems(data) {
        var audiobooks = [];

        var mediaContainer = data.get("MediaContainer");
        if (mediaContainer == null || !(mediaContainer instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        var metadata = mediaContainer.get("Metadata");
        if (metadata == null || !(metadata instanceof Lang.Dictionary)) {
            return audiobooks;
        }

        // Iterate through collection items (albums - type=9)
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
        var newView = new CollectionItemsView(_collectionKey, _collectionTitle);
        newView.setData(_audiobooks, _loading, _error);
        WatchUi.pushView(newView, new CollectionItemsDelegate(newView), WatchUi.SLIDE_IMMEDIATE);
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
                "Empty collection",
                "No items",
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
