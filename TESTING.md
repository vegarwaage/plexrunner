# PlexRunner End-to-End Testing Guide

Complete step-by-step instructions for testing PlexRunner watch app with companion mobile app.

## Prerequisites

Before starting, ensure you have:

- ✅ **Garmin Forerunner 970** (or compatible watch)
- ✅ **Garmin Connect app** installed on phone
- ✅ **Watch paired** to phone via Garmin Connect
- ✅ **Plex Media Server** running with audiobook library
- ✅ **Plex auth token** (see main README.md for how to get it)
- ✅ **iPhone or Android phone** for companion app

## Testing Options

You have two options for testing:

### Option A: Physical Watch (Recommended)
- Most realistic testing
- Tests actual Garmin SDK communication
- Requires USB connection to computer

### Option B: Simulator
- Faster iteration
- No watch required
- Limited Garmin SDK functionality

**This guide covers Option A (Physical Watch)**

---

## Part 1: Load Watch App

### Step 1.1: Connect Watch to Computer

1. Connect your Garmin Forerunner 970 to Mac via USB cable
2. Watch should appear as mounted volume in Finder
3. Verify connection:
   ```bash
   ls /Volumes/GARMIN/
   ```
   You should see folders like `GARMIN`, `NEWFILES`, etc.

### Step 1.2: Copy App to Watch

```bash
cd /Users/selwa/Developer/plexrunner
cp bin/PlexRunner.prg /Volumes/GARMIN/GARMIN/APPS/
```

### Step 1.3: Safely Eject and Reboot Watch

1. **Eject the watch** from Finder (⏏️ button)
2. **Disconnect USB cable**
3. **Reboot watch:**
   - Hold LIGHT/POWER button
   - Select "Power Off"
   - Power back on

### Step 1.4: Verify App Installation

1. From watch home screen, press UP button
2. Scroll through apps list
3. Look for **PlexRunner** app icon
4. If you see it, installation successful! ✅

---

## Part 2: Configure Plex Settings (Watch)

PlexRunner needs Plex server credentials to download audiobooks.

### Step 2.1: Open Garmin Connect App on Phone

1. Open Garmin Connect app
2. Tap **More** (bottom right)
3. Tap **Garmin Devices**
4. Select your **Forerunner 970**

### Step 2.2: Configure PlexRunner Settings

1. Scroll down to **Apps**
2. Find and tap **PlexRunner**
3. Tap **Settings** or **App Settings**
4. Enter the following:

   - **Plex Server URL:**
     ```
     https://your-plex-server:32400
     ```
     (Replace with your actual Plex server URL)

   - **Auth Token:**
     ```
     [your Plex auth token]
     ```
     (See main README.md for how to get this)

   - **Library Name:** (optional, default is "Music")
     ```
     Music
     ```

5. Tap **Save** or **Done**
6. Settings will sync to watch automatically

---

## Part 3: Install and Run Companion App

### Step 3.1: Install Dependencies

```bash
cd /Users/selwa/Developer/plexrunner/companion
npm install
```

### Step 3.2: Start Development Server

```bash
npm start
```

This opens the Expo development server with a QR code.

### Step 3.3: Install Expo Go on Phone

**iOS:**
1. Open App Store
2. Search for "Expo Go"
3. Install the app

**Android:**
1. Open Google Play Store
2. Search for "Expo Go"
3. Install the app

### Step 3.4: Load Companion App

**iOS:**
1. Open Camera app
2. Point at QR code in terminal
3. Tap notification to open in Expo Go

**Android:**
1. Open Expo Go app
2. Tap "Scan QR code"
3. Scan the QR code in terminal

The companion app should load on your phone.

---

## Part 4: Configure Companion App

### Step 4.1: Initial Setup

When you first open the app, you'll see the Setup screen.

1. **Plex Server URL:**
   ```
   https://your-plex-server:32400
   ```

2. **Auth Token:**
   ```
   [paste your auth token here]
   ```

3. **Library Name:** (optional)
   ```
   Music
   ```

4. Tap **Connect**

### Step 4.2: Verify Connection

- If successful: You'll be taken to the Library screen
- If error: Check server URL and auth token are correct

### Step 4.3: Grant Bluetooth Permissions (if prompted)

The companion app needs Bluetooth to communicate with your watch:

- **iOS:** Tap "Allow" when prompted
- **Android:** Tap "Allow" when prompted

---

## Part 5: Browse and Select Audiobooks

### Step 5.1: Browse Library

You should now see your Plex audiobooks:
- Cover art images
- Title and author
- Duration

### Step 5.2: Select Audiobooks

1. Tap on audiobooks you want to sync (checkbox appears)
2. Selected count shows at bottom
3. Select 1-3 audiobooks for initial testing

### Step 5.3: Check Watch Connection

Look at top right of screen:
- **Green dot + device name:** Watch is connected ✅
- **"No watch connected":** Garmin Connect isn't detecting watch

**If watch not connected:**
1. Ensure watch is paired in Garmin Connect app
2. Keep Garmin Connect app open in background
3. Restart companion app
4. Check Bluetooth is enabled

---

## Part 6: Sync to Watch

### Step 6.1: Send Sync List

1. With audiobooks selected, tap **"Sync to Watch"** button at bottom
2. Watch for status messages:
   - "Connecting..." - Finding watch
   - "Sending..." - Transmitting message
   - "Success!" - Message sent ✅

### Step 6.2: Verify Watch Received Message

On your watch:
1. Connect watch to computer via USB
2. Enable developer mode if not already enabled
3. View logs (if possible) to confirm message received

Or simply proceed to next step and check if sync starts.

---

## Part 7: Download Audiobooks on Watch

### Step 7.1: Trigger Sync from Watch

The sync won't start automatically. You need to trigger it:

**Option A: Via Garmin Connect (intended method)**
1. Open Garmin Connect app
2. Go to device → PlexRunner
3. Look for sync trigger option

**Option B: Manually (testing)**
The watch has received the syncList and stored it in Application.Properties.
The SyncDelegate will run when triggered by Garmin Connect's sync mechanism.

### Step 7.2: Monitor Sync Progress

Watch the watch screen for:
- Sync starting notification
- Progress indicators
- Completion message

This can take several minutes depending on audiobook size.

---

## Part 8: Verify and Play

### Step 8.1: Open Music Player on Watch

1. From watch home, press UP button
2. Scroll to **Music** app (native Garmin app)
3. Press START to open

### Step 8.2: Navigate to PlexRunner

1. Swipe up/down to find music providers
2. Look for **PlexRunner** section
3. Select it

### Step 8.3: Browse Downloaded Audiobooks

You should see:
- List of synced audiobooks
- Tap one to see chapters
- Tap a chapter to start playback

### Step 8.4: Test Playback

1. Select a chapter
2. Press START to play
3. Verify:
   - Audio plays correctly
   - Controls work (play/pause/skip)
   - Chapter advances automatically
   - Position tracking works

---

## Troubleshooting

### Watch App Not Appearing

**Problem:** PlexRunner doesn't show in apps list after copying

**Solutions:**
1. Verify .prg file copied to `/Volumes/GARMIN/GARMIN/APPS/`
2. Eject watch properly before disconnecting
3. Try rebooting watch 2-3 times
4. Check watch storage isn't full

### Companion App Can't Connect to Plex

**Problem:** "Connection failed" error in companion app

**Solutions:**
1. Verify Plex server URL includes `https://` and port
2. Test URL in browser: `https://your-server:32400/library/sections?X-Plex-Token=YOUR_TOKEN`
3. Ensure phone is on same network as Plex server (or server is publicly accessible)
4. Check auth token hasn't expired

### No Watch Connected in Companion App

**Problem:** Companion app shows "No watch connected"

**Solutions:**
1. Ensure watch is paired in Garmin Connect app
2. Keep Garmin Connect app running in background
3. Restart Garmin Connect app
4. Restart companion app
5. Check Bluetooth is enabled on phone
6. Try un-pairing and re-pairing watch

### Watch Doesn't Receive Message

**Problem:** Tapping "Sync to Watch" succeeds but watch doesn't get message

**Solutions:**
1. Verify PlexRunner app is running on watch
2. Check watch logs if possible
3. Ensure Garmin Connect SDK is functioning
4. Try sending message again
5. Restart watch and companion app

### Sync Doesn't Start on Watch

**Problem:** Watch has syncList but doesn't download audiobooks

**Solutions:**
1. SyncDelegate needs to be triggered by Garmin Connect sync mechanism
2. Try manually triggering sync from Garmin Connect app
3. Check watch has internet connectivity
4. Verify Plex server is accessible from watch

### Audio Doesn't Play

**Problem:** Audiobooks appear in Music Player but don't play

**Solutions:**
1. Check audio files downloaded successfully
2. Verify files are MP3 format
3. Check watch storage isn't full
4. Try re-syncing the audiobook

---

## Expected Results

### ✅ Successful Test

If everything works, you should see:

1. **Companion app:**
   - Connects to Plex successfully
   - Shows audiobooks with cover art
   - Detects watch connection
   - Sends message successfully

2. **Watch:**
   - Receives syncList message
   - Stores audiobook IDs
   - Downloads audiobooks when sync triggered
   - Shows audiobooks in Music Player
   - Plays audio correctly
   - Tracks playback position

3. **Position tracking:**
   - Positions saved locally on watch
   - Synced to Plex every 5 minutes (if connected)
   - Resume works correctly

---

## Next Steps After Successful Test

1. **Test with more audiobooks**
2. **Test resume playback** after stopping
3. **Test position sync to Plex** (check Plex web UI)
4. **Test offline playback** (airplane mode)
5. **Test battery impact** during playback
6. **Test chapter navigation** (next/previous)
7. **Build production version** of companion app

---

## Debug Mode

For more detailed logging during testing:

### Watch App Logs

Connect watch to simulator or use device logging tools to see System.println() output.

### Companion App Logs

Check Expo console for:
- Plex API calls
- Garmin SDK events
- Error messages
- State changes

---

## Clean Up After Testing

### Remove Test Data from Watch

If you need to start fresh:

1. Delete PlexRunner app from watch
2. Clear Application.Storage (requires developer tools)
3. Reinstall app

### Reset Companion App

Clear AsyncStorage:
1. Open Settings screen
2. Tap "Reconfigure"
3. Enter new Plex settings

---

## Getting Help

If you encounter issues not covered here:

1. Check main README.md
2. Check companion/README.md
3. Review design document: docs/plans/2025-11-11-companion-app-design.md
4. Check LIMITATIONS.md for known issues
5. Enable debug logging in both apps

---

**Good luck testing!** 🎧⌚

Report any issues or successful tests so we can improve the guide.
