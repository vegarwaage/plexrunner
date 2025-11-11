# AudioContentProviderApp Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild PlexRunner as a proper AudioContentProviderApp that integrates with Garmin's native Music Player

**Architecture:** Clean-slate implementation starting from main branch. Copy reusable modules (PlexConfig, PlexApi, DownloadManager, PositionTracker, PositionSync) from audiobook-mvp worktree. Implement ContentDelegate for catalog, SyncDelegate for downloads, configuration views for settings.

**Tech Stack:** Monkey C, Connect IQ SDK 8.3.0, Garmin Forerunner 970 (API Level 5.2)

**Source for Reusable Modules:** `/Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/source/`

---

## Phase 1: Project Setup

### Task 1: Create Project Structure

**Files:**
- Create: `manifest.xml`
- Create: `monkey.jungle`
- Create: `resources/strings/strings.xml`
- Create: `resources/drawables/launcher_icon.png` (copy from audiobook-mvp)

**Step 1: Create manifest.xml**

```xml
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application entry="PlexRunnerApp" id="plexrunner-audio-provider" launcherIcon="@Drawables.LauncherIcon" minApiLevel="5.2.0" name="@Strings.AppName" type="audio-content-provider" version="0.1.0">
        <iq:products>
            <iq:product id="fr970"/>
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="Communications"/>
        </iq:permissions>
        <iq:languages>
            <iq:language>eng</iq:language>
        </iq:languages>
    </iq:application>
</iq:manifest>
```

Note the `type="audio-content-provider"` attribute - this is critical.

**Step 2: Create monkey.jungle**

```
project.manifest = manifest.xml
fr970.resourcePath = resources
fr970.sourcePath = source
```

**Step 3: Create resources/strings/strings.xml**

```xml
<resources>
    <strings>
        <string id="AppName">PlexRunner</string>
        <string id="SyncConfigTitle">Sync Status</string>
        <string id="PlaybackConfigTitle">Now Playing</string>
        <string id="NoAudiobooks">No audiobooks synced</string>
        <string id="Syncing">Syncing...</string>
        <string id="LastSync">Last sync:</string>
        <string id="NeverSynced">Never</string>
    </strings>
</resources>
```

**Step 4: Copy launcher icon**

Run:
```bash
mkdir -p resources/drawables
cp /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/resources/drawables/launcher_icon.png resources/drawables/
```

**Step 5: Create source directory**

```bash
mkdir -p source
```

**Step 6: Verify structure**

Run: `ls -R`
Expected:
```
manifest.xml
monkey.jungle
resources/
  strings/
    strings.xml
  drawables/
    launcher_icon.png
source/
```

**Step 7: Commit**

```bash
git add .
git commit -m "feat: initial project structure for AudioContentProviderApp

- manifest.xml with type=audio-content-provider
- monkey.jungle build config for fr970
- resource strings and launcher icon
- empty source directory ready for implementation"
```

---

### Task 2: Create PlexRunnerApp Entry Point

**Files:**
- Create: `source/PlexRunnerApp.mc`

**Step 1: Create PlexRunnerApp.mc**

```monkeyc
using Toybox.Application;
using Toybox.Media;

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
    function getContentDelegate() as Media.ContentDelegate {
        return null; // TODO: Implement ContentDelegate
    }

    // Required: Return sync delegate for downloads
    function getSyncDelegate() as Media.SyncDelegate {
        return null; // TODO: Implement SyncDelegate
    }

    // Optional: Sync configuration view
    function getSyncConfigurationView() as [WatchUi.View] or [WatchUi.View, WatchUi.InputDelegate] or Null {
        return null; // TODO: Implement SyncConfigurationView
    }

    // Optional: Playback configuration view
    function getPlaybackConfigurationView() as [WatchUi.View] or [WatchUi.View, WatchUi.InputDelegate] or Null {
        return null; // TODO: Implement PlaybackConfigurationView
    }
}
```

**Step 2: Attempt compilation**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg source/PlexRunnerApp.mc --manifest manifest.xml --api-level 5.2.0
```

Expected: Compilation should succeed (with warnings about returning null from delegates - that's expected for now)

**Step 3: Commit**

```bash
git add source/PlexRunnerApp.mc
git commit -m "feat: add PlexRunnerApp entry point

- Extends AudioContentProviderApp
- Stub methods for ContentDelegate and SyncDelegate
- Stub methods for configuration views
- Compiles successfully for fr970"
```

---

## Phase 2: Copy Reusable Modules

### Task 3: Copy PlexConfig Module

**Files:**
- Create: `source/PlexConfig.mc` (copied from audiobook-mvp)

**Step 1: Copy PlexConfig.mc**

```bash
cp /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/source/PlexConfig.mc source/
```

**Step 2: Review and update for Application.Properties**

The existing PlexConfig uses Application.Storage. We need to update it to read from Application.Properties (which Garmin Connect syncs).

Modify `source/PlexConfig.mc` to read settings from properties:

```monkeyc
using Toybox.Application;
using Toybox.Lang;

// ABOUTME: PlexRunner configuration management reading from Garmin Connect settings
// ABOUTME: Settings synced via Application.Properties from phone app

module PlexConfig {

    // Read from Application.Properties (synced from Garmin Connect)
    function getServerUrl() as Lang.String {
        var url = Application.Properties.getValue("serverUrl");
        if (url == null) {
            return ""; // No server configured
        }
        return url as Lang.String;
    }

    function getAuthToken() as Lang.String {
        var token = Application.Properties.getValue("authToken");
        if (token == null) {
            return ""; // No token configured
        }
        return token as Lang.String;
    }

    function getLibraryName() as Lang.String {
        var name = Application.Properties.getValue("libraryName");
        if (name == null) {
            return "Music"; // Default library name
        }
        return name as Lang.String;
    }

    // Client ID stored in app storage (not user-configurable)
    function getClientId() as Lang.String {
        var clientId = Application.Storage.getValue("client_id");
        if (clientId == null) {
            // Generate new UUID-like client ID
            clientId = "plexrunner-" + System.getTimer().toString();
            Application.Storage.setValue("client_id", clientId);
        }
        return clientId as Lang.String;
    }

    function isAuthenticated() as Lang.Boolean {
        var url = getServerUrl();
        var token = getAuthToken();
        return url.length() > 0 && token.length() > 0;
    }
}
```

**Step 3: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS (module compiles)

**Step 4: Commit**

```bash
git add source/PlexConfig.mc
git commit -m "feat: add PlexConfig module for settings management

- Reads serverUrl, authToken, libraryName from Application.Properties
- Properties synced from Garmin Connect settings
- Client ID generated and stored locally
- isAuthenticated() checks configuration validity"
```

---

### Task 4: Copy PlexApi Module

**Files:**
- Create: `source/PlexApi.mc` (copied from audiobook-mvp)

**Step 1: Copy PlexApi.mc**

```bash
cp /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/source/PlexApi.mc source/
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/PlexApi.mc
git commit -m "feat: add PlexApi module for HTTP communication

- makeAuthenticatedRequest() for Plex API calls
- Uses PlexConfig for server URL and auth token
- Module-level callback pattern (no closures)
- Reused from audiobook-mvp without changes"
```

---

### Task 5: Copy PositionTracker Module

**Files:**
- Create: `source/PositionTracker.mc` (copied from audiobook-mvp)

**Step 1: Copy PositionTracker.mc**

```bash
cp /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/source/PositionTracker.mc source/
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/PositionTracker.mc
git commit -m "feat: add PositionTracker module for local position storage

- updatePosition(), getPosition(), markCompleted()
- Persistent storage with symbol keys
- Works 100% offline
- Reused from audiobook-mvp without changes"
```

---

### Task 6: Copy PositionSync Module

**Files:**
- Create: `source/PositionSync.mc` (copied from audiobook-mvp)

**Step 1: Copy PositionSync.mc**

```bash
cp /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp/source/PositionSync.mc source/
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/PositionSync.mc
git commit -m "feat: add PositionSync module for server position sync

- syncPosition(), syncAllPositions(), syncPositionForBook()
- Uses Plex Timeline API
- Opportunistic sync when connectivity available
- Reused from audiobook-mvp without changes"
```

---

## Phase 3: ContentDelegate Implementation

### Task 7: Create ContentDelegate Skeleton

**Files:**
- Create: `source/ContentDelegate.mc`

**Step 1: Create ContentDelegate.mc skeleton**

```monkeyc
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
        return [] as Lang.Array<Media.Playlist>;
    }

    // Return chapters for selected audiobook
    function getPlaylistTracks(playlistId as Lang.String) as Lang.Array<Media.Track> {
        // TODO: Read metadata, return chapters
        return [] as Lang.Array<Media.Track>;
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
```

**Step 2: Update PlexRunnerApp to return ContentDelegate**

Modify `source/PlexRunnerApp.mc`:

```monkeyc
function getContentDelegate() as Media.ContentDelegate {
    return new ContentDelegate();
}
```

**Step 3: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 4: Commit**

```bash
git add source/ContentDelegate.mc source/PlexRunnerApp.mc
git commit -m "feat: add ContentDelegate skeleton

- Implements Media.ContentDelegate protocol
- Stub methods for getPlaylists, getPlaylistTracks
- Stub callbacks for playback (onSongStarted, onSongFinished)
- PlexRunnerApp returns ContentDelegate instance
- Compiles successfully"
```

---

## Phase 4: SyncDelegate Implementation

### Task 8: Create SyncDelegate Skeleton

**Files:**
- Create: `source/SyncDelegate.mc`

**Step 1: Create SyncDelegate.mc skeleton**

```monkeyc
using Toybox.Media;
using Toybox.Lang;

// ABOUTME: SyncDelegate handles audiobook downloads from Plex server
// ABOUTME: Triggered by Garmin Connect when user selects audiobooks to sync

class SyncDelegate extends Media.SyncDelegate {

    function initialize() {
        SyncDelegate.initialize();
    }

    // Called when sync starts from Garmin Connect
    function sync() as Void {
        // TODO: Implement sync logic
        // 1. Get sync request (which audiobooks to download)
        // 2. For each audiobook:
        //    - Fetch metadata from Plex
        //    - Download audio files
        //    - Store locally
        //    - Register with Media.getCachedContentObj()
        // 3. Report progress
    }

    // Called to cancel ongoing sync
    function cancelSync() as Void {
        // TODO: Implement cancellation
    }
}
```

**Step 2: Update PlexRunnerApp to return SyncDelegate**

Modify `source/PlexRunnerApp.mc`:

```monkeyc
function getSyncDelegate() as Media.SyncDelegate {
    return new SyncDelegate();
}
```

**Step 3: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 4: Commit**

```bash
git add source/SyncDelegate.mc source/PlexRunnerApp.mc
git commit -m "feat: add SyncDelegate skeleton

- Implements Media.SyncDelegate protocol
- Stub sync() method for download logic
- Stub cancelSync() method
- PlexRunnerApp returns SyncDelegate instance
- Compiles successfully"
```

---

## Phase 5: Configuration Views

### Task 9: Create SyncConfigurationView

**Files:**
- Create: `source/views/SyncConfigurationView.mc`
- Create: `source/views/SyncConfigurationDelegate.mc`

**Step 1: Create views directory**

```bash
mkdir -p source/views
```

**Step 2: Create SyncConfigurationView.mc**

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Application;

// ABOUTME: SyncConfigurationView shows sync status and last sync time
// ABOUTME: Displayed in Music Player settings for PlexRunner

class SyncConfigurationView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Simple text-based layout
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.drawText(
            dc.getWidth() / 2,
            40,
            Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.SyncConfigTitle) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Last sync time
        var lastSync = Application.Storage.getValue("last_sync_time");
        var lastSyncText = WatchUi.loadResource(Rez.Strings.NeverSynced) as Lang.String;

        if (lastSync != null) {
            // TODO: Format timestamp
            lastSyncText = lastSync.toString();
        }

        dc.drawText(
            dc.getWidth() / 2,
            120,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.LastSync) as Lang.String + " " + lastSyncText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Server status
        var serverUrl = Application.Properties.getValue("serverUrl");
        var statusText = serverUrl != null ? "Configured" : "Not Configured";

        dc.drawText(
            dc.getWidth() / 2,
            180,
            Graphics.FONT_TINY,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }
}
```

**Step 3: Create SyncConfigurationDelegate.mc**

```monkeyc
using Toybox.WatchUi;

// ABOUTME: Delegate for SyncConfigurationView handling user input
// ABOUTME: Currently no interactive elements, but required by Garmin

class SyncConfigurationDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        // No action on select
        return true;
    }
}
```

**Step 4: Update PlexRunnerApp to return SyncConfigurationView**

Modify `source/PlexRunnerApp.mc`:

```monkeyc
function getSyncConfigurationView() as [WatchUi.View] or [WatchUi.View, WatchUi.InputDelegate] or Null {
    return [new SyncConfigurationView(), new SyncConfigurationDelegate()] as [WatchUi.View, WatchUi.InputDelegate];
}
```

**Step 5: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 6: Commit**

```bash
git add source/views/
git add source/PlexRunnerApp.mc
git commit -m "feat: add SyncConfigurationView

- Shows sync status and last sync time
- Displays server configuration status
- Simple text-based layout for watch display
- PlexRunnerApp returns view and delegate
- Compiles successfully"
```

---

### Task 10: Create PlaybackConfigurationView

**Files:**
- Create: `source/views/PlaybackConfigurationView.mc`
- Create: `source/views/PlaybackConfigurationDelegate.mc`

**Step 1: Create PlaybackConfigurationView.mc**

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// ABOUTME: PlaybackConfigurationView shows current audiobook and playback position
// ABOUTME: Optional view displayed in Music Player for PlexRunner

class PlaybackConfigurationView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.PlaybackConfigTitle) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // TODO: Show current audiobook and position from PositionTracker
    }

    function onHide() as Void {
    }
}
```

**Step 2: Create PlaybackConfigurationDelegate.mc**

```monkeyc
using Toybox.WatchUi;

// ABOUTME: Delegate for PlaybackConfigurationView handling user input
// ABOUTME: Currently no interactive elements

class PlaybackConfigurationDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
}
```

**Step 3: Update PlexRunnerApp to return PlaybackConfigurationView**

Modify `source/PlexRunnerApp.mc`:

```monkeyc
function getPlaybackConfigurationView() as [WatchUi.View] or [WatchUi.View, WatchUi.InputDelegate] or Null {
    return [new PlaybackConfigurationView(), new PlaybackConfigurationDelegate()] as [WatchUi.View, WatchUi.InputDelegate];
}
```

**Step 4: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 5: Commit**

```bash
git add source/views/
git add source/PlexRunnerApp.mc
git commit -m "feat: add PlaybackConfigurationView

- Shows now playing title (placeholder for now)
- Will display current audiobook and position
- Simple text-based layout
- PlexRunnerApp returns view and delegate
- Compiles successfully

Phase 5 complete: All configuration views implemented"
```

---

## Phase 6: Settings Schema for Garmin Connect

### Task 11: Create Properties Definition

**Files:**
- Create: `resources/properties/properties.xml`
- Create: `resources/settings/settings.xml`

**Step 1: Create properties directory and properties.xml**

```bash
mkdir -p resources/properties
```

```xml
<properties>
    <property id="serverUrl" type="string">
        <default></default>
    </property>
    <property id="authToken" type="string">
        <default></default>
    </property>
    <property id="libraryName" type="string">
        <default>Music</default>
    </property>
</properties>
```

**Step 2: Create settings directory and settings.xml**

```bash
mkdir -p resources/settings
```

```xml
<settings>
    <setting propertyKey="@Properties.serverUrl" title="@Strings.ServerUrl">
        <settingConfig type="textInput" />
    </setting>
    <setting propertyKey="@Properties.authToken" title="@Strings.AuthToken">
        <settingConfig type="textInput" isPassword="true" />
    </setting>
    <setting propertyKey="@Properties.libraryName" title="@Strings.LibraryName">
        <settingConfig type="textInput" />
    </setting>
</settings>
```

**Step 3: Add strings to resources/strings/strings.xml**

Add these to existing strings.xml:

```xml
<string id="ServerUrl">Plex Server URL</string>
<string id="AuthToken">Auth Token</string>
<string id="LibraryName">Library Name</string>
```

**Step 4: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 5: Commit**

```bash
git add resources/properties/ resources/settings/ resources/strings/
git commit -m "feat: add Garmin Connect settings schema

- properties.xml defines serverUrl, authToken, libraryName
- settings.xml creates Garmin Connect UI for configuration
- User enters settings on phone, syncs to watch via Properties
- authToken uses password field for security
- Compiles successfully"
```

---

## Phase 7: Content Catalog Implementation

### Task 12: Implement Storage Module for Audiobook Metadata

**Files:**
- Create: `source/AudiobookStorage.mc`

**Step 1: Create AudiobookStorage.mc**

```monkeyc
using Toybox.Application;
using Toybox.Lang;

// ABOUTME: AudiobookStorage manages locally synced audiobook metadata
// ABOUTME: Reads/writes audiobook catalog and track information

module AudiobookStorage {

    // Storage key for audiobook catalog
    const KEY_AUDIOBOOKS = "synced_audiobooks";

    // Get all synced audiobooks
    // Returns: Array of dictionaries with {:ratingKey, :title, :author, :duration, :tracks}
    function getAudiobooks() as Lang.Array {
        var audiobooks = Application.Storage.getValue(KEY_AUDIOBOOKS);
        if (audiobooks == null) {
            return [] as Lang.Array;
        }
        if (!(audiobooks instanceof Lang.Array)) {
            return [] as Lang.Array;
        }
        return audiobooks as Lang.Array;
    }

    // Get specific audiobook by ratingKey
    function getAudiobook(ratingKey as Lang.String) as Lang.Dictionary or Null {
        var audiobooks = getAudiobooks();
        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (book[:ratingKey].equals(ratingKey)) {
                return book;
            }
        }
        return null;
    }

    // Save audiobook metadata
    function saveAudiobook(metadata as Lang.Dictionary) as Void {
        var audiobooks = getAudiobooks();

        // Check if already exists, update or append
        var found = false;
        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (book[:ratingKey].equals(metadata[:ratingKey])) {
                audiobooks[i] = metadata;
                found = true;
                break;
            }
        }

        if (!found) {
            audiobooks.add(metadata);
        }

        Application.Storage.setValue(KEY_AUDIOBOOKS, audiobooks);
    }

    // Remove audiobook
    function removeAudiobook(ratingKey as Lang.String) as Void {
        var audiobooks = getAudiobooks();
        var filtered = [] as Lang.Array;

        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i] as Lang.Dictionary;
            if (!book[:ratingKey].equals(ratingKey)) {
                filtered.add(book);
            }
        }

        Application.Storage.setValue(KEY_AUDIOBOOKS, filtered);
    }

    // Get tracks for audiobook
    function getTracks(ratingKey as Lang.String) as Lang.Array {
        var book = getAudiobook(ratingKey);
        if (book == null) {
            return [] as Lang.Array;
        }
        var tracks = book[:tracks];
        if (tracks == null || !(tracks instanceof Lang.Array)) {
            return [] as Lang.Array;
        }
        return tracks as Lang.Array;
    }
}
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/AudiobookStorage.mc
git commit -m "feat: add AudiobookStorage module for metadata management

- getAudiobooks() returns all synced audiobooks
- getAudiobook() fetches by ratingKey
- saveAudiobook() stores/updates metadata
- removeAudiobook() deletes from catalog
- getTracks() returns chapters for audiobook
- Compiles successfully"
```

---

### Task 13: Implement ContentDelegate.getPlaylists()

**Files:**
- Modify: `source/ContentDelegate.mc`

**Step 1: Update ContentDelegate to use AudiobookStorage**

Replace the `getPlaylists()` method in `source/ContentDelegate.mc`:

```monkeyc
using AudiobookStorage;

function getPlaylists() as Lang.Array<Media.Playlist> {
    var playlists = [] as Lang.Array<Media.Playlist>;
    var audiobooks = AudiobookStorage.getAudiobooks();

    for (var i = 0; i < audiobooks.size(); i++) {
        var book = audiobooks[i] as Lang.Dictionary;

        var playlist = new Media.Playlist(
            book[:ratingKey] as Lang.String,  // playlistId
            book[:title] as Lang.String,      // title
            book[:author] as Lang.String      // subtitle/artist
        );

        playlists.add(playlist);
    }

    return playlists;
}
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/ContentDelegate.mc
git commit -m "feat: implement ContentDelegate.getPlaylists()

- Reads synced audiobooks from AudiobookStorage
- Converts each to Media.Playlist
- Returns array of playlists to native Music Player
- Empty array if no audiobooks synced
- Compiles successfully"
```

---

### Task 14: Implement ContentDelegate.getPlaylistTracks()

**Files:**
- Modify: `source/ContentDelegate.mc`

**Step 1: Update ContentDelegate.getPlaylistTracks()**

Replace the `getPlaylistTracks()` method:

```monkeyc
function getPlaylistTracks(playlistId as Lang.String) as Lang.Array<Media.Track> {
    var mediaTracks = [] as Lang.Array<Media.Track>;
    var tracks = AudiobookStorage.getTracks(playlistId);

    for (var i = 0; i < tracks.size(); i++) {
        var track = tracks[i] as Lang.Dictionary;

        var mediaTrack = new Media.Track(
            track[:partId] as Lang.String,    // trackId (unique identifier)
            track[:title] as Lang.String,     // track title (e.g., "Chapter 1")
            track[:duration] as Lang.Number   // duration in milliseconds
        );

        mediaTracks.add(mediaTrack);
    }

    return mediaTracks;
}
```

**Step 2: Compile to verify**

Run:
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

Expected: SUCCESS

**Step 3: Commit**

```bash
git add source/ContentDelegate.mc
git commit -m "feat: implement ContentDelegate.getPlaylistTracks()

- Reads tracks/chapters from AudiobookStorage
- Converts each to Media.Track with title and duration
- Returns array of tracks for selected audiobook
- Empty array if audiobook not found
- Compiles successfully

Content catalog implementation complete"
```

---

## Next Steps

**Implementation Status:**
- ✅ Phase 1: Project Setup
- ✅ Phase 2: Reusable Modules
- ✅ Phase 3: ContentDelegate Skeleton
- ✅ Phase 4: SyncDelegate Skeleton
- ✅ Phase 5: Configuration Views
- ✅ Phase 6: Settings Schema
- ✅ Phase 7: Content Catalog (partial - getPlaylists and getTracks)

**Remaining Work:**
- Phase 8: Sync Implementation (SyncDelegate.sync())
- Phase 9: Playback Integration (ContentDelegate.onPlaybackRequested())
- Phase 10: Position Tracking Integration

**Note:** This plan is comprehensive but incomplete. The remaining phases require:
1. Understanding Garmin's sync request API
2. File download and storage implementation
3. Media.ContentRef and Media.getCachedContentObj() usage
4. Position tracking integration with playback callbacks

These tasks require research into Connect IQ Media APIs that wasn't fully completed in the design phase. Recommend continuing implementation to this point, then researching the Media APIs before proceeding with remaining phases.

---

## Compilation Quick Reference

**Compile all sources:**
```bash
monkeyc --device fr970 --output bin/PlexRunner.prg $(find source -name "*.mc") --manifest manifest.xml --api-level 5.2.0
```

**Check file structure:**
```bash
tree -I 'bin'
```

**Git status:**
```bash
git status --short
```
