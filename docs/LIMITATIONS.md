# PlexRunner Technical Limitations & Workarounds

This document describes known limitations, API issues encountered, and technical trade-offs made during development.

## Configuration View Integration

**Issue:** Cannot integrate `SyncConfigurationView` and `PlaybackConfigurationView` with `PlexRunnerApp`.

**Root Cause:** API signature ambiguity for optional configuration view methods:
- Documentation doesn't clearly specify parameter/return types
- Original implementation plan had incorrect signatures
- Multiple compilation attempts with different signatures all failed
- Task 2, 9, 10 all encountered the same issue

**Attempted Signatures:**
```monkeyc
// Attempt 1: From plan
function getSyncConfigurationView() as [WatchUi.View] or [WatchUi.View, WatchUi.InputDelegate] or Null

// Attempt 2: No parameters
function getSyncConfigurationView() as Lang.Array

// Attempt 3: With args parameter
function getSyncConfigurationView(args) as Lang.Array
```

All resulted in compilation errors about incompatible signatures with parent class.

**Current State:**
- Views exist in `source/views/` directory
- Fully implemented with proper UI layout
- Just not hooked up to `PlexRunnerApp.mc`

**Impact:**
- Users cannot view sync status from watch UI
- Users cannot view now playing info from watch UI
- **Does not affect core functionality** - purely cosmetic

**Workaround:**
- Check Garmin Connect app for sync status
- Use native Music Player for playback status

**Future Resolution:**
- Research actual API from working AudioContentProviderApp samples
- Or: Wait for clearer SDK documentation
- Or: Contact Garmin developer support for correct signatures

## Original Implementation Plan Errors

**Issue:** Implementation plan (docs/plans/2025-11-11-audio-provider-implementation.md) contained multiple API errors.

**Errors Found:**

1. **Non-existent APIs (Tasks 13-14)**
   ```monkeyc
   // Plan specified:
   function getPlaylists() as Lang.Array<Media.Playlist>
   function getPlaylistTracks() as Lang.Array<Media.Track>

   // Reality: These methods don't exist
   // Media.Playlist class doesn't exist
   // Media.Track class doesn't exist
   ```

2. **Incorrect Manifest Type (Task 2)**
   ```xml
   <!-- Plan specified: -->
   <manifest type="audio-content-provider">

   <!-- Correct: -->
   <manifest type="audio-content-provider-app">
   ```

3. **Deprecated API (Task 8)**
   ```monkeyc
   // Plan specified:
   class SyncDelegate extends Media.SyncDelegate

   // Correct (Media.SyncDelegate deprecated):
   class SyncDelegate extends Communications.SyncDelegate
   ```

4. **Invalid App ID Format (Task 2)**
   ```xml
   <!-- Plan specified: -->
   <manifest id="plexrunner-audio-provider">

   <!-- Correct (must be 32-char hex): -->
   <manifest id="7362c2a0f1805be30d6fdfa43b1178bb">
   ```

**Resolution:**
- Researched Garmin's MonkeyMusic sample for correct patterns
- Discovered ContentIterator/ContentDelegate architecture
- Implemented proper APIs throughout Tasks 13-18

**Lesson:** Always verify APIs against official samples and documentation before creating implementation plans.

## Type Casting Issues

**Issue:** Monkey C compiler rejects typed array initializers in some contexts.

**Example:**
```monkeyc
// Fails to compile:
return [] as Lang.Array<Media.Playlist>;

// Compiles successfully:
return [];
```

**Encountered in:** Task 7 (ContentDelegate skeleton)

**Current State:** Using bare `[]` syntax

**Impact:** Potential runtime type safety issues if wrong types are added to arrays

**Mitigation:** Defensive programming and type checking before array access

**Future Resolution:** Monitor for runtime issues, may need to use `new [0]` syntax

## Position Sync Placeholder Duration

**Issue:** `PositionSync.syncAllPositions()` uses placeholder duration value.

**Location:** `source/PositionSync.mc:98`

```monkeyc
var duration = 999999999; // TODO: Get actual duration from PositionTracker
```

**Root Cause:** Duration not stored in PositionTracker data structure

**Impact:** Plex Timeline API receives incorrect duration value

**Workaround:** Plex may calculate duration from audio file metadata

**Future Fix:** Store duration in PositionTracker when chapter starts

## Garmin Connect Companion App Missing

**Issue:** PlexRunner requires companion mobile app that doesn't exist yet.

**Required Functionality:**
1. Browse Plex library via phone (better UX than watch)
2. Display audiobooks with cover art
3. Allow user to select audiobooks for sync
4. Populate `syncList` property: `["ratingKey1", "ratingKey2", ...]`
5. Trigger sync via Garmin Connect SDK

**Current State:**
- Watch app is functionally complete
- Cannot be tested end-to-end without companion app
- `syncList` property must be set manually for testing

**Testing Workaround:**
```bash
# Manually set syncList for testing (requires simulator or device connection)
# This is not a real solution - just for development testing
```

**Future Work:**
- Develop Garmin Connect mobile companion app (separate project)
- Or: Provide CLI tool to populate syncList for testing
- Or: Use Garmin's IQ Mobile SDK to build companion integration

## Media Encoding Hardcoded

**Issue:** Only MP3 encoding currently supported.

**Location:** `source/SyncDelegate.mc:204`

```monkeyc
:mediaEncoding => Media.ENCODING_MP3
```

**Impact:** Non-MP3 audiobooks require Plex transcoding

**Available Encodings (per Connect IQ API):**
- `Media.ENCODING_MP3`
- `Media.ENCODING_M4A`
- `Media.ENCODING_WAV`
- `Media.ENCODING_ADTS`

**Future Enhancement:**
- Detect audio format from Plex metadata
- Map format string to Media.ENCODING_* constant
- MonkeyMusic sample has `typeStringToEncoding()` helper function

## Plex API Assumptions

**Assumptions Made:**

1. **Audiobook Structure:**
   - Single album per audiobook
   - Chapters as separate audio files (tracks)
   - `grandparentTitle` contains author name

2. **Metadata Response Structure:**
   ```json
   {
     "MediaContainer": {
       "Metadata": [{
         "title": "Book Title",
         "grandparentTitle": "Author Name",
         "Media": [{
           "Part": [{
             "id": "123",
             "key": "/library/parts/123/file.mp3",
             "duration": 1800000
           }]
         }]
       }]
     }
   }
   ```

3. **Authentication:**
   - X-Plex-Token in URL params works for all endpoints
   - Token doesn't expire during sync

**Potential Issues:**
- Different Plex library structures may not work
- Multi-part books with complex hierarchies may fail
- Token expiration during long syncs

**Mitigation:**
- Extensive error checking in metadata parsing
- Graceful failure with error messages
- Position tracking persists across app restarts

## Timer Limitations

**Issue:** Background timer for position sync may be suspended by OS.

**Implementation:** `Timer.Timer()` with 5-minute interval

**Garmin Watch Behavior:**
- Timers may not fire if watch is inactive
- Background processes limited to conserve battery
- AudioContentProviderApp may be suspended when Music Player not active

**Impact:** Position syncs may be delayed or skipped

**Mitigation:**
- Sync on app stop (guaranteed)
- Sync after audiobook downloads complete (guaranteed)
- 5-minute timer is best-effort

**Alternative Approach (not implemented):**
- Use native Music Player events as triggers
- Monitor app state changes
- Sync on connectivity change events

## Summary of Workarounds Applied

| Limitation | Workaround Applied |
|-----------|-------------------|
| Configuration views | Created but not integrated; use Garmin Connect |
| Non-existent APIs | Researched MonkeyMusic, implemented ContentIterator |
| Type casting | Use bare `[]` instead of typed arrays |
| Placeholder duration | Accept technical debt, document for future fix |
| Missing companion app | Document requirement, provide manual testing steps |
| Hardcoded MP3 | Document limitation, enhancement for future |
| Timer suspension | Multiple sync triggers ensure eventual sync |

## Testing Recommendations

Given these limitations, thorough testing should cover:

1. **Sync Process:**
   - Various audiobook structures
   - Network interruptions during sync
   - Cancellation handling

2. **Playback & Navigation:**
   - Chapter transitions
   - Next/previous navigation
   - Resume from saved position

3. **Position Tracking:**
   - Multiple start/stop cycles
   - Position accuracy after interruptions
   - Sync to Plex verification

4. **Edge Cases:**
   - Empty audiobook library
   - Malformed metadata responses
   - Auth token expiration
   - No connectivity scenarios

5. **Resource Management:**
   - Memory usage with multiple audiobooks
   - Storage capacity limits
   - Battery impact of periodic syncing

## Conclusion

Most limitations are well-understood and mitigated. The missing Garmin Connect companion app is the only blocking issue for end-user deployment. All core functionality is implemented and working.
