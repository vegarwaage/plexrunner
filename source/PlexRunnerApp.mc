using Toybox.Application;
using Toybox.WatchUi;

// ABOUTME: PlexRunner main application entry point and lifecycle management
// ABOUTME: Initializes audio content provider and handles app state

class PlexRunnerApp extends Application.AudioContentProviderApp {

    function initialize() {
        AudioContentProviderApp.initialize();
    }

    function onStart(state) {
        AudioContentProviderApp.onStart(state);
    }

    function onStop(state) {
        AudioContentProviderApp.onStop(state);
    }

    function getInitialView() {
        return [new MainMenuView(), new MainMenuDelegate()];
    }
}
