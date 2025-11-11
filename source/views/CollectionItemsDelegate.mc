using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Collection items input delegate handling audiobook selection within collection
// ABOUTME: Handles selection of audiobooks from collection items and retry functionality

class CollectionItemsDelegate extends WatchUi.Menu2InputDelegate {

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
            System.println("Retrying collection items fetch...");
            _view.onShow();
        } else if (id == :empty) {
            // Do nothing on empty state
            return;
        } else {
            // Selected an audiobook - get its data
            var audiobook = _view.getAudiobook(id);
            if (audiobook != null) {
                System.println("Selected audiobook: " + audiobook[:title]);
                System.println("Author: " + audiobook[:author]);
                System.println("Rating Key: " + audiobook[:ratingKey]);
                // Show audiobook detail view
                var detailView = new AudiobookDetailView(audiobook);
                WatchUi.pushView(detailView, new AudiobookDetailDelegate(detailView), WatchUi.SLIDE_LEFT);
            }
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
