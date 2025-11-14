# PlexRunner - Next Steps

**Last Updated:** 2025-11-14
**Current Status:** See STATUS.md for comprehensive project status

---

## Current Blocker: HTTP Code 0 Errors

The immediate priority is resolving network connectivity issues between the watch and Plex server.

### Problem

When PlexRunner tries to download audiobook metadata from Plex, it fails with HTTP Code 0:

```
Fetching metadata for audiobook: 9549
DEBUG: Server URL: http://192.168.10.10:32400
DEBUG: Auth token length: 20
DEBUG: Full URL: http://192.168.10.10:32400/library/metadata/9549
Failed to fetch metadata: 0
```

**HTTP Code 0** means the request failed before reaching the server - typically a network configuration issue.

### Potential Causes

1. **Watch not connected to WiFi**
   - Settings may not persist after sideloading
   - Need to verify watch WiFi connection

2. **Settings file not loading**
   - Manual settings file may not work the same as Garmin Connect settings
   - Watch might be using fallback values incorrectly

3. **Garmin network stack limitations**
   - May not support HTTP to local IPs
   - May require HTTPS even for local servers
   - May have firewall/security restrictions

4. **Plex server accessibility**
   - Server might not be listening on 192.168.10.10:32400
   - Firewall might block connections from watch

### Investigation Plan

**Step 1: Verify Watch WiFi (Most Likely)**
- Check watch WiFi settings after sideloading
- Confirm watch connected to same network as Plex server
- Try triggering WiFi reconnection

**Step 2: Test Simple HTTP Request**
- Create test endpoint that just returns "OK"
- Try fetching from watch to isolate Plex vs network issue
- This will confirm if watch can make any HTTP request

**Step 3: Test Different URLs**
- Try plain IP: `http://192.168.10.10:32400`
- Try hostname: `http://macbook-pro-2016.local:32400`
- Try plex.direct: `https://192-168-10-10.{token}.plex.direct:32400`
- See which (if any) works

**Step 4: Check Garmin Developer Forums**
- Search for "HTTP Code 0 Garmin"
- Look for similar network connectivity issues
- Check if there are special requirements for HTTP requests

**Step 5: Try Garmin Connect Sync (Not Sideload)**
- Install via Garmin Connect app instead of sideloading
- Settings file should load properly via Garmin Connect
- May resolve issues with manual setup

---

## After Code 0 is Resolved

Once the watch can successfully connect to Plex, the remaining work is straightforward:

### 1. Complete End-to-End Testing (1-2 days)

**Verify Core Functionality:**
- [ ] Download single audiobook chapter successfully
- [ ] Play audio in native Music Player
- [ ] Navigate between chapters (next/previous)
- [ ] Verify automatic chapter advancement
- [ ] Test position tracking saves locally
- [ ] Test position sync uploads to Plex

**Test Edge Cases:**
- [ ] Empty library handling
- [ ] Network disconnection during sync
- [ ] Low battery scenarios
- [ ] Multiple audiobooks synced
- [ ] Large audiobook (100+ chapters)

**Performance Testing:**
- [ ] Measure battery drain during playback
- [ ] Test storage usage with multiple audiobooks
- [ ] Verify sync speed acceptable for users

### 2. Documentation Updates (1 day)

**Update Existing Docs:**
- [ ] README.md - Fix media encoding description
- [ ] RELEASE_NOTES.md - Add v0.2.0 with companion app
- [ ] TESTING.md - Add results from end-to-end testing

**Create Missing Docs:**
- [ ] SIDELOADING.md - Manual testing procedure (for developers)
- [ ] TROUBLESHOOTING.md - Common issues and solutions
- [ ] USER_GUIDE.md - End-user instructions (if needed)

### 3. Prepare for Deployment (1-2 weeks)

**Garmin Connect IQ Store:**
- [ ] Create store listing assets
  - App screenshots (watch + companion)
  - Feature description
  - Privacy policy
- [ ] Test on additional watch models (if available)
- [ ] Submit app for Connect IQ Store review
- [ ] Address any feedback from Garmin review team

**Companion App Deployment:**
- [ ] Build production React Native app
- [ ] Create App Store listing (iOS)
  - Screenshots
  - Description
  - Privacy policy
- [ ] Create Play Store listing (Android)
  - Screenshots
  - Description
  - Privacy policy
- [ ] Submit for review
- [ ] Coordinate release dates

---

## Future Enhancements (Post-Launch)

These are nice-to-have features that can be added after initial release:

### Enhanced Media Support
- Detect audio format dynamically from Plex metadata
- Support additional formats (ADTS, WAV, etc.)
- Implement smart transcoding requests to Plex

### Improved Position Sync
- Better connectivity detection
- Retry logic for failed syncs
- Sync queue management
- Conflict resolution (if position changed on another device)

### On-Watch Configuration Views
- Integrate SyncConfigurationView (show sync progress)
- Integrate PlaybackConfigurationView (show now playing)
- Requires research into correct API signatures

### User Experience Improvements
- Progress indicators during download
- Better error messages
- Settings validation in companion app
- Download queue management

### Advanced Features
- Bookmarks/favorites
- Playback speed control
- Sleep timer
- Collections support

---

## Timeline Estimate

**Assuming Code 0 is resolved this week:**

| Phase | Duration | Target Date |
|-------|----------|-------------|
| Debug Code 0 | 1-3 days | Nov 15-17 |
| End-to-end testing | 1-2 days | Nov 18-19 |
| Documentation updates | 1 day | Nov 20 |
| Store submission prep | 3-5 days | Nov 21-25 |
| Review & approval | 1-2 weeks | Dec 2-9 |
| **Public Release** | - | **Mid-December 2025** |

**If Code 0 takes longer:** Add debugging time to all subsequent phases.

---

## How You Can Help

### If you're debugging Code 0:

1. Check watch WiFi settings after sideloading
2. Try different server URL formats (IP vs hostname)
3. Search Garmin forums for similar issues
4. Test with a simple HTTP endpoint (non-Plex)
5. Try installing via Garmin Connect instead of sideloading

### If you want to contribute:

1. **Test on different watch models**
   - We've only tested on Forerunner 970
   - Other watches may have different network behavior

2. **Improve error handling**
   - Better error messages for users
   - Retry logic for network failures
   - Graceful degradation when offline

3. **Enhance companion app**
   - Better loading states
   - Improved error handling
   - Additional Plex features (collections, filters)

---

## Questions to Answer

Before deployment, we need to answer:

1. **WiFi requirement:** Can watch connect to Plex over WiFi, or does it need cellular?
2. **HTTPS requirement:** Does watch require HTTPS, or will HTTP work?
3. **Settings file:** Will Garmin Connect settings work better than sideloaded settings?
4. **Network restrictions:** Are there firewall/security restrictions on Garmin watches?

---

## Success Criteria

The project is ready for public release when:

✅ Watch successfully downloads audiobooks from Plex
✅ Audio plays correctly in native Music Player
✅ Position tracking works (local + Plex sync)
✅ Companion app successfully triggers sync
✅ All documentation complete and accurate
✅ Tested on physical watch with real Plex server
✅ No critical bugs or crashes
✅ Reasonable battery life during playback

---

## Current Priority

**#1 Priority:** Resolve HTTP Code 0 network errors

Everything else is blocked until the watch can connect to Plex. Once that works, the rest should fall into place quickly.

---

**See STATUS.md for detailed current project status**
