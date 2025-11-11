# PlexRunner AudioContentProviderApp

**Phone-free audiobook listening from your Plex server on Garmin watches**

PlexRunner integrates with Garmin's native Music Player to provide audiobooks from your Plex server. Select audiobooks via Garmin Connect on your phone, sync them to your watch, and enjoy them during phone-free runs.

## Features

- ✅ Browse and select audiobooks from Plex library (via companion mobile app)
- ✅ Download audiobooks to watch storage
- ✅ Native Music Player integration (standard Garmin playback controls)
- ✅ Hierarchical navigation (audiobooks → chapters)
- ✅ Position tracking with opportunistic sync to Plex
- ✅ 100% offline playback support
- ✅ Battery-efficient native audio session management
- ✅ React Native companion app for iOS and Android

## Architecture

PlexRunner is an **AudioContentProviderApp** that extends Garmin's native Music Player:

- **ContentIterator** - Navigates through audiobooks and chapters
- **ContentDelegate** - Provides catalog and handles playback callbacks
- **SyncDelegate** - Downloads audiobooks from Plex when triggered
- **AudiobookStorage** - Manages locally synced audiobook metadata
- **PositionTracker** - Tracks playback position locally
- **PositionSync** - Syncs positions to Plex Timeline API opportunistically

## Configuration

### Via Garmin Connect App

PlexRunner is configured through Garmin Connect's built-in app settings:

1. **Plex Server URL** (required)
   - Example: `https://plex.example.com:32400`
   - Your Plex server must be accessible from the watch

2. **Auth Token** (required)
   - Obtain from: plex.tv → Account → XML (token in URL)
   - Or: Browser dev tools on any Plex page
   - Paste into Garmin Connect

3. **Library Name** (optional, default: "Music")
   - Name of your Plex Music library containing audiobooks

Settings sync automatically to watch via `Application.Properties`.

### Getting Your Auth Token

**Method 1: plex.tv**
1. Visit https://www.plex.tv/
2. Sign in to your account
3. Click your profile → Account
4. Click "View XML" in any section
5. Copy the token from the URL: `?X-Plex-Token=YOUR_TOKEN_HERE`

**Method 2: Browser Dev Tools**
1. Open Plex Web in your browser
2. Open Developer Tools (F12)
3. Go to Network tab
4. Reload the page
5. Look for any request, find `X-Plex-Token` header
6. Copy the token value

## Usage Flow

### 1. Sync Audiobooks (via Companion App)

1. Install PlexRunner Companion app on your phone (see `companion/` directory)
2. Configure Plex server connection in companion app
3. Browse your Plex audiobook library
4. Select audiobooks to sync to watch
5. Tap "Sync to Watch" button

**What happens:**
- Companion app sends audiobook list to watch via Garmin SDK
- Watch downloads audiobook metadata from Plex
- Audio files download sequentially with progress updates
- ContentRef IDs registered with media system
- Metadata stored in `AudiobookStorage`

### 2. Listen to Audiobooks

1. On watch: Open Music Player
2. Navigate to PlexRunner section
3. See list of synced audiobooks
4. Select audiobook → see chapters
5. Select chapter → press play

**What happens:**
- Native Music Player handles playback
- ContentIterator provides next/previous navigation
- Playback automatically advances to next chapter
- Position tracked locally in real-time

### 3. Position Tracking & Sync

**Local Tracking (100% offline):**
- Every chapter start/pause/complete saves position
- Works without connectivity
- Stored in `Application.Storage`

**Opportunistic Plex Sync:**
- Every 5 minutes (if connected)
- After audiobook sync completes
- When app stops
- Silently fails if no connectivity

## Technical Details

### Storage Structure

```
Application.Storage:
  - synced_audiobooks: [{
      ratingKey: "12345",
      title: "Book Title",
      author: "Author Name",
      duration: 3600000,
      tracks: [{
        refId: "content_ref_id",
        partId: "part_id",
        key: "/library/parts/123/file.mp3",
        duration: 1800000,
        title: "Chapter 1"
      }, ...]
    }, ...]

  - positions: {
      "12345": {
        position: 150000,
        timestamp: 1234567890,
        currentPart: "content_ref_id",
        completed: false
      }
    }
```

### API Integration

**Plex API Endpoints Used:**
- `/library/metadata/{ratingKey}` - Fetch audiobook metadata
- `/library/parts/{id}/file.mp3` - Download audio files
- `/:/timeline` - Sync playback position (via PositionSync)

**Garmin Connect IQ APIs:**
- `Communications.SyncDelegate` - Handles audiobook downloads
- `Media.ContentIterator` - Manages chapter navigation
- `Media.ContentDelegate` - Provides catalog and callbacks
- `Media.getCachedContentObj()` - Retrieves downloaded audio
- `Application.Properties` - Synced settings from Garmin Connect

### Module Descriptions

**Core Application:**
- `PlexRunnerApp.mc` - Main app entry point, lifecycle management
- `ContentDelegate.mc` - Media player interactions, playback callbacks
- `ContentIterator.mc` - Audiobook/chapter navigation logic
- `SyncDelegate.mc` - Audiobook download orchestration

**Reusable Modules (from audiobook-mvp):**
- `PlexConfig.mc` - Configuration management
- `PlexApi.mc` - HTTP communication with Plex
- `PositionTracker.mc` - Local position tracking
- `PositionSync.mc` - Position upload to Plex Timeline API

**Storage & Helpers:**
- `AudiobookStorage.mc` - Metadata persistence
- `RequestDelegate.mc` - Async HTTP callback helper

**Views (not integrated):**
- `SyncConfigurationView.mc` - Sync status display
- `PlaybackConfigurationView.mc` - Now playing display

## Known Limitations

### Configuration Views Not Integrated

The optional configuration view methods (`getSyncConfigurationView()` and `getPlaybackConfigurationView()`) could not be integrated due to API signature ambiguity. The views exist but are not hooked up to `PlexRunnerApp`.

**Impact:** Users cannot view sync status or now playing info from within the app. This is cosmetic only - all functionality works.

**Workaround:** Check Garmin Connect app for sync status.

### Companion Mobile App

PlexRunner includes a React Native companion app for iOS and Android:
- Browse Plex library on phone with cover art
- Select audiobooks for sync
- Send sync list to watch via Garmin Connect IQ SDK
- Simple setup and configuration

**Location:** See `companion/` directory for source code and documentation.

### Media Encoding

Currently hardcoded to `Media.ENCODING_MP3`. Plex transcoding may be required for non-MP3 audiobooks.

## Development

### Build

```bash
monkeyc --jungles monkey.jungle \
        --device fr970 \
        --output bin/PlexRunner.prg \
        --private-key developer_key
```

### Target Device

- **Garmin Forerunner 970**
- API Level: 5.2.0
- SDK: Connect IQ 8.3.0

### Project Structure

```
.
├── manifest.xml           # App manifest
├── monkey.jungle          # Build configuration
├── resources/
│   ├── drawables/        # Launcher icon
│   ├── properties/       # Settings schema
│   ├── settings/         # Garmin Connect UI
│   └── strings/          # Localized strings
├── source/
│   ├── PlexRunnerApp.mc
│   ├── ContentDelegate.mc
│   ├── ContentIterator.mc
│   ├── SyncDelegate.mc
│   ├── RequestDelegate.mc
│   ├── AudiobookStorage.mc
│   ├── PlexConfig.mc
│   ├── PlexApi.mc
│   ├── PositionTracker.mc
│   ├── PositionSync.mc
│   └── views/            # Not integrated
└── docs/
    └── plans/            # Design and implementation docs
```

## License

See main PlexRunner project for license information.

## Credits

**Architecture based on:**
- Garmin's MonkeyMusic sample app
- Connect IQ SDK documentation

**Developed by:** Claude & Vegar (2025)

---

**Note:** This is a redesign of the original audiobook-mvp implementation, rebuilt as a proper AudioContentProviderApp after discovering the original architecture was incompatible with Garmin's audio system.
