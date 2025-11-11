using Toybox.Media;
using Toybox.Lang;

// ABOUTME: ContentDelegate provides audiobook catalog to Garmin's native Music Player
// ABOUTME: Returns playlists (audiobooks) and tracks (chapters) from local storage

class ContentDelegate extends Media.ContentDelegate {

    function initialize() {
        ContentDelegate.initialize();
    }

    // Return list of synced audiobooks as playlists
    function getPlaylists() as Lang.Array<Media.Playlist> {
        // TODO: Read from local storage, return audiobooks
        return [];
    }

    // Return chapters for selected audiobook
    function getPlaylistTracks(playlistId as Lang.String) as Lang.Array<Media.Track> {
        // TODO: Read metadata, return chapters
        return [];
    }

    // Called when user starts playback
    function onPlaybackRequested(contentKey as Lang.String) as Media.ContentRef or Null {
        // TODO: Return ContentRef for audio file
        return null;
    }

    // Called when track starts
    function onSongStarted(track as Media.Track) as Void {
        // TODO: Update PositionTracker
    }

    // Called when track finishes
    function onSongFinished(track as Media.Track) as Void {
        // TODO: Save position, advance to next
    }
}
