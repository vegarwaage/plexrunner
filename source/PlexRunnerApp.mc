using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Media;
using Toybox.WatchUi;

// ABOUTME: PlexRunner main application entry point for AudioContentProviderApp
// ABOUTME: Provides delegates and configuration views to Garmin's native Music Player

class PlexRunnerApp extends Application.AudioContentProviderApp {

    function initialize() {
        AudioContentProviderApp.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        AudioContentProviderApp.onStart(state);
    }

    function onStop(state as Lang.Dictionary?) as Void {
        AudioContentProviderApp.onStop(state);
    }

    // Required: Return content delegate for catalog
    function getContentDelegate(args as Application.PersistableType) as Media.ContentDelegate {
        return new ContentDelegate();
    }

    // Required: Return sync delegate for downloads
    function getSyncDelegate() as Communications.SyncDelegate or Null {
        return new SyncDelegate();
    }

    // Note: getSyncConfigurationView and getPlaybackConfigurationView are optional
    // and not implemented yet - the base class provides default behavior
}
