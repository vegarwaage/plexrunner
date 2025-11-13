# PlexRunner Configuration Options: Complete Analysis

**Date:** 2025-11-13
**Purpose:** Clarify real configuration alternatives and resolve settings access issues

## Executive Summary

**Key Findings:**
1. ✅ **Garmin Connect app settings ARE supported** - your app has the correct setup
2. ⚠️ **Settings not appearing** - likely because app needs rebuild with resource files
3. ✅ **SubMusic proves on-watch browsing works** - no companion app needed
4. 📋 **Three viable paths forward** - detailed below

## Current Settings Issue: Why You Only See "Uninstall"

### Problem
When accessing PlexRunner through Music Providers on your watch, you only see "Uninstall" instead of settings for Server URL, Auth Token, and Library Name.

### Root Cause
Your settings files ARE correctly configured, but they're not appearing because:

**File verification shows settings ARE properly defined:**
- ✅ `/resources/properties/properties.xml` - defines serverUrl, authToken, libraryName
- ✅ `/resources/settings/settings.xml` - defines UI for Garmin Connect
- ✅ `/resources/strings/strings.xml` - has all string resources
- ✅ `manifest.xml` - correctly set as `audio-content-provider-app`
- ✅ `PlexConfig.mc` - reads from Application.Properties (no hardcoding)

**Why settings don't appear:**
1. **App not built** - `/bin/` directory doesn't exist, indicating no recent build
2. **Resources not included** - if installed app predates settings files, they won't appear
3. **Wrong access path** - settings for audio provider apps may need different access method

### Where Settings SHOULD Appear

Based on Garmin documentation research:

**Option 1: Garmin Connect Mobile App (RECOMMENDED)**
1. Open Garmin Connect app on iPhone
2. Tap menu → **Garmin Devices**
3. Select your Forerunner 970
4. Scroll to **Connect IQ Apps** section
5. Find **PlexRunner** in the list
6. Tap it → you should see **Settings** option
7. Configure: Server URL, Auth Token, Library Name

**Option 2: On Watch (Music Settings)**
1. From watch face, hold button
2. Select **Settings** → **Music** → **Music Providers**
3. Find PlexRunner
4. Long-press UP button while on PlexRunner
5. Settings should appear (if app properly built)

**Option 3: Garmin Express (Desktop)**
1. Connect watch to computer
2. Open Garmin Express
3. Select device → **Manage Apps**
4. Find PlexRunner → click settings icon (three dots)
5. Edit settings

### Immediate Fix

**You need to rebuild and reinstall the app:**

```bash
# Build with all resources
monkeyc --jungles monkey.jungle \
        --device fr970 \
        --output bin/PlexRunner.prg \
        --private-key developer_key

# Or build .iq file for sideloading
monkeyc --jungles monkey.jungle \
        --device fr970 \
        --output bin/PlexRunner.iq \
        --private-key developer_key \
        --release
```

After installing the newly built app, settings SHOULD appear in Garmin Connect mobile app.

---

## Research Findings: Real Configuration Alternatives

### SubMusic's Proven Approach

SubMusic is a production Garmin app supporting Plex/Subsonic/Ampache. Key findings:

**Configuration Method:**
- ✅ Uses **Garmin Connect app settings** for server URL and auth token
- ✅ Uses **on-watch menu browsing** for content selection
- ❌ Does **NOT use a companion mobile app**

**Direct quotes from SubMusic analysis:**

> "**UI/UX for Small Screens**: Menu-driven navigation with nested text lists provides the primary interface. **Complex configuration lives in the Garmin Connect mobile app rather than requiring on-watch typing**. Two-mode operation separates online browsing (fetch from server) from offline playback (local cache)."

> "**Plex Authentication**: Uses **X-Plex-Token** authentication stored via `Application.Properties`. The implementation requires server address format `https://[ip-address].[hash].plex.direct:32400/` with tokens obtained through plex.tv."

**SubMusic's Menu Structure:**
```
Main Menu
├── Select Playlists (browse server online - fetches from Plex)
├── Synced Playlists (offline cached content)
├── Settings (API backend selection, server config, test connection)
└── Sync Menu (download selected content)
```

**Technical Implementation:**
- Settings stored in `Application.Properties` (synced from Garmin Connect)
- On-watch menus fetch data from Plex API directly
- Browse server content via watch network connection
- User selects content on watch (text-based lists, no images during browse)
- Sync downloads selected content for offline playback

**Key Insight:** SubMusic proves you can build a fully functional Plex audiobook app WITHOUT a companion mobile app by using on-watch browsing.

---

## The Three Real Configuration Paths

### Option A: On-Watch Browsing (SubMusic Approach) ⭐ **RECOMMENDED**

**How it works:**
- Basic settings (server URL, token) via **Garmin Connect app settings** ✅ *Already done*
- Audiobook browsing and selection via **on-watch menu system**
- Watch connects directly to Plex API to fetch library
- User browses text-based lists on watch
- Selects audiobooks for download
- Triggers sync from watch

**What you need to build:**
1. **Library Browse UI** - menu view that fetches audiobook list from Plex
2. **Selection System** - mark audiobooks for sync (checkboxes or dedicated list)
3. **Sync Trigger** - button/menu option to start download
4. **Plex API Integration** - fetch library metadata on watch

**Architecture:**
```
PlexRunner App Flow:

1. User configures server/token in Garmin Connect app (already works)
   ↓
2. User opens PlexRunner menu on watch
   ↓
3. Watch fetches audiobook list from Plex API
   ↓
4. User browses text-based audiobook list
   ↓
5. User selects audiobooks to sync
   ↓
6. User triggers sync from watch menu
   ↓
7. SyncDelegate downloads (already implemented)
   ↓
8. Audiobooks appear in Music Player (already works)
```

**Pros:**
- ✅ No companion app required
- ✅ Self-contained solution
- ✅ Leverages existing Garmin Connect settings (already built)
- ✅ SubMusic proves this approach works in production
- ✅ Matches user's stated preference (avoid companion app)
- ✅ Simpler deployment (single app, not two)

**Cons:**
- ⚠️ Text-only browsing (no cover art during selection)
- ⚠️ Slower navigation than phone UI
- ⚠️ More watch app code to write
- ⚠️ Requires network connection on watch to browse

**Implementation Complexity:** Medium (3-5 days)

---

### Option B: Keep Companion App (Current Design)

**How it works:**
- Basic settings (server URL, token) via **Garmin Connect app settings**
- Audiobook browsing via **React Native companion mobile app**
- Companion app sends selection to watch via Garmin SDK
- Watch receives message and triggers sync

**What you have:**
- ✅ React Native companion app already designed (see `/companion/`)
- ✅ Message passing already implemented in PlexRunnerApp.mc
- ✅ SyncDelegate ready to receive syncList

**Architecture:**
```
Companion App Flow:

1. User installs PlexRunner watch app
   ↓
2. User installs PlexRunner Companion on phone (iOS/Android)
   ↓
3. User configures Plex in companion app
   ↓
4. User browses library on phone (rich UI, images)
   ↓
5. User selects audiobooks
   ↓
6. Companion sends message to watch via Connect IQ SDK
   ↓
7. Watch receives syncList message
   ↓
8. SyncDelegate downloads
   ↓
9. Audiobooks appear in Music Player
```

**Pros:**
- ✅ Best browsing UX (native mobile UI with images)
- ✅ Fast content discovery (phone performance)
- ✅ Rich metadata display
- ✅ Design already complete

**Cons:**
- ❌ Requires separate app installation (violates stated preference)
- ❌ Two codebases to maintain (MonkeyC + React Native)
- ❌ More complex setup for users
- ❌ Requires Garmin SDK integration
- ❌ Additional App Store/Play Store submissions

**Implementation Complexity:** High (7-10 days)

---

### Option C: Manual Configuration (Not Recommended)

**How it works:**
- Add a `syncList` property to Garmin Connect settings
- User manually enters comma-separated Plex rating keys
- User finds rating keys from Plex web interface
- Watch reads syncList from Application.Properties

**Settings addition:**
```xml
<setting propertyKey="@Properties.syncList" title="Audiobooks to Sync">
    <settingConfig type="alphaNumeric" />
</setting>
```

**Example user input:**
```
12345,67890,11223,44556
```

**Pros:**
- ✅ No companion app
- ✅ Minimal code changes
- ✅ Uses existing Garmin Connect settings

**Cons:**
- ❌ Terrible user experience
- ❌ Requires finding rating keys manually (advanced users only)
- ❌ Error-prone (typos, formatting)
- ❌ Not scalable (large libraries impossible)
- ❌ No metadata preview
- ❌ Professional app wouldn't use this approach

**Implementation Complexity:** Low (1 hour) but **NOT RECOMMENDED**

---

## Recommended Path: Option A Implementation Plan

Based on your stated preference to **avoid companion app** and SubMusic's proven approach, here's the detailed implementation plan:

### Phase 1: Fix Settings Access (Immediate)

**Goal:** Get your existing Garmin Connect settings working

**Tasks:**
1. **Build app with resources:**
   ```bash
   mkdir -p bin
   monkeyc --jungles monkey.jungle \
           --device fr970 \
           --output bin/PlexRunner.iq \
           --private-key developer_key \
           --release
   ```

2. **Install on watch:**
   - Sideload `bin/PlexRunner.iq` to watch
   - OR: Copy to `GARMIN/APPS/` via USB
   - OR: Use Garmin Express to sync

3. **Verify settings appear:**
   - Open Garmin Connect app on iPhone
   - Navigate: Menu → Garmin Devices → Forerunner 970 → Connect IQ Apps
   - Find PlexRunner → tap → should see **Settings**
   - Configure:
     - **Server URL:** `https://your-server.plex.direct:32400`
     - **Auth Token:** `your_X-Plex-Token`
     - **Library Name:** `Music` (or your audiobook library name)

4. **Test reading on watch:**
   - Settings should sync to watch via Application.Properties
   - Verify PlexConfig.getServerUrl() returns your URL
   - Verify PlexConfig.isAuthenticated() returns true

**Expected Result:** Settings accessible and syncing to watch ✅

---

### Phase 2: Add Library Browse Menu (Core Feature)

**Goal:** Fetch audiobook list from Plex and display on watch

**Files to create/modify:**

**2.1 Create LibraryBrowseView.mc**

```monkeyc
// Location: source/views/LibraryBrowseView.mc
using Toybox.WatchUi;
using Toybox.Communications;

class LibraryBrowseView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Browse Library"});
        Menu2.addItem(new WatchUi.MenuItem(
            "Loading...",
            null,
            :loading,
            {}
        ));

        // Fetch library on initialization
        fetchLibrary();
    }

    function fetchLibrary() {
        var url = PlexConfig.getServerUrl();
        var token = PlexConfig.getAuthToken();
        var library = PlexConfig.getLibraryName();

        if (url.length() == 0 || token.length() == 0) {
            // Show error - not configured
            Menu2.deleteItem(0);
            Menu2.addItem(new WatchUi.MenuItem(
                "Not Configured",
                "Set server in Garmin Connect",
                :error,
                {}
            ));
            return;
        }

        // Find library ID first
        var libraryUrl = url + "/library/sections?X-Plex-Token=" + token;
        Communications.makeWebRequest(
            libraryUrl,
            {},
            {:method => Communications.HTTP_REQUEST_METHOD_GET},
            method(:onLibrarySections)
        );
    }

    function onLibrarySections(responseCode, data) {
        if (responseCode != 200) {
            showError("Cannot connect to server");
            return;
        }

        // Parse library sections, find matching library name
        var libraryId = findLibraryId(data);
        if (libraryId == null) {
            showError("Library not found");
            return;
        }

        // Fetch audiobooks from library
        var url = PlexConfig.getServerUrl();
        var token = PlexConfig.getAuthToken();
        var audiobooksUrl = url + "/library/sections/" + libraryId +
                           "/all?type=9&X-Plex-Token=" + token;

        Communications.makeWebRequest(
            audiobooksUrl,
            {},
            {:method => Communications.HTTP_REQUEST_METHOD_GET},
            method(:onAudiobookList)
        );
    }

    function onAudiobookList(responseCode, data) {
        if (responseCode != 200) {
            showError("Failed to load audiobooks");
            return;
        }

        // Clear loading message
        Menu2.deleteItem(0);

        // Parse and add audiobooks to menu
        var audiobooks = parseAudiobooks(data);
        for (var i = 0; i < audiobooks.size(); i++) {
            var book = audiobooks[i];
            Menu2.addItem(new WatchUi.MenuItem(
                book[:title],
                book[:author],
                book[:ratingKey],
                {}
            ));
        }

        if (audiobooks.size() == 0) {
            Menu2.addItem(new WatchUi.MenuItem(
                "No Audiobooks",
                "Library is empty",
                :empty,
                {}
            ));
        }

        WatchUi.requestUpdate();
    }

    function parseAudiobooks(data) {
        // Parse XML response from Plex
        // Extract: ratingKey, title, grandparentTitle (author)
        var audiobooks = [];
        // TODO: XML parsing implementation
        return audiobooks;
    }

    function findLibraryId(data) {
        // Parse sections XML, find library matching libraryName
        // Return section ID
        // TODO: XML parsing implementation
        return null;
    }

    function showError(message) {
        Menu2.deleteItem(0);
        Menu2.addItem(new WatchUi.MenuItem(
            "Error",
            message,
            :error,
            {}
        ));
        WatchUi.requestUpdate();
    }
}
```

**2.2 Create LibraryBrowseDelegate.mc**

```monkeyc
// Location: source/views/LibraryBrowseDelegate.mc
using Toybox.WatchUi;

class LibraryBrowseDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var ratingKey = item.getId();

        if (ratingKey equals :loading || ratingKey equals :error ||
            ratingKey equals :empty) {
            return;
        }

        // Add to sync list
        SyncListManager.addToSyncList(ratingKey);

        // Show confirmation
        WatchUi.pushView(
            new WatchUi.Confirmation("Added to sync list"),
            new WatchUi.ConfirmationDelegate(method(:onConfirmation)),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function onConfirmation(result) {
        // Return to browse
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
```

**2.3 Create SyncListManager.mc**

```monkeyc
// Location: source/SyncListManager.mc
using Toybox.Application;
using Toybox.Lang;

module SyncListManager {

    function getSyncList() as Lang.Array {
        var syncList = Application.Storage.getValue("sync_list");
        if (syncList == null) {
            return [];
        }
        return syncList as Lang.Array;
    }

    function addToSyncList(ratingKey as Lang.String) {
        var syncList = getSyncList();

        // Check if already in list
        for (var i = 0; i < syncList.size(); i++) {
            if (syncList[i].equals(ratingKey)) {
                return; // Already added
            }
        }

        syncList.add(ratingKey);
        Application.Storage.setValue("sync_list", syncList);
    }

    function removeFromSyncList(ratingKey as Lang.String) {
        var syncList = getSyncList();
        var newList = [];

        for (var i = 0; i < syncList.size(); i++) {
            if (!syncList[i].equals(ratingKey)) {
                newList.add(syncList[i]);
            }
        }

        Application.Storage.setValue("sync_list", newList);
    }

    function clearSyncList() {
        Application.Storage.setValue("sync_list", []);
    }

    function getSyncListSize() as Lang.Number {
        return getSyncList().size();
    }
}
```

**2.4 Add main menu to PlexRunnerApp.mc**

```monkeyc
// Add to PlexRunnerApp.mc

function getGlanceView() as Array<GlanceView> or Null {
    return [new PlexRunnerGlanceView()];
}

function onSettingsChanged() {
    WatchUi.requestUpdate();
}

// Add initial view when app is opened (not as music provider)
function getInitialView() as Array<Views or InputDelegates>? {
    var menu = new WatchUi.Menu2({:title => "PlexRunner"});
    menu.addItem(new WatchUi.MenuItem(
        "Browse Library",
        "Select audiobooks",
        :browse,
        {}
    ));
    menu.addItem(new WatchUi.MenuItem(
        "Sync Queue",
        getSyncQueueSubtitle(),
        :queue,
        {}
    ));
    menu.addItem(new WatchUi.MenuItem(
        "Start Sync",
        "Download audiobooks",
        :sync,
        {}
    ));

    return [menu, new PlexRunnerMenuDelegate()];
}

function getSyncQueueSubtitle() {
    var count = SyncListManager.getSyncListSize();
    return count + " audiobook" + (count == 1 ? "" : "s");
}
```

---

### Phase 3: Add Sync Queue Management

**Goal:** View and manage audiobooks queued for sync

**3.1 Create SyncQueueView.mc**

```monkeyc
// Location: source/views/SyncQueueView.mc
using Toybox.WatchUi;

class SyncQueueView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Sync Queue"});
        loadQueue();
    }

    function loadQueue() {
        var syncList = SyncListManager.getSyncList();

        if (syncList.size() == 0) {
            Menu2.addItem(new WatchUi.MenuItem(
                "Queue Empty",
                "Browse library to add",
                :empty,
                {}
            ));
            return;
        }

        // Load metadata for each item in sync list
        for (var i = 0; i < syncList.size(); i++) {
            var ratingKey = syncList[i];
            // Try to load from storage if previously fetched
            var title = "Audiobook " + (i + 1);
            Menu2.addItem(new WatchUi.MenuItem(
                title,
                "Tap to remove",
                ratingKey,
                {}
            ));
        }
    }
}

class SyncQueueDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var ratingKey = item.getId();

        if (ratingKey equals :empty) {
            return;
        }

        // Remove from sync list
        SyncListManager.removeFromSyncList(ratingKey);

        // Show confirmation
        WatchUi.pushView(
            new WatchUi.Confirmation("Removed from queue"),
            new WatchUi.ConfirmationDelegate(method(:onConfirmation)),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function onConfirmation(result) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        // Re-push updated queue
        WatchUi.pushView(
            new SyncQueueView(),
            new SyncQueueDelegate(),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}
```

---

### Phase 4: Trigger Sync from Watch

**Goal:** Start SyncDelegate download from on-watch menu

**4.1 Research needed:**
- Can SyncDelegate be triggered programmatically from watch app?
- Or does it ONLY trigger from Garmin Connect sync request?
- Alternative: use Communications.makeWebRequest() directly instead of SyncDelegate

**4.2 Implementation approach:**

**Option 1: If SyncDelegate can be triggered:**
```monkeyc
function startSync() {
    var syncList = SyncListManager.getSyncList();
    Application.Properties.setValue("syncList", syncList);

    // Trigger SyncDelegate somehow
    // TODO: Research Communications.SyncDelegate trigger API
}
```

**Option 2: Direct download (bypass SyncDelegate):**
```monkeyc
// Create new DownloadManager.mc that uses Communications.makeWebRequest
// to download audiobooks directly, similar to SyncDelegate but triggered
// from watch instead of from Garmin Connect
```

This requires research into the SyncDelegate API and whether it can be triggered programmatically from the watch app itself.

---

### Phase 5: Polish and Testing

**5.1 Add error handling:**
- Network timeout messages
- Invalid server configuration
- Plex server unreachable
- Empty library handling

**5.2 Add progress indicators:**
- Loading spinner while fetching library
- Sync progress (if possible)
- Download status

**5.3 Add settings test function:**
- "Test Connection" button in main menu
- Validates server URL and token
- Shows success/failure message

**5.4 Update documentation:**
- README.md - remove companion app references
- Add on-watch browsing instructions
- Update NEXT_STEPS.md

---

## Summary: Your Path Forward

### Immediate Actions (Today)

1. **Fix settings access:**
   - Build app: `monkeyc --jungles monkey.jungle --device fr970 --output bin/PlexRunner.iq --private-key developer_key --release`
   - Install on watch
   - Access settings via Garmin Connect mobile app → Garmin Devices → FR970 → Connect IQ Apps → PlexRunner
   - Configure: Server URL, Auth Token, Library Name

2. **Verify settings work:**
   - Check that values sync to watch
   - Test PlexConfig module reads them correctly

### Next Development Phase (This Week)

3. **Implement Option A (on-watch browsing):**
   - Add LibraryBrowseView - fetch and display audiobooks
   - Add SyncListManager - manage queue
   - Add SyncQueueView - view/edit queue
   - Research SyncDelegate trigger mechanism
   - Add main menu UI

4. **Test complete flow:**
   - Browse library on watch
   - Select audiobooks
   - Trigger sync
   - Verify downloads
   - Play in Music Player

### Expected Timeline

- **Phase 1 (Settings fix):** 1 hour
- **Phase 2 (Browse UI):** 2 days
- **Phase 3 (Queue management):** 1 day
- **Phase 4 (Sync trigger):** 1-2 days (depends on API research)
- **Phase 5 (Polish):** 1 day

**Total: 5-6 days** for complete on-watch browsing implementation

---

## References

### SubMusic Key Findings
- File: `/home/user/plexrunner/docs/submusic-report1.md`
- File: `/home/user/plexrunner/docs/submusic-report2.md`
- Proves on-watch browsing works for Plex
- No companion app required
- Settings via Garmin Connect + menus via watch

### Garmin Documentation
- Audio Content Provider apps support settings via settings.xml
- Settings accessible through Garmin Connect mobile app
- Settings sync via Application.Properties
- Can also be accessed via long-press UP button on watch (if properly built)

### Current PlexRunner Files
- `/home/user/plexrunner/resources/properties/properties.xml` ✅
- `/home/user/plexrunner/resources/settings/settings.xml` ✅
- `/home/user/plexrunner/source/PlexConfig.mc` ✅
- `/home/user/plexrunner/source/SyncDelegate.mc` ✅ (needs trigger mechanism)

---

## Decision Point

**You asked to avoid the companion app.** Based on SubMusic's proven approach, this is entirely feasible.

**Recommendation:** Proceed with **Option A (On-Watch Browsing)**

This gives you:
- ✅ Self-contained single app
- ✅ Settings in Garmin Connect (already done)
- ✅ Browsing on watch (to be built)
- ✅ Proven approach (SubMusic does this)
- ✅ No separate mobile app deployment

**Next Step:** Build and install app to verify settings access, then begin Phase 2 implementation.
