using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Audiobook list delegate handling audiobook selection
// ABOUTME: Routes to detail view for selected audiobook or retries loading

class AudiobookListDelegate extends WatchUi.Menu2InputDelegate {

    private var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :loading) {
            // Do nothing while loading
            System.println("Still loading...");
        } else if (id == :error || id == :empty) {
            // Do nothing for error/empty state items
            System.println("Error or empty state");
        } else if (id == :retry) {
            // Retry fetching audiobooks
            System.println("Retrying fetch...");
            _view.fetchAudiobooks();
        } else if (id instanceof Lang.Number) {
            // Selected an audiobook
            var audiobook = _view.getAudiobook(id);
            if (audiobook != null) {
                System.println("Selected audiobook: " + audiobook[:title] + " by " + audiobook[:author]);
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
