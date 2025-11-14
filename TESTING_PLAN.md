# PlexRunner Testing Plan - Get It Working This Week

**Goal:** Validate your existing code works before building more features.

---

## Phase 1: Build Validation (Day 1)

### Step 1: Install Build Tools (if needed)

```bash
# Check if SDK is installed
which monkeyc

# If not, install Connect IQ SDK
# Download from: https://developer.garmin.com/connect-iq/sdk/
```

### Step 2: Compile the Project

```bash
cd /path/to/plexrunner

# Find your device's SDK path
SDK_PATH="/Applications/ConnectIQ"  # macOS typical path

# Compile for Forerunner 970
monkeyc \
  --jungles monkey.jungle \
  --device fr970 \
  --output bin/PlexRunner.prg \
  --sdk $SDK_PATH \
  --api-level 5.2.0

# Expected output: "Build Succeeded"
```

### Step 3: Handle Compilation Errors

**If you get errors:**

1. **Missing developer_key:**
   ```bash
   # Generate key
   openssl genrsa -out developer_key 4096
   ```

2. **API signature errors:**
   - Note the exact error message
   - Check which file/line
   - This is valuable info (not a failure!)

3. **Type errors:**
   - Monkey C is picky about types
   - Fix one at a time

**Don't give up if it doesn't compile first try.** That's expected.

---

## Phase 2: Simulator Testing (Day 2-3)

### Step 1: Launch Simulator

```bash
# Option A: Command line
simulator

# Option B: VS Code
# Install "Monkey C" extension
# Press F5 to launch
```

### Step 2: Load Your App

```bash
# In simulator:
# File → Run Program → Select bin/PlexRunner.prg
```

### Step 3: Inject Test Data

**Open simulator debug console:**

```javascript
// Your Plex server details
var serverUrl = "https://your-plex-server.com:32400";
var authToken = "YOUR_ACTUAL_TOKEN";

// Set configuration
Application.Properties.setValue("serverUrl", serverUrl);
Application.Properties.setValue("authToken", authToken);
Application.Properties.setValue("libraryName", "Audiobooks");

// Get audiobook ratingKeys from Plex
// Visit: https://your-plex-server.com:32400/library/sections/X/all?X-Plex-Token=TOKEN
// Find ratingKey values

// Inject syncList with YOUR audiobook IDs
var syncList = ["12345", "67890"];  // Replace with real ratingKeys
Application.Storage.setValue("syncList", syncList);

// Verify
Application.Storage.getValue("syncList");  // Should print array
```

### Step 4: Trigger Sync

**In the simulator:**

1. Navigate to PlexRunner app
2. Trigger sync (check what UI element does this)
3. Watch debug console output

**What to look for:**

```
✅ GOOD:
"Starting sync with 2 audiobooks"
"Fetching metadata for audiobook: 12345"
"DEBUG: Server URL: https://..."
"Metadata received for: 12345"
"Found 10 chapters, starting download"
"Chapter 1 downloaded successfully"

❌ BAD:
"Failed to fetch metadata: 401" → Auth token wrong
"Failed to fetch metadata: 0" → Server unreachable
"Invalid metadata response" → Plex structure different
"Download failed: HTTP 404" → Part key incorrect
```

### Step 5: Debug Plex API Calls

**If metadata fetch fails:**

```bash
# Test the actual HTTP call outside the watch
curl "https://your-plex-server.com:32400/library/metadata/12345?X-Plex-Token=TOKEN"

# Expected response:
{
  "MediaContainer": {
    "Metadata": [{
      "ratingKey": "12345",
      "title": "Book Title",
      "parentTitle": "Author Name",
      "key": "/library/metadata/12345/children",
      ...
    }]
  }
}
```

**If children fetch fails:**

```bash
# Get the children
curl "https://your-plex-server.com:32400/library/metadata/12345/children?X-Plex-Token=TOKEN"

# Check the structure matches what SyncDelegate expects
```

**Common Issues:**

1. **Server URL has wrong format**
   - ✅ `https://192.168.1.100:32400`
   - ✅ `https://abc-def-ghi.plex.direct:32400`
   - ❌ `https://192.168.1.100` (missing port)
   - ❌ `192.168.1.100:32400` (missing https://)

2. **Auth token is wrong**
   - Get from: `https://app.plex.tv/desktop/#!/settings/account`
   - Or: Browser dev tools → Network → any Plex request → Headers

3. **Library structure different**
   - Your Plex might organize audiobooks differently
   - Check actual JSON structure
   - Might need to adjust SyncDelegate parsing

---

## Phase 3: Download Testing (Day 3-4)

### Step 1: Monitor Download Progress

**Watch for:**

```
"Downloading chapter 1/10"
"File format: mp3"
"Using encoding: 1"  // Media.ENCODING_MP3
"Chapter 1 downloaded successfully"
```

### Step 2: Verify Content Storage

```javascript
// In simulator console
var audiobooks = AudiobookStorage.getAudiobooks();
audiobooks;  // Should show array with your audiobook

var tracks = AudiobookStorage.getTracks("12345");
tracks;  // Should show array of chapters with refId values
```

### Step 3: Check ContentIterator

```javascript
// Create iterator
var iterator = new ContentIterator();

// Get first chapter
var content = iterator.get();
content;  // Should be Media.Content object

// Try next
var next = iterator.next();
next;  // Should be second chapter
```

### Step 4: Test Playback

**In simulator Music Player:**

1. Navigate to PlexRunner provider
2. Should see audiobook title
3. Select audiobook
4. Should see chapter list
5. Select chapter
6. Press play

**Watch debug output:**

```
"Song Event (Start): [refId] at position 0"
"Chapter started for audiobook: 12345"
```

---

## Phase 4: Real Device Testing (Day 5)

### Step 1: Deploy to Watch

```bash
# Connect watch via USB
# Compile for your device
monkeyc --device fr970 --output bin/PlexRunner.prg ...

# Copy to watch
# Watch appears as USB device
# Copy .prg to GARMIN/Apps folder
```

### Step 2: Configure on Watch

**Using Garmin Connect:**

1. Open Garmin Connect app on phone
2. Go to device settings
3. Find PlexRunner
4. Configure:
   - Server URL
   - Auth Token
   - Library Name

### Step 3: Test Sync on Real WiFi

**On the watch:**

1. Ensure WiFi connected
2. Open PlexRunner
3. Trigger sync
4. Wait (this will be SLOW on real WiFi)

**Expected:**

- Sync can take 5-20 minutes for one audiobook
- Watch will get hot (normal)
- Battery will drain (normal during sync)

### Step 4: Test Offline Playback

1. Disconnect from WiFi
2. Open Music Player
3. Navigate to PlexRunner
4. Play audiobook
5. Verify chapters advance automatically

---

## Phase 5: Position Sync Testing (Day 6)

### Step 1: Monitor Position Updates

```javascript
// In simulator/device logs
"Chapter started for audiobook: 12345"
"Playback paused"
"Playback stopped"
```

### Step 2: Verify Local Position Storage

```javascript
var positions = Application.Storage.getValue("positions");
positions;  // Should have entry for ratingKey

positions["12345"];  // Should show current position
```

### Step 3: Test Plex Timeline Sync

**Watch debug output:**

```
"Syncing positions to Plex..."
"Syncing position for book 12345: 150000ms"
```

**Verify on Plex:**

1. Open Plex web interface
2. Go to your audiobook
3. Check playback position
4. Should match watch position (within sync interval)

### Step 4: Test Position Restore

1. Play audiobook to middle of chapter
2. Stop playback
3. Close app
4. Reopen app
5. Resume playback
6. Should start from saved position

---

## Common Issues and Solutions

### Issue 1: "Failed to fetch metadata: 0"

**Possible Causes:**

1. Server URL wrong
2. Network unreachable
3. Certificate invalid (HTTPS)
4. Firewall blocking

**Solutions:**

```bash
# Test from computer
curl -v "https://your-plex-server:32400/library/metadata/12345?X-Plex-Token=TOKEN"

# Check:
- Does it connect?
- What's the HTTP response code?
- Is certificate valid?
- Try HTTP instead (temporarily)
```

**In code:**

Check `PlexApi.mc` - does it handle HTTP vs HTTPS correctly?

### Issue 2: "Invalid metadata response"

**Possible Causes:**

1. Plex response structure different
2. Audiobook vs Music library
3. Custom metadata fields

**Solutions:**

1. Get actual JSON from Plex
2. Compare to what `SyncDelegate.onAudiobookMetadata()` expects
3. Adjust parsing code

**Example:**

```monkeyc
// SyncDelegate.mc:135
var author = audiobook["parentTitle"];

// But your Plex might use:
var author = audiobook["grandparentTitle"];  // Artist level
```

### Issue 3: "Download failed: HTTP 404"

**Possible Causes:**

1. Part key incorrect
2. File path wrong on Plex
3. Permissions issue

**Solutions:**

```bash
# Test the part URL directly
curl "https://your-plex-server:32400/library/parts/123/file.mp3?X-Plex-Token=TOKEN"

# Should download actual audio file
# If 404, check Plex library file paths
```

### Issue 4: Chapters don't play

**Possible Causes:**

1. ContentRef IDs not stored
2. ContentIterator logic wrong
3. Audio encoding incompatible

**Debug:**

```javascript
// Check stored tracks
var tracks = AudiobookStorage.getTracks("12345");
tracks[0][:refId];  // Should be a value, not null

// Check content retrieval
var ref = new Media.ContentRef(tracks[0][:refId], Media.CONTENT_TYPE_AUDIO);
var content = Media.getCachedContentObj(ref);
content;  // Should be Content object, not null
```

### Issue 5: Position doesn't sync to Plex

**Possible Causes:**

1. Network not available
2. Timeline API endpoint wrong
3. Plex rejects position update

**Debug:**

```bash
# Test Plex Timeline API manually
curl -X POST "https://your-plex-server:32400/:/timeline?ratingKey=12345&state=playing&time=150000&duration=3600000&X-Plex-Token=TOKEN"

# Should return 200 OK
# Check Plex web UI - position should update
```

**In code:**

Check `PositionSync.mc` - verify Timeline API parameters.

---

## Test Checklist

### Build Phase

- [ ] Project compiles without errors
- [ ] .prg file generated successfully
- [ ] Developer key created
- [ ] Target device specified correctly

### Simulator Phase

- [ ] App launches in simulator
- [ ] Properties can be set via console
- [ ] SyncDelegate can be triggered
- [ ] Debug output appears in console
- [ ] Metadata fetch succeeds
- [ ] Download starts (even if fails)

### Plex Integration Phase

- [ ] Server URL reachable from simulator/watch
- [ ] Auth token valid
- [ ] Metadata request returns 200
- [ ] Children request returns tracks
- [ ] Audio file download returns 200
- [ ] ContentRef ID stored successfully

### Playback Phase

- [ ] Audiobook appears in Music Player
- [ ] Chapters listed correctly
- [ ] Playback starts when selected
- [ ] Position tracked during playback
- [ ] Next chapter advances automatically
- [ ] Previous chapter goes back

### Position Sync Phase

- [ ] Position saved locally
- [ ] Position syncs to Plex (when online)
- [ ] Position restored after app restart
- [ ] Position visible in Plex web UI

### Device Phase

- [ ] App installs on physical watch
- [ ] Settings configurable via Garmin Connect
- [ ] Sync works over watch WiFi
- [ ] Offline playback works
- [ ] Battery life acceptable

---

## Success Metrics

**You'll know it's working when:**

1. You see this in logs:
   ```
   Starting sync with 1 audiobooks
   Fetching metadata for audiobook: [ID]
   Metadata received
   Found [N] chapters, starting download
   Chapter 1 downloaded successfully
   Chapter 2 downloaded successfully
   ...
   All chapters downloaded for audiobook
   Sync complete!
   ```

2. In Music Player:
   - PlexRunner appears as audio provider
   - Your audiobook title shows up
   - Chapters are listed
   - Playback works

3. On Plex web:
   - Playback position updates
   - Matches watch position (within 5 minutes)

---

## What to Document

**As you test, record:**

### Success Case

```markdown
## Test: Basic Sync and Playback

**Date:** 2025-11-14
**Environment:** Simulator / Forerunner 970
**Plex Version:** 1.32.5.7349
**Audiobook:** "The Hobbit" (ratingKey: 12345)

**Steps:**
1. Set serverUrl to https://192.168.1.100:32400
2. Set authToken to [redacted]
3. Injected syncList = ["12345"]
4. Triggered sync
5. Waited 15 minutes
6. Playback tested

**Results:**
✅ Metadata fetched successfully
✅ 12 chapters downloaded
✅ Audiobook appeared in Music Player
✅ Playback worked
✅ Chapter transitions automatic
✅ Position saved

**Issues:** None

**Logs:** [attach or inline]
```

### Failure Case

```markdown
## Test: Sync with M4B Audiobook

**Date:** 2025-11-14
**Audiobook:** "Dune" (ratingKey: 67890, format: M4B)

**Steps:**
1. Same config as above
2. Injected syncList = ["67890"]
3. Triggered sync

**Results:**
❌ Download failed: HTTP 406

**Error Logs:**
```
Download failed for chapter 1: HTTP 406
Media encoding: ENCODING_MP3
```

**Analysis:**
- File is M4B, but SyncDelegate used ENCODING_MP3
- Need to detect format and use ENCODING_M4A
- See line 291 in SyncDelegate.mc

**Fix Applied:**
Updated getMediaEncoding() to handle M4B format

**Retest:** ✅ Passed after fix
```

---

## Tools and Resources

### Plex API Testing

```bash
# Get your library sections
curl "https://SERVER:32400/library/sections?X-Plex-Token=TOKEN"

# Get audiobooks (replace {id} with your audiobook library section ID)
curl "https://SERVER:32400/library/sections/{id}/all?X-Plex-Token=TOKEN"

# Get specific audiobook metadata
curl "https://SERVER:32400/library/metadata/{ratingKey}?X-Plex-Token=TOKEN"

# Get audiobook tracks
curl "https://SERVER:32400/library/metadata/{ratingKey}/children?X-Plex-Token=TOKEN"

# Download a file
curl "https://SERVER:32400/library/parts/{id}/file.mp3?X-Plex-Token=TOKEN" -o test.mp3

# Test timeline update
curl -X POST "https://SERVER:32400/:/timeline?ratingKey={ratingKey}&state=playing&time=150000&duration=3600000&X-Plex-Token=TOKEN"
```

### Python Test Script

```python
#!/usr/bin/env python3
"""
PlexRunner Test Utility
Fetches audiobooks from Plex and generates test syncList
"""

import requests
import json
import sys

def get_audiobooks(server_url, token):
    """Fetch audiobooks from Plex"""
    # Get library sections
    r = requests.get(f"{server_url}/library/sections",
                    params={"X-Plex-Token": token})
    sections = r.json()["MediaContainer"]["Directory"]

    # Find audiobook library (or music library with audiobooks)
    for section in sections:
        if section["type"] in ["artist", "show"]:
            print(f"Found library: {section['title']} (ID: {section['key']})")

            # Get items in library
            r = requests.get(f"{server_url}/library/sections/{section['key']}/all",
                           params={"X-Plex-Token": token})
            items = r.json()["MediaContainer"]["Metadata"]

            audiobooks = []
            for item in items:
                audiobooks.append({
                    "ratingKey": item["ratingKey"],
                    "title": item["title"],
                    "author": item.get("parentTitle", "Unknown")
                })

            return audiobooks

    return []

def main():
    if len(sys.argv) < 3:
        print("Usage: python test_plex.py SERVER_URL AUTH_TOKEN")
        sys.exit(1)

    server_url = sys.argv[1]
    token = sys.argv[2]

    print(f"Fetching audiobooks from {server_url}...")
    audiobooks = get_audiobooks(server_url, token)

    print(f"\nFound {len(audiobooks)} audiobooks:\n")
    for i, book in enumerate(audiobooks, 1):
        print(f"{i}. {book['title']} by {book['author']} (ID: {book['ratingKey']})")

    print("\nSelect audiobooks to sync (comma-separated numbers):")
    selection = input("> ")

    selected_ids = []
    for num in selection.split(","):
        idx = int(num.strip()) - 1
        if 0 <= idx < len(audiobooks):
            selected_ids.append(audiobooks[idx]["ratingKey"])

    print("\n--- Simulator Console Commands ---")
    print(f'Application.Storage.setValue("syncList", {json.dumps(selected_ids)});')
    print("\n--- For your code (hardcoded) ---")
    print(f'syncList = {json.dumps(selected_ids)};')

if __name__ == "__main__":
    main()
```

Save as `tools/test_plex.py`, then:

```bash
python tools/test_plex.py "https://your-server:32400" "YOUR_TOKEN"
```

---

## Next Steps After Testing

**Once basic sync works:**

1. **Fix issues found in testing**
   - HTTP vs HTTPS handling
   - Format detection (MP3 vs M4B)
   - Error messages for users
   - Storage full handling

2. **Optimize sync flow**
   - Progress indicators
   - Pause/resume support
   - Selective chapter download
   - Quality settings

3. **Build companion app** (if still needed)
   - Now you know the exact API contract
   - You've validated the watch app works
   - Companion just needs to populate syncList

4. **Polish user experience**
   - Better error messages
   - Sync status display
   - Storage management
   - Settings validation

5. **Documentation**
   - User guide
   - Setup instructions
   - Troubleshooting
   - Known limitations

**But all of that comes AFTER you've proven the core functionality works.**

---

**Remember:** The goal is to get ONE audiobook playing from YOUR Plex server on the watch. Not perfect. Not polished. Just working. Everything else builds from there.
