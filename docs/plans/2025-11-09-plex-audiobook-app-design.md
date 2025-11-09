# PlexRunner: Plex Audiobook App for Garmin Forerunner 970

**Design Document**
**Date:** November 9, 2025
**Target Device:** Garmin Forerunner 970 (expandable to other Connect IQ devices)
**Project Goal:** Build a functional audiobook player that syncs content from Plex Media Server for offline playback during workouts

---

## Project Overview

PlexRunner is a Garmin Connect IQ Audio Content Provider app that downloads audiobooks from a Plex Media Server and integrates them with the watch's native media player. This is a capability exploration project to determine what Claude Code can autonomously build with minimal human intervention.

**User Role:**
- Define requirements and make decisions
- Test on physical Forerunner 970 hardware
- Deploy builds to watch
- Report functionality and issues

**Claude Code Role:**
- Write all Monkey C code
- Set up project structure and build system
- Integrate with Plex API
- Debug based on feedback
- Research solutions when needed

**Success Criteria:**
A functional MVP that plays music, podcasts, and audiobooks from Plex with:
- Reliable authentication
- WiFi-based download and sync
- Continuous position tracking with resume capability
- Manual storage management
- Integration with Garmin's native media player

---

## 1. Architecture Overview

PlexRunner follows Garmin's Audio Content Provider architecture, acting as a "plugin" for the watch's native media player rather than a standalone player.

### Core Components

**PlexAuth**
- Handles Plex authentication using PIN-based OAuth flow
- Manages JWT token lifecycle (7-day expiration with auto-refresh)
- Stores credentials securely in watch persistent storage

**PlexAPI**
- Communicates with Plex server over HTTP/HTTPS
- Browses audiobook library (Music library type)
- Fetches metadata (authors, books, chapters, cover art)
- Downloads audio files with optional transcoding

**AudiobookBrowser**
- UI for discovering and selecting audiobooks
- Smart lists: Continue Reading, Plex Collections, All Audiobooks
- Displays book details, file sizes, download status

**SyncManager**
- Downloads audiobooks from Plex over WiFi
- Handles single-file M4B and multi-file chapter formats
- Tracks download progress with cancellation support
- Manages transcoding requests for incompatible formats

**StorageManager**
- Tracks storage usage on watch
- Calculates space used by audiobooks
- Warns before downloads if insufficient space
- Provides manual deletion interface

**PositionTracker**
- Saves playback position every 30 seconds locally
- Syncs positions back to Plex on next sync
- Handles both single-file and multi-file audiobooks
- Enables resume across devices via Plex

**ContentProvider**
- Implements Garmin's AudioContentProviderApp interface
- Registers downloaded audiobooks with native media player
- Provides track lists and metadata to player
- Receives playback callbacks for position tracking

### Data Flow

1. User authenticates once with Plex (PIN-based OAuth)
2. Browse audiobooks via smart lists or collections
3. Select audiobook to download
4. Manual sync downloads audiobook over WiFi
5. Garmin's native music player sees the audiobook
6. User plays audiobook with standard controls
7. Position saves every 30 seconds locally
8. Next sync uploads position to Plex server

### Technology Stack

- **Language:** Monkey C (Garmin's proprietary language)
- **SDK:** Connect IQ 8.3.0 (supports API Level 5.2)
- **Target Device:** Forerunner 970 (API Level 5.2, AMOLED display)
- **Development:** VS Code with Monkey C extension, Connect IQ SDK tools
- **Testing:** Physical Forerunner 970 hardware + Connect IQ simulator

---

## 2. Authentication & Plex API Integration

### Authentication Flow (PIN-Based OAuth)

Since typing URLs or passwords on a watch is impractical, PlexRunner uses Plex's PIN-based OAuth:

1. **Generate PIN request:** Call `POST https://plex.tv/api/v2/pins` to get a 4-digit code
2. **Display code on watch:** Show "Go to plex.tv/link and enter: 1234"
3. **User authenticates:** Visit plex.tv/link on phone/computer, enter PIN, approve app
4. **Poll for token:** Check every 2-3 seconds if user has approved
5. **Receive JWT token:** Store securely in watch persistent storage
6. **Auto-refresh tokens:** JWT tokens expire after 7 days, app auto-refreshes on next sync

### Plex API Headers

All API calls include authentication and identification headers:

```
X-Plex-Token: <user-jwt-token>
X-Plex-Client-Identifier: <unique-watch-id>
X-Plex-Product: PlexRunner
X-Plex-Platform: Garmin
X-Plex-Device: Forerunner 970
X-Plex-Version: 1.0.0
```

### Key API Endpoints

**Library Discovery:**
- `GET /library/sections` - Get all libraries, find audiobook library
- `GET /library/sections/{id}/all?type=8` - List authors (artists)
- `GET /library/sections/{id}/all?type=9&artist.id={artistId}` - List books by author (albums)
- `GET /playlists` - Get Plex collections/playlists

**Book & Chapter Metadata:**
- `GET /library/metadata/{albumRatingKey}` - Get book details
- `GET /library/metadata/{albumRatingKey}/children` - Get chapters/tracks

**Audio Download:**
- `GET /library/parts/{partId}/file` - Download original file
- `GET /audio/:/transcode/universal/start?path=...&audioCodec=mp3` - Download with transcoding

**Position Tracking:**
- `POST /:/timeline` - Update playback position (scrobbling)
  - Parameters: `ratingKey`, `time` (milliseconds), `state` (playing/paused/stopped), `duration`

### Error Handling

**Network Errors:**
- Timeouts → Retry 3 times with exponential backoff (2s, 4s, 8s)
- Server unreachable → Clear error: "Cannot connect to Plex server. Check WiFi and server status."
- Connection lost mid-download → Pause download: "WiFi lost. Reconnect to continue."

**Authentication Errors:**
- Token expired → Auto-refresh attempt, fall back to PIN flow if refresh fails
- Invalid credentials → "Authentication failed. Re-authenticate in settings."

**Server Errors:**
- 404 Not Found → "Audiobook not found on server."
- 500 Server Error → "Plex server error. Try again later."

**Security Requirements:**
- HTTPS required for all API calls
- Valid CA-signed certificates (no self-signed)
- TLS 1.2+ connections

---

## 3. Audiobook Discovery & UI

### Main Menu Structure

**1. Continue Reading** (if books in progress exist)
- Shows 1-3 audiobooks with saved positions
- Display: Title, Author, Progress percentage (e.g., "The Gods Themselves - 34%")
- One tap to resume playback

**2. Plex Collections** (if user has created playlists)
- Lists custom Plex playlists (e.g., "Sci-Fi", "Currently Reading")
- Tap to browse audiobooks in collection
- Download entire collection or individual books

**3. All Audiobooks**
- Alphabetical list of all audiobooks
- Scroll to browse complete library
- Search by scrolling (no text input)

**4. Downloaded**
- Shows audiobooks currently stored on watch
- Display space used: "3 books, 1.8 GB"
- Tap individual book to delete

**5. Sync Now**
- Triggers manual WiFi sync
- Downloads queued audiobooks
- Uploads playback positions to Plex
- Shows progress during sync

### Audiobook Detail Screen

When selecting an audiobook:

**Display:**
- Cover art (if available and device supports it)
- Title & Author
- Total duration (e.g., "12h 34m")
- File size (e.g., "487 MB")
- Download status: "Not Downloaded" / "Downloading 45%..." / "Downloaded"

**Actions:**
- Download button (if not downloaded)
- Delete button (if downloaded)
- Queue for sync button

### UI Design Constraints

**Small Screen Optimization:**
- Text-based lists (minimal graphics)
- Large touch targets (buttons fill width)
- Minimal scrolling on main menu
- Progress bars for downloads
- Simple icons where helpful

**AMOLED Display Optimization:**
- Dark theme by default (battery efficiency)
- High contrast text for outdoor visibility
- Minimal always-on elements

---

## 4. Plex Audiobook Library Structure

### How Plex Stores Audiobooks

Audiobooks in Plex use a **Music library** (not a dedicated audiobook type). Metadata mapping:

- **Album Artist** = Author (e.g., "Isaac Asimov")
- **Album** = Book Title (e.g., "The Gods Themselves")
- **Track** = Chapter or single file
- **Track Number** = Chapter number (for multi-file books)
- **Title** = Chapter name (e.g., "Chapter 01" or "Part 1")

### Required Plex Library Settings

User's Plex audiobook library must have:
- **Library type:** Music (basic, not premium)
- **Setting enabled:** "Store Track Progress" (for position tracking)
- **Optional:** Audnexus metadata agent for rich Audible metadata

### Detecting Audiobook Format

Query book metadata to determine format:

**Single-File M4B Books:**
- Track count = 1
- One continuous file with optional embedded chapters
- Position tracking: milliseconds into single file
- Example: "Cable Cowboy.m4b" (12 hours, one file)

**Multi-File Chapter Books:**
- Track count > 1
- Multiple files, one per chapter
- Position tracking: current chapter + position within chapter
- Example: "The Gods Themselves" (48 MP3 files)

### API Query Strategy

1. **Get audiobook library ID:** `/library/sections` → Find "audiobooks" library
2. **List all books:** `/library/sections/{id}/all?type=9` (type=9 = albums)
3. **Filter by author:** Add `&artist.id={artistId}` parameter
4. **Get book chapters:** `/library/metadata/{albumRatingKey}/children`
5. **Determine format:** Check track count in response

---

## 5. Sync & Download Management

### Manual Sync Process

When user taps "Sync Now":

1. **Check WiFi connectivity** → If not on WiFi, show: "Connect to WiFi first"
2. **Validate Plex connection** → Test server reachability, refresh token if needed
3. **Upload positions first** → Send all saved playback positions to Plex (quick, small data)
4. **Download queued audiobooks** → Process download queue one at a time
5. **Show progress** → "Downloading: The Gods Themselves (Chapter 12/48) - 67%"
6. **Complete or fail** → "Sync complete: 2 books downloaded" or "Sync failed: Connection lost"

### Download Strategies by Format

**Single-File M4B Audiobooks:**
- Download complete M4B file as one HTTP request
- Store as single audio item
- Garmin player treats it as one long track
- Example: 487 MB file, ~15-30 minutes download on WiFi

**Multi-File Chapter Audiobooks:**
- Download all chapter files sequentially
- Store as playlist/album with track numbers
- Garmin player auto-advances through chapters
- Example: 48 files, ~200-500 MB total

### Transcoding Support

If audiobook is in incompatible format (FLAC, OGG, etc.):

1. Detect incompatible codec from metadata
2. Request transcoded version from Plex universal transcoder
3. Use endpoint: `/audio/:/transcode/universal/start?path=...&audioCodec=mp3`
4. Download transcoded MP3/M4A stream instead of original
5. Supported output: MP3, M4A, AAC (Garmin-compatible formats)

### Download Progress Tracking

- Use `Communications.makeWebRequest()` with progress callbacks
- Update UI every second with download percentage
- Display estimated time remaining (optional)
- Allow canceling mid-download
- Resume capability if connection drops (if Plex supports HTTP range requests)

### Storage Pre-Check

Before starting download:

1. Query audiobook file size from Plex metadata
2. Check available storage on watch
3. If insufficient space → Block download, show warning:
   - "Not enough space. Need 487 MB, have 245 MB free."
   - "Delete some audiobooks first."
4. Only proceed if space available + 100 MB buffer

---

## 6. Position Tracking & Resume

### Local Position Tracking (Every 30 Seconds)

During playback, app receives callbacks from Garmin's media player:

- `onPlaybackInfoChanged()` → Fires when position updates
- Save position locally every 30 seconds to watch storage
- Data stored: `{bookRatingKey, trackRatingKey, positionMs, lastUpdated, totalDuration}`

**For Single-File M4B Books:**
- Track one position: current milliseconds into file
- Example: "Cable Cowboy" at 3,245,000ms (54:00 into book)

**For Multi-File Chapter Books:**
- Track both: current chapter number AND position within chapter
- Example: "The Gods Themselves" - Chapter 23 of 48, at 145,000ms (2:25 into chapter)

### Syncing Position to Plex

On next manual sync:

1. Upload all saved positions via `POST /:/timeline`
2. Parameters:
   - `ratingKey={trackRatingKey}` - Identifies the track/chapter
   - `time={positionMs}` - Position in milliseconds
   - `state=stopped` - Playback state
   - `duration={totalDuration}` - Total track duration
3. Plex's "Store Track Progress" setting saves this server-side
4. Other devices (phone, web player) can resume from this position

### Resume on Watch

When user selects a book from "Continue Reading":

1. Check local storage first (fastest)
2. If local position exists → Resume immediately
3. If no local position → Query Plex server for saved position
4. Start playback at saved position automatically
5. Handle edge case: If server position is newer, use that

### Edge Cases & Conflict Resolution

**Book finished:**
- Detect when position > 98% of total duration
- Mark as complete locally
- Remove from "Continue Reading" list
- Optionally sync "completed" status to Plex

**Multiple devices:**
- Plex server position is source of truth
- On sync, compare local vs server timestamps
- Newest position wins (prevents overwriting newer progress)

**Watch reset:**
- Local positions lost, but survive in Plex
- Re-download book → Query Plex for last position
- Resume from server-saved position

---

## 7. Storage Management

### Storage Monitoring

App tracks storage using Garmin's storage APIs:

- Query total available storage on watch
- Calculate space used by PlexRunner audiobooks
- Monitor free space before/during downloads
- Update statistics after deletions

### Storage Display

In "Downloaded" screen:

```
3 audiobooks downloaded
1.8 GB used
Available: 28.4 GB
```

**Per-audiobook details:**
- "The Gods Themselves - 487 MB"
- "Cable Cowboy - 356 MB"
- "Neuromancer - 292 MB"

### Pre-Download Space Check

Before downloading:

1. Get file size from Plex metadata
2. Compare to available storage
3. If insufficient → Show warning and block download:
   - "Not enough space"
   - "Need: 487 MB"
   - "Available: 245 MB"
   - "Delete some audiobooks first"
4. Require 100 MB safety buffer (don't fill storage completely)

### Low Storage Warnings

**During download:**
- If free space drops below 500 MB → Warning message
- If below 100 MB → Abort download, show error

**On main menu:**
- If free space below 100 MB → Red warning badge
- "Storage Low: 87 MB remaining"
- "Delete audiobooks to free space"

### Manual Deletion

From "Downloaded" screen:

1. List all downloaded audiobooks with sizes
2. Tap any book → Shows detail screen
3. "Delete" button prominently displayed
4. Confirmation prompt: "Delete 'The Gods Themselves' (487 MB)?"
5. If book has saved position → Additional warning:
   - "You're 34% through this book"
   - "Position will be saved in Plex"
   - "Delete anyway?"
6. On confirm → Remove all files, update storage display

### No Automatic Deletion

Per user requirement:
- App NEVER auto-deletes audiobooks
- User has full manual control
- App only warns when space is low
- No "smart" cleanup algorithms

---

## 8. Playback Integration

### Audio Content Provider Implementation

PlexRunner implements Garmin's `AudioContentProviderApp` interface:

**ContentDelegate**
- Returns list of available audiobooks when player requests
- Provides metadata (title, author, duration, cover art)
- Maps audiobooks to player's content structure

**ContentIterator**
- Provides track-by-track playback queue
- For single-file books: One track
- For multi-file books: All chapters in order

**Playback Callbacks**
- `onPlaybackInfoChanged()` → Track position updates
- `onContentSelected()` → User selected audiobook
- `onContentRemoved()` → Audiobook deleted

### Playback Flow

1. User downloads "The Gods Themselves" (48 chapter files)
2. App stores files and registers with Garmin's media player
3. User opens Garmin's music player → Sees "PlexRunner" as provider
4. Selects "PlexRunner" → Sees downloaded audiobooks
5. Taps "The Gods Themselves" → Player loads all 48 chapters as queue
6. Presses play → Chapter 1 starts
7. Chapter completes → Auto-advances to Chapter 2
8. PlexRunner receives playback events → Saves position every 30 seconds

### Native Player Controls

User controls playback via Garmin's standard media player:

- **Play/Pause** - Standard playback control
- **Next Track** - Next chapter (for multi-file books) or skip forward 30s (single-file)
- **Previous Track** - Previous chapter or skip back 30s
- **30-Second Skip** - Forward/backward navigation
- **Volume** - Adjust audio level
- **Output Selection** - Built-in speaker or Bluetooth headphones

**No Custom Controls:**
- Cannot add speed control (1.5x, 2x)
- Cannot add sleep timer
- Cannot add custom chapter navigation
- Limited to Garmin's native player features

### Audiobook Format Handling

**Single M4B Files:**
- Player treats as one continuous track
- No chapter markers visible to user
- 30-second skip buttons for navigation
- Position tracking handles resume

**Multi-File Chapters:**
- Each file appears as separate track in queue
- "Next track" button = "next chapter"
- Natural chapter navigation via track controls
- Better user experience for chapter-based books

---

## 9. Error Handling

### Authentication Errors

**Token Expired:**
- Detect 401 Unauthorized response
- Attempt auto-refresh with refresh token
- If refresh fails → Display PIN flow again
- Message: "Session expired. Please re-authenticate."

**Server Unreachable:**
- Detect network timeouts or connection refused
- Message: "Cannot connect to Plex server"
- Suggestion: "Check WiFi and server status"
- Don't retry forever (max 3 attempts)

**Invalid Credentials:**
- Detect 403 Forbidden response
- Message: "Authentication failed"
- Action: "Re-authenticate in settings"

### Download Errors

**Network Timeout:**
- Retry 3 times with exponential backoff (2s, 4s, 8s)
- If all retries fail: "Download failed. Check connection and try again."
- Allow user to retry manually

**Insufficient Storage:**
- Pre-check before download starts
- Message: "Not enough space. Need 487 MB, have 245 MB."
- Action: "Delete audiobooks first"
- Block download until space available

**File Corruption:**
- Detect invalid audio file after download
- Message: "Download failed. File corrupted."
- Action: "Try downloading again"
- Automatic cleanup of partial download

**WiFi Disconnected Mid-Download:**
- Pause download immediately
- Message: "WiFi lost. Reconnect to continue."
- Resume from last successful chunk if possible
- Otherwise, restart download

### Playback Errors

**File Missing:**
- Detect when player requests non-existent file
- Message: "Audiobook file missing"
- Action: "Re-download from Plex"
- Remove from downloaded list

**Corrupted Audio:**
- Player reports playback error
- Message: "Cannot play this file"
- Action: "Try re-downloading"

**Position Tracking Failure:**
- Silent fallback: continue playback
- Log error for debugging
- Don't interrupt user experience
- Position saves on next successful callback

### Sync Errors

**Plex Server Offline:**
- Detect connection refused
- Message: "Plex server is offline"
- Action: "Check server status and try again"

**Library Not Found:**
- Detect 404 on library endpoints
- Message: "Audiobook library not found on Plex"
- Action: "Configure audiobook library in Plex settings"

**Upload Position Failed:**
- Non-critical error (playback positions)
- Retry on next sync
- Don't block download operations

### Error Message Principles

**Always provide:**
1. Clear description of what went wrong
2. Suggested action to resolve
3. Technical details only if helpful (not "Error 500")

**Never show:**
- Generic "An error occurred"
- Stack traces or technical jargon
- Errors without suggested actions

---

## 10. Development & Testing Strategy

### Development Environment

**Required Tools:**
- Connect IQ SDK 8.3.0
- Visual Studio Code with Monkey C extension
- Java Runtime Environment (JRE) for SDK tools
- Developer RSA key for signing apps

**Build System:**
- Monkey C compiler (`monkeyc`)
- Build configuration: `monkey.jungle` file
- Output: `.iq` or `.prg` files for device deployment

### Testing Approach

**Physical Device Testing (Primary):**
- Test on actual Forerunner 970
- Validate audio download and playback
- Measure battery impact during sync and playback
- Test Bluetooth headphone connectivity
- Verify storage management
- Real WiFi performance testing

**Simulator Testing (Limited):**
- Basic UI navigation
- Code compilation validation
- Cannot test: audio playback, real downloads, battery, Bluetooth
- Use for rapid iteration on UI changes only

### Development Phases

**Phase 1: Core Infrastructure (Weeks 1-2)**
- Project setup and build system
- Plex authentication (PIN-based OAuth)
- Basic API communication
- Library browsing (list authors and books)
- Simple UI for audiobook selection

**Phase 2: Download & Sync (Weeks 3-4)**
- WiFi sync implementation
- Single-file M4B download
- Multi-file chapter download
- Transcoding support
- Storage management
- Progress tracking

**Phase 3: Playback Integration (Weeks 5-6)**
- ContentProvider implementation
- Register with Garmin media player
- Playback callbacks
- Position tracking (30-second intervals)
- Resume functionality

**Phase 4: Position Sync & Polish (Weeks 7-8)**
- Sync positions to Plex server
- Continue Reading smart list
- Error handling refinement
- UI polish for AMOLED display
- Battery optimization

**Phase 5: Testing & Refinement (Weeks 9-10)**
- Comprehensive hardware testing
- Edge case validation
- Performance optimization
- Bug fixes
- User experience improvements

### Iteration Strategy

**Feedback Loop:**
1. Claude Code implements feature
2. Vegar deploys to Forerunner 970
3. Vegar tests and reports results
4. Claude Code debugs based on feedback
5. Repeat until feature works correctly

**Version Control:**
- Git repository for all code
- Frequent commits after each working feature
- Branches for experimental features
- Tags for stable releases

---

## 11. Future Enhancements (Post-MVP)

### Music & Podcast Support

After audiobooks work reliably:

**Music:**
- Browse music library (same API as audiobooks)
- Download playlists and albums
- Integration with existing audiobook UI

**Podcasts:**
- List podcast series
- Auto-download latest episodes
- Mark episodes as played
- Episode description display

### Advanced Features

**Collections & Playlists:**
- Create custom playlists on watch
- Sync curated collections
- Smart playlists (recently added, unfinished books)

**Playback Enhancements:**
- Custom bookmarks (if API allows)
- Better chapter navigation for M4B
- Playback statistics (hours listened, books completed)

**Background Sync:**
- Explore Garmin's background sync capabilities
- Auto-download queued books overnight (if 30-second limit allows)
- Position sync during activities (if possible)

### Device Expansion

**Other Garmin Watches:**
- Forerunner 965, 955, 745
- Fenix series
- Epix series
- Adjust UI for different screen sizes and shapes

---

## Summary

PlexRunner provides a complete audiobook listening experience on Garmin watches by:

1. **Authenticating** securely with Plex via PIN-based OAuth
2. **Browsing** audiobooks through smart lists and collections
3. **Downloading** books over WiFi with transcoding support
4. **Playing** via Garmin's native media player with standard controls
5. **Tracking** position every 30 seconds, syncing back to Plex
6. **Managing** storage manually with clear warnings

The design prioritizes reliability, simplicity, and user control. By leveraging Plex's existing music library infrastructure and Garmin's proven Audio Content Provider architecture, PlexRunner achieves a functional audiobook player without reinventing complex systems.

**Key Design Decisions:**
- Manual sync only (no automatic background downloads)
- Manual storage management (no auto-deletion)
- Native player controls (no custom playback features)
- Support both M4B and multi-file formats
- Continuous position tracking with Plex sync
- Clear error messages with suggested actions

**Success depends on:**
- Reliable WiFi download performance
- Garmin's ContentProvider API stability
- Plex server uptime and accessibility
- User testing and feedback for UX refinement
- Iterative debugging via hardware testing
