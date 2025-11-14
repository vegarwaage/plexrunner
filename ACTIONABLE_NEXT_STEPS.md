# What to Do Right Now - PlexRunner Immediate Actions

**Context:** Your code is good. You just need to TEST it. Here's exactly what to do.

---

## ⚡ Quick Start (Today)

### Step 1: Compile the Project (30 minutes)

```bash
# Navigate to project
cd /home/user/plexrunner

# Try to build
monkeyc --jungles monkey.jungle --device fr970 --output bin/PlexRunner.prg --api-level 5.2.0
```

**Possible Outcomes:**

✅ **It compiles:**
- Great! Move to Step 2.

❌ **"monkeyc: command not found":**
- Install Connect IQ SDK
- Download from: https://developer.garmin.com/connect-iq/sdk/
- Or use Eclipse plugin
- Comeback to this step

❌ **Compilation errors:**
- Note the errors
- These are VALUABLE information
- Fix them one by one
- This is normal!

### Step 2: Get Your Plex Audiobook IDs (15 minutes)

```bash
# Replace with YOUR Plex details
SERVER="https://your-plex-server.com:32400"
TOKEN="your-auth-token"

# Get library sections
curl "$SERVER/library/sections?X-Plex-Token=$TOKEN" | jq '.'

# Find your audiobook library ID (e.g., 2)
LIBRARY_ID=2

# Get audiobooks
curl "$SERVER/library/sections/$LIBRARY_ID/all?X-Plex-Token=$TOKEN" | jq '.MediaContainer.Metadata[] | {title, ratingKey}'

# Pick ONE audiobook ratingKey for testing (e.g., "9549")
```

**Write down:**
- Your Plex server URL: _________________
- Your auth token: _________________
- One audiobook ratingKey: _________________

### Step 3: Test in Simulator (1 hour)

**Option A: If you have the simulator installed:**

```bash
# Launch simulator
simulator

# Load PlexRunner.prg
# File → Run Program → bin/PlexRunner.prg

# Open Debug Console
# Paste these commands (replace with YOUR values):
Application.Properties.setValue("serverUrl", "https://your-server:32400");
Application.Properties.setValue("authToken", "YOUR_TOKEN");
Application.Properties.setValue("libraryName", "Audiobooks");
Application.Storage.setValue("syncList", ["YOUR_RATINGKEY"]);

# Trigger sync from app UI
# Watch debug output
```

**Option B: If simulator won't work:**

Skip to device testing (Step 4)

### Step 4: Document What Happens (30 minutes)

**Create a simple test log:**

```markdown
## Test Run 2025-11-14

**Setup:**
- Plex Server: https://192.168.1.100:32400
- Audiobook: "The Hobbit" (ID: 12345)
- Device: Simulator / Forerunner 970

**Results:**
[Paste debug output here]

**What worked:**
-

**What failed:**
-

**Next steps:**
-
```

**Save as: `TEST_LOG.md`**

This is your progress tracker.

---

## 📋 This Week's Checklist

Copy this to a task manager or markdown file you check daily:

### Monday: Build & Setup
- [ ] Install Connect IQ SDK (if needed)
- [ ] Compile PlexRunner project
- [ ] Fix compilation errors (if any)
- [ ] Get Plex server info ready
- [ ] Get 1-3 audiobook ratingKeys

### Tuesday: Simulator Testing
- [ ] Launch simulator
- [ ] Load app
- [ ] Configure Plex settings
- [ ] Inject test syncList
- [ ] Trigger sync
- [ ] Document results

### Wednesday: Debug Issues
- [ ] Fix HTTP/network errors
- [ ] Fix metadata parsing errors
- [ ] Fix download errors
- [ ] Test with different audiobook formats

### Thursday: Playback Testing
- [ ] Verify audiobook appears in Music Player
- [ ] Test chapter playback
- [ ] Test chapter transitions
- [ ] Test position tracking

### Friday: Device Testing (if available)
- [ ] Deploy to Forerunner 970
- [ ] Configure via Garmin Connect
- [ ] Test sync over WiFi
- [ ] Test offline playback
- [ ] Test position sync

---

## 🎯 Focus Areas

### Priority 1: Core Sync (Must Work)
- SyncDelegate downloads audiobook
- Metadata parsed correctly
- Files stored successfully
- ContentRef IDs captured

### Priority 2: Playback (Must Work)
- Audiobook appears in Music Player
- Chapters playable
- Navigation works (next/previous)
- Position tracked

### Priority 3: Polish (Nice to Have)
- Error messages
- Progress indicators
- Configuration views
- Companion app

**Don't work on Priority 3 until Priority 1 and 2 are proven.**

---

## 🚫 What NOT to Do

### Don't: Research More
You have 17,000+ lines of documentation. You don't need more research.

### Don't: Redesign the Architecture
Your AudioContentProviderApp design is correct. Trust it.

### Don't: Build the Companion App Yet
Test the watch app first. Companion app can wait.

### Don't: Optimize Prematurely
Get it working first. Optimize later.

### Don't: Write More Plans
You have enough plans. Execute the existing ones.

---

## 🔥 When You Get Stuck

### Scenario 1: "It won't compile"

**Do this:**
1. Read the error message carefully
2. Google the specific error
3. Check Garmin forums
4. Fix one error at a time
5. Recompile

**Don't:**
- Give up after first error
- Assume the architecture is wrong
- Rewrite everything

### Scenario 2: "Sync fails with HTTP error"

**Do this:**
1. Test the URL in browser/curl
2. Check auth token is correct
3. Verify HTTPS vs HTTP
4. Check certificate validity
5. Try different audiobook

**Don't:**
- Assume Plex API is broken
- Switch to different architecture
- Abandon the approach

### Scenario 3: "Audiobook doesn't appear in Music Player"

**Do this:**
1. Check AudiobookStorage has data
2. Verify ContentRef IDs stored
3. Test ContentIterator.get()
4. Check debug logs for errors
5. Validate metadata structure

**Don't:**
- Blame Garmin SDK
- Assume media framework is broken
- Give up on AudioContentProviderApp

### Scenario 4: "I don't have a Forerunner 970"

**Do this:**
1. Test in simulator first
2. Use a different Garmin device you own
3. Borrow a device
4. Update jungle file for your device
5. Accept simulator limitations

**Don't:**
- Assume it won't work
- Stop development
- Buy a $750 watch just for testing

---

## 📞 Where to Get Help

### Garmin Developer Forums
- https://forums.garmin.com/developer/connect-iq/
- Search before posting
- Include code snippets and error messages
- Be specific about your issue

### Plex API Documentation
- https://www.plexopedia.com/plex-media-server/api/
- For official endpoints
- Check response formats

### Connect IQ Documentation
- https://developer.garmin.com/connect-iq/api-docs/
- For SDK reference
- Check device compatibility

### Your Own Documentation
- `garmin-documentation/` folder (10,310 lines of examples!)
- `LIMITATIONS.md` (known issues)
- `README.md` (architecture overview)

---

## 🎉 Success Looks Like

### End of Week 1

**Minimum Success:**
- Project compiles ✅
- Runs in simulator ✅
- Makes HTTP call to Plex ✅
- Gets SOME response (even if error) ✅

**Good Success:**
- Fetches audiobook metadata ✅
- Downloads at least one chapter ✅
- Stores ContentRef ID ✅
- Appears in simulator Music Player ✅

**Great Success:**
- Full audiobook downloads ✅
- Playback works in simulator ✅
- Chapters advance automatically ✅
- Position tracking works ✅

### End of Week 2

**Minimum Success:**
- Identified and fixed Week 1 errors ✅
- Improved error handling ✅
- Documented actual limitations ✅

**Good Success:**
- Tested on physical device ✅
- Confirmed sync works on WiFi ✅
- Offline playback validated ✅

**Great Success:**
- Position syncs to Plex ✅
- Multiple audiobooks work ✅
- Different formats supported (MP3, M4B) ✅

---

## 🔄 Daily Workflow

### Morning (Planning - 15 min)
1. Read yesterday's test log
2. Pick ONE thing to fix today
3. Write it down
4. Don't multitask

### Afternoon (Coding - 2-4 hours)
1. Work on that ONE thing
2. Make small changes
3. Test frequently
4. Document results

### Evening (Review - 15 min)
1. Update test log
2. Note blockers
3. Plan tomorrow's focus
4. Commit code if progress made

**Example Day:**

```
Monday Goal: Make project compile

9:00 AM - Check current build status
9:15 AM - Fix missing import errors
10:00 AM - Fix type signature errors
11:00 AM - Generate developer key
11:30 AM - SUCCESS: Project compiles!
12:00 PM - Commit: "fix: resolve compilation errors"
12:15 PM - Update TEST_LOG.md
12:30 PM - Plan: Tomorrow test in simulator
```

---

## 💡 Tips for Fast Progress

### 1. Work in Small Iterations

**Bad:**
- Spend 2 weeks writing companion app
- Then test everything at once
- Everything breaks
- Can't isolate issues

**Good:**
- Test sync with one audiobook
- Fix errors found
- Add second audiobook
- Fix new errors
- Repeat

### 2. Use Print Debugging

```monkeyc
// Add liberally:
System.println("DEBUG: About to fetch metadata for " + ratingKey);
System.println("DEBUG: Server URL is " + serverUrl);
System.println("DEBUG: Response code: " + responseCode);
System.println("DEBUG: Data is null: " + (data == null));
```

This is NOT bad practice during validation. Remove later.

### 3. Test with Real Data

**Bad:**
- Mock Plex responses
- Test with fake audiobooks
- Assume structure

**Good:**
- Use your actual Plex server
- Real audiobooks you own
- See actual API responses

### 4. Document Everything

**Every test, write down:**
- What you tried
- What happened
- What you learned
- What to try next

**Even failures are progress** if documented.

### 5. Ask for Help AFTER Trying

**Before asking on forums:**
- Try to solve it yourself (30 min)
- Google the error (15 min)
- Check documentation (15 min)
- Then ask with DETAILS

**Good forum post:**
```
Title: SyncDelegate HTTP request returns 0 on Forerunner 970

Environment:
- Device: Forerunner 970 (simulator)
- SDK: 4.1.6
- Plex: 1.32.5
- Server: Local network, valid HTTPS cert

Code:
[snippet of makeWebRequest call]

Error:
Response code 0, data is null

What I tried:
- Tested URL in browser: works
- Tested with curl: 200 OK
- Verified token: correct
- Tried HTTP instead: same result

Question: What does response code 0 mean in this context?
```

---

## 📊 Track Your Progress

### Create a Simple Kanban Board

**To Do:**
- Compile project
- Test in simulator
- Fix sync errors
- Test playback

**In Progress:**
- [Current task]

**Done:**
- [Completed tasks]

**Blocked:**
- [Waiting on X]

Move items as you work. Visible progress prevents "moving in circles" feeling.

---

## 🏁 The Finish Line

**You'll know you're done with Phase 1 when:**

1. You can select an audiobook on your phone/computer
2. It syncs to your watch
3. You can play it while running (no phone needed)
4. Position saves and restores
5. It works for someone else's Plex server

**Everything else is polish.**

---

## Remember

You're not stuck. You're not going in circles. **You're 62.5% done.**

You just need to:
1. Build it
2. Run it
3. Fix what breaks
4. Repeat

**Start with Step 1 today.**

Good luck! 🚀
