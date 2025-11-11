# PlexRunner - Next Steps

**Current Status:** Core AudioContentProviderApp implementation complete and merged to main.

**Missing Feature:** On-watch browsing UI to select audiobooks for sync.

---

## The Problem

The current implementation expects audiobooks to be selected for sync via a `syncList` property that must be populated externally:

```monkeyc
// In SyncDelegate.mc line 32
mSyncList = Application.Properties.getValue("syncList");
```

**There is currently no way for users to:**
1. Browse their Plex audiobook library on the watch
2. Select which audiobooks to download
3. Trigger the sync process

**The README incorrectly states:** "Browse and select audiobooks from Plex library (via Garmin Connect)"

This is **not implemented**. The documentation assumed a companion mobile app would populate `syncList`, but we decided NOT to build a companion app.

---

## The Solution: Add On-Watch Browsing UI

We need to port the browsing UI from the `feature/audiobook-mvp` branch (the deprecated first attempt), but adapt it to work with the AudioContentProviderApp architecture.

### What Needs to Be Ported

From `feature/audiobook-mvp`, these views are needed:

1. **AudiobookListView.mc** - Browse audiobooks from Plex
2. **AudiobookDetailView.mc** - Show audiobook details and "Download" button
3. **MainMenuView.mc** - Entry point with "Browse Audiobooks" option

### What Needs to Be Changed

The ported UI must be adapted because:

**Old (audiobook-mvp):**
- Standalone app with custom playback
- Main menu is the app entry point
- Downloads triggered manually from detail view

**New (AudioContentProviderApp):**
- Extends native Music Player
- App has no "main" view (Music Player is the main UI)
- Need to provide browsing via optional configuration view
- Downloads trigger SyncDelegate

---

## Implementation Plan

### Phase 1: Create Browse Menu Structure

**Goal:** Add "Browse Audiobooks" menu accessible from watch.

**Tasks:**

1. **Create BrowseMenuView.mc**
   ```monkeyc
   // Entry point for browsing
   // Options: "All Audiobooks", "Continue Reading", "Collections"
   ```

2. **Hook up to PlexRunnerApp**
   ```monkeyc
   // PlexRunnerApp.mc
   function getInitialView() {
       return [new BrowseMenuView(), new BrowseMenuDelegate()];
   }
   ```

   **Note:** This may conflict with AudioContentProviderApp requirements. Need to test if `getInitialView()` is allowed.

   **Alternative:** Use `getSyncConfigurationView()` to show browse menu instead of sync status. This leverages the configuration view API we already have.

**Files to create:**
- `source/views/BrowseMenuView.mc`
- `source/views/BrowseMenuDelegate.mc`

**References:**
- `feature/audiobook-mvp:source/views/MainMenuView.mc` (adapt)

---

### Phase 2: Implement Audiobook List

**Goal:** Display list of audiobooks from Plex.

**Tasks:**

1. **Port AudiobookListView.mc**
   - Fetch audiobooks from Plex `/library/sections/{id}/all`
   - Display as scrollable list (title, author)
   - Handle loading/error states

2. **Create AudiobookListDelegate.mc**
   - Handle item selection → navigate to detail view

3. **Integrate with PlexApi**
   - Already exists, just need to call correct endpoints
   - Filter for audiobooks (music library items)

**Files to create:**
- `source/views/AudiobookListView.mc`
- `source/views/AudiobookListDelegate.mc`

**References:**
- `feature/audiobook-mvp:source/views/AudiobookListView.mc` (port with modifications)
- `feature/audiobook-mvp:source/views/AudiobookListDelegate.mc`

**Key Changes from MVP:**
- Remove playback-related code
- Focus only on browsing and selection

---

### Phase 3: Implement Detail View & Download Trigger

**Goal:** Show audiobook details and allow user to queue for download.

**Tasks:**

1. **Port AudiobookDetailView.mc**
   - Display: Title, Author, Duration, Chapters
   - Show "Download" or "Already Downloaded" status
   - Menu option: "Add to Download Queue"

2. **Create Download Queue Manager**
   ```monkeyc
   // DownloadQueue.mc
   module DownloadQueue {
       function addToQueue(ratingKey) {
           // Add to syncList property
           var current = Application.Properties.getValue("syncList") || [];
           current.add(ratingKey);
           Application.Properties.setValue("syncList", current);
       }

       function removeFromQueue(ratingKey) { ... }
       function getQueue() { ... }
   }
   ```

3. **Create Download Trigger UI**
   - "Start Download" button in menu
   - Calls SyncDelegate.onStartSync() when ready
   - Shows progress (already implemented in SyncDelegate)

**Files to create:**
- `source/views/AudiobookDetailView.mc`
- `source/views/AudiobookDetailDelegate.mc`
- `source/DownloadQueue.mc`

**References:**
- `feature/audiobook-mvp:source/views/AudiobookDetailView.mc` (port with modifications)

**Key Changes from MVP:**
- Remove playback buttons
- Add download queue functionality
- Integrate with SyncDelegate instead of custom download manager

---

### Phase 4: Optional Enhancements

**Continue Reading View:**
- Port ContinueReadingView to show audiobooks with saved positions
- Uses PositionTracker.getAllPositions() to find in-progress books

**Collections View:**
- Port CollectionsView to browse by Plex collections
- Useful for "Recently Added", "Unplayed", custom collections

**Download Queue View:**
- Show pending downloads before sync starts
- Allow removing items from queue
- Show total download size estimate

---

## Technical Considerations

### Architecture Constraint

**Problem:** AudioContentProviderApp may not support custom views outside of optional configuration views.

**Research Needed:**
- Can AudioContentProviderApp have `getInitialView()`?
- If not, must use configuration view methods
- May need to hijack `getSyncConfigurationView()` to show browse menu

**Test Approach:**
1. Try adding `getInitialView()` and compile
2. If fails, use `getSyncConfigurationView()` instead
3. Document limitation if neither works

### Integration Points

**SyncDelegate expects:**
```monkeyc
mSyncList = Application.Properties.getValue("syncList");
// Array of ratingKey strings
```

**BrowseUI must provide:**
```monkeyc
Application.Properties.setValue("syncList", ["12345", "67890"]);
```

**Trigger sync:**
```monkeyc
// From Browse UI, after adding to queue:
var app = Application.getApp();
var syncDelegate = app.getSyncDelegate();
syncDelegate.onStartSync(); // May need different trigger mechanism
```

### Data Flow

```
User Browse → Audiobook List View
             ↓
         Select Audiobook → Detail View
                           ↓
                       Add to Queue → DownloadQueue.addToQueue()
                                     ↓
                                 syncList property updated
                                     ↓
                              User triggers "Start Sync"
                                     ↓
                              SyncDelegate reads syncList
                                     ↓
                              Downloads audiobooks
                                     ↓
                              ContentIterator shows in Music Player
```

---

## Implementation Phases

### Minimal Viable Product (MVP)

**Goal:** Users can browse and download audiobooks.

**Includes:**
- ✅ Phase 1: Browse Menu
- ✅ Phase 2: Audiobook List
- ✅ Phase 3: Detail View + Download Queue
- ❌ Phase 4: Skip enhancements

**Estimated Effort:** 4-6 hours

**Outcome:** Fully functional audiobook app

---

### Enhanced Version

**Goal:** Full feature parity with Plex browsing.

**Includes:**
- ✅ All MVP phases
- ✅ Continue Reading view
- ✅ Collections browsing
- ✅ Download queue management

**Estimated Effort:** 8-10 hours

**Outcome:** Rich browsing experience matching Plex web UI

---

## Development Workflow

### Step 1: Create Feature Branch

```bash
git checkout main
git checkout -b feature/add-browsing-ui
```

### Step 2: Reference audiobook-mvp

```bash
# View MVP implementation for reference
git show feature/audiobook-mvp:source/views/AudiobookListView.mc

# DO NOT merge audiobook-mvp - it's deprecated
# Port code manually with modifications
```

### Step 3: Implement Phase by Phase

For each phase:
1. Create new files
2. Compile and test
3. Commit with clear message
4. Move to next phase

### Step 4: Update Documentation

When complete:
- Update README.md (remove "via Garmin Connect" lie)
- Update RELEASE_NOTES.md
- Document new UI flow

### Step 5: Merge to Main

```bash
git checkout main
git merge feature/add-browsing-ui --no-ff
git push origin main
```

---

## Testing Checklist

Before considering browsing complete, verify:

- [ ] Can browse audiobook library from watch
- [ ] Can view audiobook details (title, author, chapters)
- [ ] Can add audiobooks to download queue
- [ ] Can trigger sync from watch UI
- [ ] SyncDelegate receives correct syncList
- [ ] Downloads complete successfully
- [ ] Downloaded audiobooks appear in Music Player
- [ ] Can remove items from download queue
- [ ] Loading states work correctly
- [ ] Error messages display properly
- [ ] Works with empty library
- [ ] Works with large library (100+ audiobooks)

---

## Open Questions

1. **Can AudioContentProviderApp have getInitialView()?**
   - Need to test compilation
   - If not, must use configuration view approach

2. **How to trigger SyncDelegate from UI?**
   - SyncDelegate is triggered by Garmin Connect normally
   - May need alternative trigger mechanism for on-watch initiation
   - Research Communications.SyncDelegate API

3. **Should download queue persist?**
   - Currently using Application.Properties (syncs to phone)
   - Alternative: Application.Storage (local only)
   - Which is better for user experience?

4. **Configuration view integration?**
   - We have SyncConfigurationView not integrated (API signature issue)
   - Could we repurpose it as the browse menu entry point?
   - Would solve the view integration problem

---

## Success Criteria

**Browsing feature is complete when:**

✅ User can browse Plex audiobooks from watch (no phone needed)
✅ User can select audiobooks for download
✅ User can trigger sync from watch
✅ Downloads complete and audiobooks playable in Music Player
✅ Documentation accurately describes the feature
✅ No misleading claims about "companion app" or "Garmin Connect"

---

## Timeline Estimate

**Minimal Viable Product:**
- Phase 1: 1-2 hours
- Phase 2: 2-3 hours
- Phase 3: 1-2 hours
- Testing & docs: 1 hour
- **Total: 5-8 hours**

**Enhanced Version:**
- MVP: 5-8 hours
- Phase 4 enhancements: 3-4 hours
- **Total: 8-12 hours**

---

## Notes

- This work should happen in a NEW branch (`feature/add-browsing-ui`)
- Do NOT work in `feature/audiobook-mvp` (it's deprecated)
- Do NOT work directly in `main` (keep clean)
- Reference MVP code but port with modifications
- Test compilation after each phase
- Update documentation as you go

---

**Last Updated:** Nov 11, 2025
**Status:** Ready to implement
**Next Action:** Create `feature/add-browsing-ui` branch and start Phase 1
