# PlexRunner - Current Project Status

**Last Updated:** 2025-11-14
**Version:** 0.2.0-dev
**Branch:** main

---

## Overview

PlexRunner is a Garmin Connect IQ AudioContentProviderApp that streams audiobooks from Plex to Garmin watches. The core implementation is complete, but physical watch testing is blocked by network connectivity issues.

---

## Completed Features ✅

### Core Watch App
- ✅ AudioContentProviderApp architecture
- ✅ ContentIterator for audiobook → chapter navigation
- ✅ SyncDelegate for audiobook downloads from Plex
- ✅ ContentDelegate for playback callbacks
- ✅ Position tracking (local storage)
- ✅ Opportunistic position sync to Plex Timeline API
- ✅ Auto-sync on app start (for testing)
- ✅ Dynamic media format detection (MP3/M4A/M4B/MP4)

### Testing & Deployment Approach
- ✅ Sideloading via USB for development testing
- ✅ Manual settings file creation for sideloaded apps
- ✅ Auto-sync on app start (for testing convenience)
- ⚠️ Garmin Connect deployment approach (future)

### Configuration
- ✅ Settings schema for Garmin Connect app
- ✅ PlexConfig module for reading settings
- ✅ Fallback values for testing (HTTP instead of HTTPS)
- ✅ Manual settings file support for sideloading

### Storage & Data
- ✅ AudiobookStorage module for metadata persistence
- ✅ PositionTracker for local playback positions
- ✅ PositionSync for uploading to Plex
- ✅ Efficient ContentRef management

---

## In Progress ⚠️

### Physical Watch Testing
**Status:** Blocked by network connectivity issues

**Current Approach:**
- Sideloading PlexRunner.prg directly to watch via USB
- Manual settings file at `/tmp/7362c2a0f1805be30d6fdfa43b1178bb.set`
- Using OpenMTP for reliable MTP file transfer

**Blocker:**
- HTTP Code 0 errors when watch tries to fetch metadata from Plex
- Settings file may not be loading on watch (using fallback values)
- Watch WiFi connectivity to local Plex server unconfirmed

**Next Steps:**
1. Verify watch WiFi connectivity (ping test)
2. Test plain HTTP URL vs plex.direct HTTPS
3. Confirm settings file loads on physical watch
4. Check if Garmin network stack requires special headers

---

## Known Issues ❌

### Critical: HTTP Code 0 Errors
**Symptom:** "Failed to fetch audiobook metadata (code 0)"

**What we know:**
- Code 0 = request fails before reaching server
- Happens on both physical watch and simulator
- PlexConfig returns correct URL and auth token (verified with debug logging)
- Full URL constructed properly: `http://192.168.10.10:32400/library/metadata/9549`

**Potential causes:**
- Settings file not loading (watch using fallback values)
- Watch WiFi not connected to local network
- Garmin network stack doesn't support HTTP to local IPs
- Watch requires HTTPS but can't handle plex.direct DNS/certificates

**Current workaround:**
- Using plain HTTP fallback (`http://192.168.10.10:32400`)
- Added debug logging to diagnose issue
- Testing continues with simulator (limited)

### Minor: Simulator Network Limitations
- Simulator cannot make real HTTP requests
- All network testing must happen on physical watch
- Slows iteration for network-related debugging

---

## Recent Changes (Since v0.1.0)

**Commit 4a3dd9c (Nov 14):** HTTP fallback and debug logging
- Changed PlexConfig fallback from plex.direct HTTPS to plain HTTP
- Added debug logging showing server URL, token length, full URL
- Fixed null/empty string check in PlexConfig getters

**Commit 3bc95b0 (Nov 12):** Companion app implementation
- Complete React Native companion app
- Plex library browsing with cover art
- Garmin SDK integration for sending sync list to watch
- Bluetooth device detection

**Commit 8da9491 (Nov 11):** Core implementation merge
- AudioContentProviderApp complete
- SyncDelegate, ContentDelegate, ContentIterator
- Position tracking and sync
- Media format detection (MP3/M4A/M4B/MP4)

---

## Testing Status

### Compilation ✅
- Builds successfully with zero errors/warnings
- Target: Garmin Forerunner 970
- SDK: Connect IQ 8.3.0

### Simulator Testing ⚠️
- App launches successfully
- Auto-sync triggers correctly
- PlexConfig fallback values load
- Network requests fail (expected - no real network in simulator)

### Physical Watch Testing ❌
- App sideloads successfully
- App appears in watch app list
- **Blocked:** Code 0 errors prevent metadata download
- Cannot complete end-to-end test until resolved

### Companion App Testing ✅
- Connects to Plex server successfully
- Browses library with cover art
- Detects Garmin watch via Bluetooth
- Sends sync message to watch
- All UI flows working

---

## What Works

1. **Companion App → Watch Communication** ✅
   - Bluetooth detection works
   - Message sending succeeds
   - Watch should receive sync list (untested due to Code 0)

2. **Code Architecture** ✅
   - All modules compile cleanly
   - Type checking passes
   - No runtime errors in simulator

3. **Plex Integration (from companion)** ✅
   - Companion app successfully calls Plex API
   - Cover art downloads
   - Metadata parsing works

## What Doesn't Work

1. **Watch → Plex Communication** ❌
   - HTTP Code 0 errors
   - Cannot fetch audiobook metadata
   - Cannot download audio files
   - Blocks all testing

2. **Settings File Loading** ❓
   - Unknown if settings file loads on real watch
   - Simulator confirms fallback values work
   - Need physical watch debug logging to confirm

3. **End-to-End Workflow** ❌
   - Cannot test sync workflow
   - Cannot test playback
   - Cannot test position tracking
   - All blocked by Code 0

---

## Next Milestones

### Immediate: Resolve Code 0 Errors
**Goal:** Get watch to successfully connect to Plex

**Tasks:**
- [ ] Verify watch WiFi connectivity to local network
- [ ] Test HTTP request to simple endpoint (not Plex)
- [ ] Try different server URLs (IP vs hostname)
- [ ] Check Garmin network stack requirements
- [ ] Review Garmin forums for HTTP Code 0 solutions

**Estimated:** 1-2 days of debugging

### Short-term: Complete End-to-End Test
**Goal:** Verify full workflow on physical watch

**Tasks:**
- [ ] Successfully download 1 audiobook chapter
- [ ] Play audio in Music Player
- [ ] Verify position tracking
- [ ] Test position sync to Plex
- [ ] Monitor battery impact

**Estimated:** 1 day (after Code 0 resolved)

### Medium-term: Deploy to Garmin Connect IQ Store
**Goal:** Public release

**Tasks:**
- [ ] Complete testing on multiple watch models
- [ ] Create store listing assets (screenshots, description)
- [ ] Submit to Connect IQ Store for approval
- [ ] Deploy companion app to App Store / Play Store

**Estimated:** 1-2 weeks (after testing complete)

---

## Development Environment

**macOS Setup:**
- Connect IQ SDK 8.3.0
- Monkey C compiler
- OpenMTP for MTP file transfer
- Physical Garmin Forerunner 970

**Companion App:**
- React Native / Expo
- Node.js development server
- iOS/Android testing via Expo Go

---

## How to Help

If you want to contribute to debugging:

1. **Test on your Garmin watch**
   - Sideload bin/PlexRunner.prg
   - Copy settings file to watch
   - Report if you get Code 0 or different error

2. **Review network code**
   - Check source/PlexConfig.mc
   - Check source/SyncDelegate.mc (lines 85-107)
   - Suggest alternative approaches

3. **Check Garmin forums**
   - Search for "HTTP Code 0"
   - Look for network connectivity solutions
   - Share relevant findings

---

## Project Health

**Code Quality:** ✅ Excellent
- Clean architecture
- Well-documented modules
- Type-safe throughout

**Documentation:** ⚠️ Needs updates
- README.md mostly accurate
- NEXT_STEPS.md obsolete (being replaced)
- RELEASE_NOTES.md outdated

**Testing:** ❌ Blocked
- Unit testing not feasible (Connect IQ limitations)
- Integration testing blocked by Code 0
- Companion app tested successfully

**Deployment:** ⏸️ On hold
- Cannot deploy until testing complete
- Code 0 must be resolved first

---

## Summary

**What's working:** Core architecture, companion app, compilation
**What's blocked:** Physical watch testing due to HTTP Code 0 errors
**Next action:** Debug network connectivity between watch and Plex server

The project is ~90% complete. Once the Code 0 network issue is resolved, we can complete end-to-end testing and prepare for deployment.
