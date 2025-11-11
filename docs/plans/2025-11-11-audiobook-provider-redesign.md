# PlexRunner AudioContentProviderApp Redesign

**Date:** 2025-11-11
**Author:** Claude & Vegar
**Status:** Design Complete

## Overview

PlexRunner provides Plex audiobooks to Garmin's native Music Player. Users select audiobooks via Garmin Connect on their phone, sync them to the watch, and play them through the native player during phone-free runs.

## Architecture

### Application Type

PlexRunner extends `AudioContentProviderApp`, integrating with Garmin's native Music Player as a content plugin. The app provides delegates and configuration views but does not control playback or navigation.

### Core Components

**PlexRunnerApp** (main application class)
- Extends `AudioContentProviderApp`
- Returns `ContentDelegate` via `getContentDelegate()`
- Returns `SyncDelegate` via `getSyncDelegate()`
- Provides configuration views via `getPlaybackConfigurationView()` and `getSyncConfigurationView()`

**ContentDelegate** (provides audiobook catalog to native player)
- Implements `Media.ContentDelegate` protocol
- `getPlaylists()` returns synced audiobooks as playlists
- `getTracksForPlaylist()` returns chapters for selected audiobook
- `onPlaybackRequested()` handles playback start, returns `Media.ContentRef` to local files
- `onSongStarted()` and `onSongFinished()` callbacks track playback position

**SyncDelegate** (downloads audiobooks from Plex)
- Implements sync protocol
- Downloads selected audiobooks when triggered from Garmin Connect
- Fetches metadata from Plex API
- Downloads audio files to watch storage
- Registers content with `Media.getCachedContentObj()`
- Reports progress to Garmin Connect

**Configuration Views**
- `SyncConfigurationView` displays sync status and last sync time
- `PlaybackConfigurationView` shows current audiobook and position

## Configuration Flow

### Setup via Garmin Connect

Users configure PlexRunner through Garmin Connect's built-in app settings:

1. **Server URL** (text input, required)
   - User enters Plex server URL (e.g., `https://plex.example.com:32400`)

2. **Auth Token** (password field, required)
   - User obtains token from plex.tv or browser dev tools
   - Paste into Garmin Connect

3. **Audiobook Library** (text input, optional)
   - Name of Plex Music library containing audiobooks
   - Defaults to "Music"

Settings sync automatically to watch via `Application.Properties`.

### Getting Auth Token

Users obtain their Plex auth token manually:
- Visit plex.tv → Account → XML (shows token in URL)
- Use browser dev tools on any Plex page
- Copy token into Garmin Connect settings

Instructions appear in Connect IQ store listing.

## Sync Mechanism

### User Flow

1. User opens Garmin Connect app on phone
2. Navigates to PlexRunner → Audiobooks
3. Browses Plex library via phone (fetched through Garmin Connect)
4. Selects audiobooks to sync to watch
5. Triggers sync

### Watch Sync Process

When sync starts, `SyncDelegate.sync()` executes:

1. Fetch selected audiobooks from sync request
2. For each audiobook:
   - Fetch metadata: `/library/metadata/{ratingKey}`
   - Get audio parts/chapters
   - Download each file to watch storage: `/storage/audiobooks/{ratingKey}/part_*.mp3`
   - Store metadata locally: `/storage/audiobooks/{ratingKey}/metadata.json`
   - Register with `Media.getCachedContentObj()` using `ContentRef`
3. Report progress to Garmin Connect

Storage structure:
```
/storage/audiobooks/
  {ratingKey}/
    metadata.json
    part_001.mp3
    part_002.mp3
    ...
```

Sync is manual only. Users control what syncs to watch.

## Content Catalog

### Browsing in Music Player

Users open: Music Player → PlexRunner

They see:
- List of synced audiobooks (as "playlists")
- Each shows: Title, Author, Cover art
- Sourced from local metadata

Selecting an audiobook shows:
- Chapters/parts (as "tracks")
- Track titles: "Chapter 1", "Chapter 2", or part names from Plex
- Duration for each track

### Playback Flow

1. User selects audiobook → chapter → presses play
2. Garmin calls `ContentDelegate.onPlaybackRequested(contentKey)`
3. PlexRunner returns `Media.ContentRef` pointing to local audio file
4. Native player handles playback
5. PlexRunner receives callbacks: `onSongStarted()`, `onSongFinished()`

### Resume from Saved Position

When audiobook starts:
- Check `PositionTracker` for saved position
- Return appropriate chapter and timestamp
- Garmin player seeks to position

## Position Tracking

### Local Tracking During Playback

PositionTracker module (reusable from Phase 5):

- On `onSongStarted()`: Note audiobook and chapter
- Every 30 seconds: Update local position in storage
- On `onSongFinished()`: Save final position, advance to next chapter
- Works 100% offline

Storage structure:
```
{
  ratingKey: {
    position: milliseconds,
    timestamp: when last updated,
    currentPart: which chapter/file,
    completed: boolean
  }
}
```

### Opportunistic Sync to Plex

PositionSync module (reusable from Phase 5) syncs positions to Plex Timeline API when connectivity exists.

Background sync triggers:
- Watch connects to phone/WiFi
- After sync completes
- Periodic check every hour (if connected)

Sync process:
1. Check connectivity
2. If connected: Upload changed positions to Plex Timeline API
3. If no connection: Skip silently, retry on next trigger
4. Update local "last synced" timestamp

No user interaction required. Sync happens automatically in background.

## Reusable Modules

These modules from Phase 5 require no changes:

- **PlexConfig** - Storage for settings (reads from Application.Properties)
- **PlexApi** - HTTP communication with Plex APIs
- **DownloadManager** - File download and storage (adapt for sync flow)
- **PositionTracker** - Local position tracking
- **PositionSync** - Upload positions to Plex

## Implementation Phases

### Phase 1: Core Infrastructure
- Restructure PlexRunnerApp for AudioContentProviderApp
- Implement ContentDelegate skeleton
- Implement SyncDelegate skeleton
- Create configuration views

### Phase 2: Garmin Connect Integration
- Define settings schema for Garmin Connect
- Implement settings reading from Application.Properties
- Test configuration flow

### Phase 3: Content Catalog
- Implement ContentDelegate.getPlaylists()
- Implement ContentDelegate.getTracksForPlaylist()
- Display synced audiobooks in native player

### Phase 4: Sync Implementation
- Implement SyncDelegate.sync()
- Download audiobooks from Plex
- Register with Media.getCachedContentObj()
- Report progress

### Phase 5: Playback Integration
- Implement ContentDelegate.onPlaybackRequested()
- Return Media.ContentRef for local files
- Handle resume from saved position

### Phase 6: Position Tracking
- Integrate PositionTracker on playback callbacks
- Implement opportunistic background sync
- Test offline/online scenarios

### Phase 7: Testing & Polish
- End-to-end testing
- Error handling
- Documentation

## Trade-offs

### Advantages of AudioContentProviderApp

- Native music player integration
- Standard Garmin UX
- Battery-efficient playback
- Proper audio session management

### Disadvantages

- Lost custom UI/navigation
- Less control over user flow
- Manual token entry (no PIN flow on watch)
- Depends on Garmin Connect for configuration

### Accepted Constraints

- Users configure via phone/computer (better than watch typing)
- Manual sync only (user controls storage)
- Phone-free running supported (offline playback + opportunistic sync)
- Simple configuration (no companion app needed)
