# PlexRunner Companion App - Design Document

**Date:** 2025-11-11
**Status:** Design Phase
**Platform:** React Native (iOS + Android)

## Executive Summary

Build a mobile companion app that allows users to browse their Plex audiobook library and select audiobooks for sync to their Garmin watch. Uses React Native with Garmin Connect IQ Mobile SDK integration.

## Problem Statement

The PlexRunner watch app is feature-complete but has no way for users to:
1. Browse their Plex audiobook library
2. Select which audiobooks to download
3. Trigger the sync process

The watch app's `SyncDelegate` expects a `syncList` property (array of Plex ratingKeys) but nothing currently populates this.

## Solution Architecture

### Platform Choice: React Native

**Rationale:**
- Single codebase for iOS and Android
- JavaScript/TypeScript (accessible for learning)
- `react-native-connect-iq-mobile-sdk` wrapper exists
- fnm (Node.js) already installed on development Mac
- No Xcode installed (would require 7-10 GB download for native iOS)

**Trade-offs:**
- Larger app size vs native
- Performance acceptable for browsing UI
- Garmin SDK integration handled by wrapper library

### Technology Stack

**Core:**
- React Native 0.73+
- TypeScript
- React Navigation (screen navigation)
- Expo (optional, for easier development)

**Garmin Integration:**
- `react-native-connect-iq-mobile-sdk` (npm package)
- Wraps native iOS/Android Garmin SDKs

**State Management:**
- React Context API (sufficient for this app's complexity)
- AsyncStorage for persistent settings

**HTTP:**
- fetch API (built-in)
- Plex API communication

## Data Flow

```
User → Mobile App → Garmin SDK → Watch App → Plex Server
         ↑                                ↓
         └───────── Plex API ──────────────┘
```

### Detailed Flow:

1. **Configuration:**
   - User enters Plex server URL and auth token in mobile app
   - Stored in AsyncStorage
   - (Alternative: Read from watch app's Application.Properties if SDK allows)

2. **Browsing:**
   - Mobile app fetches audiobook list from Plex API
   - `/library/sections` - Get library IDs
   - `/library/sections/{id}/all` - Get audiobooks
   - Display with title, author, cover art

3. **Selection:**
   - User selects audiobooks to sync
   - Local state tracks selections
   - Show selected count in UI

4. **Sync Trigger:**
   - User taps "Sync to Watch"
   - Mobile app sends message to watch app via Garmin SDK
   - Message format: `{type: "syncList", data: ["ratingKey1", "ratingKey2", ...]}`

5. **Watch Processing:**
   - Watch app receives message
   - Stores syncList in Application.Storage
   - User triggers sync from watch (or auto-triggers)
   - SyncDelegate downloads audiobooks

## Screen Design

### Screen 1: Setup (First Launch)

```
┌─────────────────────────────────┐
│  PlexRunner Setup               │
│                                 │
│  Plex Server URL                │
│  ┌─────────────────────────┐   │
│  │ https://plex.example... │   │
│  └─────────────────────────┘   │
│                                 │
│  Auth Token                     │
│  ┌─────────────────────────┐   │
│  │ ••••••••••••••••••••    │   │
│  └─────────────────────────┘   │
│                                 │
│  Library Name (optional)        │
│  ┌─────────────────────────┐   │
│  │ Music                   │   │
│  └─────────────────────────┘   │
│                                 │
│        [ Connect ]              │
└─────────────────────────────────┘
```

**Purpose:** Collect Plex server configuration
**Validation:** Test connection before proceeding
**Storage:** AsyncStorage (persistent)

### Screen 2: Audiobook Library

```
┌─────────────────────────────────┐
│  < Settings    Audiobooks    ✓  │
│                                 │
│  🔍 Search audiobooks...        │
│                                 │
│  ┌─────────────────────────┐   │
│  │ □ [Cover] The Hobbit    │   │
│  │    by J.R.R. Tolkien    │   │
│  │    12h 32m              │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✓ [Cover] Dune          │   │
│  │    by Frank Herbert     │   │
│  │    21h 2m               │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ □ [Cover] 1984          │   │
│  │    by George Orwell     │   │
│  │    11h 22m              │   │
│  └─────────────────────────┘   │
│                                 │
│  2 selected  [ Sync to Watch ]  │
└─────────────────────────────────┘
```

**Purpose:** Browse and select audiobooks
**Features:**
- Cover art thumbnails
- Title, author, duration
- Checkbox selection
- Selected count badge
- Sync button (bottom)

### Screen 3: Sync Progress

```
┌─────────────────────────────────┐
│  Syncing to Watch               │
│                                 │
│  Connecting to watch...         │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░ 65%      │
│                                 │
│  Sending:                       │
│  • The Hobbit                   │
│  • Dune                         │
│                                 │
│  Status: Transferring data...   │
│                                 │
│         [ Cancel ]              │
└─────────────────────────────────┘
```

**Purpose:** Show sync progress
**States:**
- Connecting to watch
- Sending data
- Success / Error

### Screen 4: Settings

```
┌─────────────────────────────────┐
│  < Back         Settings        │
│                                 │
│  Plex Server                    │
│  ┌─────────────────────────┐   │
│  │ https://plex.example... │   │
│  └─────────────────────────┘   │
│                                 │
│  Auth Token                     │
│  ┌─────────────────────────┐   │
│  │ ••••••••••••••••••••    │   │
│  └─────────────────────────┘   │
│                                 │
│  Library Name                   │
│  ┌─────────────────────────┐   │
│  │ Music                   │   │
│  └─────────────────────────┘   │
│                                 │
│  Watch Connection               │
│  Status: Connected              │
│  Device: Forerunner 970         │
│                                 │
│  [ Test Connection ]            │
│  [ Clear Cache ]                │
└─────────────────────────────────┘
```

**Purpose:** Manage app configuration
**Features:**
- Edit Plex settings
- View watch connection status
- Test utilities

## Watch App Changes

### Add Message Receiver

**File:** `source/PlexRunnerApp.mc`

```monkeyc
using Toybox.Communications;

class PlexRunnerApp extends Application.AudioContentProviderApp {
    function onStart(state as Lang.Dictionary?) as Void {
        AudioContentProviderApp.onStart(state);

        // Register message listener
        Communications.registerForPhoneAppMessages(method(:onMessage));

        // ... existing timer code ...
    }

    function onMessage(msg as Lang.Dictionary) as Void {
        if (msg[:type] != null && msg[:type].equals("syncList")) {
            var syncList = msg[:data];
            if (syncList != null && syncList instanceof Lang.Array) {
                // Store in Application.Properties for SyncDelegate
                Application.Properties.setValue("syncList", syncList);
                System.println("Received syncList from companion: " + syncList.size() + " audiobooks");
            }
        }
    }
}
```

**Changes:**
1. Register for phone app messages
2. Parse received message
3. Store syncList in Application.Properties
4. SyncDelegate reads it automatically

## Plex API Integration

### Endpoints Used

**1. Get Library Sections:**
```
GET /library/sections
X-Plex-Token: {token}

Response:
{
  "MediaContainer": {
    "Directory": [
      {"key": "1", "title": "Music", "type": "artist"}
    ]
  }
}
```

**2. Get Audiobooks:**
```
GET /library/sections/{id}/all
X-Plex-Token: {token}

Response:
{
  "MediaContainer": {
    "Metadata": [
      {
        "ratingKey": "12345",
        "title": "The Hobbit",
        "parentTitle": "J.R.R. Tolkien", // author
        "thumb": "/library/metadata/12345/thumb",
        "duration": 45120000 // milliseconds
      }
    ]
  }
}
```

**3. Get Cover Art (optional):**
```
GET {thumb_url}
X-Plex-Token: {token}

Response: JPEG image
```

### API Module Structure

```typescript
// src/api/plex.ts

export interface PlexConfig {
  serverUrl: string;
  authToken: string;
  libraryName?: string;
}

export interface Audiobook {
  ratingKey: string;
  title: string;
  author: string;
  duration: number; // milliseconds
  thumbUrl?: string;
}

export class PlexApi {
  constructor(private config: PlexConfig) {}

  async getLibraries(): Promise<Library[]>
  async getAudiobooks(libraryId: string): Promise<Audiobook[]>
  async getCoverArt(thumbUrl: string): Promise<string> // base64
}
```

## Garmin SDK Integration

### Message Sending (Mobile → Watch)

```typescript
// src/services/garmin.ts
import ConnectIQ from 'react-native-connect-iq-mobile-sdk';

export class GarminService {
  private appId = '7362c2a0f1805be30d6fdfa43b1178bb'; // PlexRunner app ID

  async initialize() {
    await ConnectIQ.initialize();
  }

  async getConnectedDevices() {
    return await ConnectIQ.getConnectedDevices();
  }

  async sendSyncList(ratingKeys: string[]) {
    const message = {
      type: 'syncList',
      data: ratingKeys
    };

    await ConnectIQ.sendMessage(this.appId, message);
  }

  async checkAppInstalled(device): Promise<boolean> {
    const apps = await ConnectIQ.getDeviceApps(device);
    return apps.some(app => app.id === this.appId);
  }
}
```

## State Management

### Context Structure

```typescript
// src/context/AppContext.tsx

interface AppState {
  // Config
  plexConfig: PlexConfig | null;

  // Data
  audiobooks: Audiobook[];
  selectedAudiobooks: string[]; // ratingKeys

  // Status
  isLoading: boolean;
  error: string | null;
  syncStatus: 'idle' | 'connecting' | 'sending' | 'success' | 'error';

  // Garmin
  connectedDevice: any | null;
}

interface AppActions {
  setPlexConfig: (config: PlexConfig) => void;
  loadAudiobooks: () => Promise<void>;
  toggleAudiobook: (ratingKey: string) => void;
  syncToWatch: () => Promise<void>;
}
```

## Error Handling

### Categories:

1. **Plex Connection Errors:**
   - Invalid URL
   - Invalid token
   - Network timeout
   - Library not found

2. **Garmin SDK Errors:**
   - No device connected
   - App not installed on watch
   - Message send failure
   - SDK initialization failure

3. **User Errors:**
   - No audiobooks selected
   - Storage full on watch
   - Invalid configuration

### Error Display:

```typescript
interface ErrorAlert {
  title: string;
  message: string;
  actions: {
    primary: {label: string, action: () => void};
    secondary?: {label: string, action: () => void};
  };
}
```

## Development Phases

### Phase 1: Project Setup (1 hour)
- Initialize React Native project
- Install dependencies
- Set up TypeScript
- Configure navigation
- Create project structure

### Phase 2: Plex Integration (2 hours)
- Implement PlexApi service
- Setup screen with validation
- Test Plex connection
- Fetch audiobook list

### Phase 3: UI Implementation (3 hours)
- Audiobook library screen
- Cover art loading
- Selection state management
- Search/filter (optional)

### Phase 4: Garmin Integration (3 hours)
- Install and configure Garmin SDK wrapper
- Implement GarminService
- Device detection
- Message sending

### Phase 5: Watch App Changes (1 hour)
- Add message receiver
- Store syncList
- Test end-to-end

### Phase 6: Testing & Polish (2 hours)
- Error handling
- Loading states
- UX improvements
- Documentation

**Total Estimated Time:** 12 hours

## Testing Strategy

### Unit Tests:
- PlexApi methods
- GarminService methods
- State management logic

### Integration Tests:
- Plex API communication
- Garmin SDK message sending
- End-to-end data flow

### Manual Tests:
1. Setup with invalid credentials (should error)
2. Browse empty library (should show empty state)
3. Select audiobooks and sync
4. Verify watch receives syncList
5. Verify SyncDelegate downloads audiobooks
6. Test offline behavior
7. Test with no watch connected

## Security Considerations

### Auth Token Storage:
- Store in AsyncStorage (encrypted on device)
- Never log token
- Clear on logout

### Network Security:
- Support HTTPS only
- Validate SSL certificates
- Handle token expiration

### Data Privacy:
- No analytics/tracking
- No data sent to third parties
- Local-only processing

## Future Enhancements

### Phase 2 (Post-MVP):
- Resume playback from position
- Recently played list
- Collections browsing
- Search by author/title
- Cover art caching
- Offline mode improvements
- Watch storage indicator
- Sync progress from watch

## Success Criteria

**Companion app is complete when:**
- ✅ User can configure Plex connection
- ✅ User can browse audiobook library with cover art
- ✅ User can select multiple audiobooks
- ✅ App detects connected Garmin watch
- ✅ App sends syncList to watch successfully
- ✅ Watch stores syncList and SyncDelegate downloads audiobooks
- ✅ End-to-end flow works (mobile browse → select → sync → watch playback)
- ✅ Error handling covers all failure modes
- ✅ Documentation explains setup and usage

## Documentation Requirements

1. **README.md** - User-facing setup guide
2. **DEVELOPMENT.md** - Developer setup instructions
3. **API.md** - Plex API integration details
4. **ARCHITECTURE.md** - Technical overview
5. **Watch app integration** - Update PlexRunner README with companion app info

## Repository Structure

```
plexrunner-companion/
├── src/
│   ├── api/
│   │   └── plex.ts
│   ├── services/
│   │   └── garmin.ts
│   ├── screens/
│   │   ├── SetupScreen.tsx
│   │   ├── LibraryScreen.tsx
│   │   ├── SyncScreen.tsx
│   │   └── SettingsScreen.tsx
│   ├── components/
│   │   ├── AudiobookCard.tsx
│   │   ├── CoverArt.tsx
│   │   └── ErrorAlert.tsx
│   ├── context/
│   │   └── AppContext.tsx
│   ├── types/
│   │   └── index.ts
│   └── App.tsx
├── android/
├── ios/
├── package.json
├── tsconfig.json
├── README.md
└── DEVELOPMENT.md
```

## Implementation Order

1. Design document (this file) ✅
2. Initialize React Native project
3. Implement PlexApi service
4. Build Setup screen
5. Build Library screen
6. Integrate Garmin SDK
7. Add watch app message handler
8. End-to-end testing
9. Polish and documentation
10. Deployment instructions

---

**Ready for Implementation:** Yes
**Next Step:** Phase 1 - Project Setup
**Estimated Completion:** 12 hours
**Platform:** macOS (Intel) with fnm
