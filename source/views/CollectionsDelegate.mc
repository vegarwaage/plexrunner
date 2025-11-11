using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Collections input delegate handling collection selection
// ABOUTME: Shows items within selected collection using CollectionItemsView

class CollectionsDelegate extends WatchUi.Menu2InputDelegate {

    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :loading) {
            // Do nothing while loading
            return;
        } else if (id == :error) {
            // Do nothing on error item
            return;
        } else if (id == :retry) {
            // Retry fetching
            System.println("Retrying Collections fetch...");
            _view.onShow();
        } else if (id == :empty) {
            // Do nothing on empty state
            return;
        } else {
            // Selected a collection - show its items
            var collection = _view.getCollection(id);
            if (collection != null) {
                System.println("Selected collection: " + collection[:title]);
                System.println("Rating Key: " + collection[:ratingKey]);

                // Show collection items
                var collectionItemsView = new CollectionItemsView(collection[:ratingKey], collection[:title]);
                WatchUi.pushView(collectionItemsView, new CollectionItemsDelegate(collectionItemsView), WatchUi.SLIDE_LEFT);
            }
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
