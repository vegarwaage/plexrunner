# ⚠️ THIS BRANCH IS DEPRECATED - DO NOT USE ⚠️

## **NEVER MERGE THIS BRANCH**

This branch represents the **FIRST ATTEMPT** at PlexRunner implementation (Nov 9-11, 2025 early).

**It was abandoned because the architecture is fundamentally incompatible with Garmin's audio system.**

---

## Why This Branch Exists

This branch is kept **for historical reference only** to document:
1. The initial approach we tried
2. Why it didn't work
3. What we learned that led to the correct implementation

## What's Wrong With This Branch

### ❌ Architectural Problems

**Fatal Flaw:** Built as a standalone WatchApp with custom audio playback

Garmin Connect IQ **does not support** custom audio playback in standalone apps:
- No access to audio hardware
- No media player APIs for apps
- No way to play audio files directly
- Would require building entire audio system from scratch
- Battery inefficient
- Incompatible with native controls

### ❌ What This Branch Contains

- Custom UI implementation (main menu, settings, browsing, detail views)
- On-watch PIN authentication flow
- Manual download queue management
- Custom audiobook browser with collections
- Position tracking (this part was good and was reused)

**All of this UI is unusable** because there's no way to actually play the audiobooks.

## The Correct Implementation

**Branch:** `feature/audio-provider` (merged to `main` on Nov 11, 2025)

**Architecture:** AudioContentProviderApp (extends Garmin's native Music Player)

**Why It's Correct:**
- Integrates with native Music Player (proper audio support)
- Uses Garmin's ContentIterator/ContentDelegate pattern
- Battery efficient
- Native playback controls
- Proper audio session management

## The Pivot Point

The realization happened on **Nov 11, 2025** after:
1. Completing 15 tasks on this branch
2. Researching Garmin's audio APIs
3. Discovering AudioContentProviderApp architecture
4. Reading MonkeyMusic sample code
5. Understanding that standalone apps cannot play audio

**Commit `fa401aa`** on this branch documents the redesign that led to the correct implementation.

## Timeline

```
Nov 9, 2025:  Started audiobook-mvp branch
              Built custom UI, PIN auth, browsing

Nov 11, 2025: Completed position tracking
              Researched audio APIs
              ⚠️ DISCOVERED ARCHITECTURE IS WRONG ⚠️
              Created redesign document
              Started fresh with audio-provider branch

Nov 11, 2025: Completed correct implementation
              Merged audio-provider to main
```

## What Can Be Salvaged

From this branch, the following modules were **copied** to the correct implementation:
- ✅ `PlexApi.mc` - HTTP communication (updated)
- ✅ `PlexConfig.mc` - Configuration storage (updated)
- ✅ `PositionTracker.mc` - Local position tracking (unchanged)
- ✅ `PositionSync.mc` - Plex Timeline sync (unchanged)

**Everything else** (all the UI code) is incompatible and was not used.

## Missing From Correct Implementation

The correct implementation (`audio-provider`/`main`) is missing:
- ❌ On-watch browsing UI to select audiobooks
- ❌ On-watch audiobook detail view

**These need to be re-implemented** differently to work with AudioContentProviderApp architecture.

See `NEXT_STEPS.md` on `main` branch for the plan to add browsing capability.

## If You're Reading This

**DO NOT:**
- Merge this branch to main
- Use this code as a reference for new features
- Try to "fix" the audio playback

**DO:**
- Use `main` branch (merged from `feature/audio-provider`)
- Reference this branch only for understanding what didn't work
- Read the redesign document to understand why we pivoted

## Conclusion

This branch is a **dead end** kept for historical context.

The working implementation is on `main` branch.

---

**Last updated:** Nov 11, 2025
**Status:** ⚠️ DEPRECATED - Historical Reference Only
**Action:** DO NOT MERGE
