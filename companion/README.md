# PlexRunner Companion App

**Browse and sync Plex audiobooks to your Garmin watch**

React Native companion app for PlexRunner - browse your Plex audiobook library on your phone and sync selected audiobooks to your Garmin watch for offline playback.

## Features

- 📚 Browse Plex audiobook library with cover art
- ✅ Select multiple audiobooks for sync
- ⌚ Automatic Garmin device detection
- 🔄 One-tap sync to watch
- ⚙️ Simple Plex server configuration
- 📱 iOS and Android support

## Prerequisites

### Required

- **Node.js 18+** (fnm, nvm, or system Node)
- **npm** or **yarn**
- **Plex Media Server** with audiobook library
- **Garmin watch** with PlexRunner app installed
- **Garmin Connect app** on phone (for watch pairing)

### For iOS Development

- **macOS** with Xcode
- **iOS Simulator** or physical iOS device

### For Android Development

- **Android Studio**
- **Android SDK**
- **Android Emulator** or physical Android device

## Quick Start

### 1. Install Dependencies

```bash
cd companion
npm install
```

### 2. Start Development Server

```bash
npm start
```

This starts the Expo development server. You'll see a QR code and menu options.

### 3. Run on Device

**iOS:**
```bash
npm run ios
```

**Android:**
```bash
npm run android
```

**Physical Device (Recommended):**
1. Install Expo Go app on your phone
2. Scan the QR code from the terminal
3. App will load on your device

## Setup Guide

### First-Time Setup

1. **Launch App** - Opens setup screen

2. **Configure Plex Server:**
   - **Server URL:** `https://your-plex-server:32400`
   - **Auth Token:** Get from plex.tv → Account → View XML
   - **Library Name:** Name of your Music library (usually "Music")
   - Tap **Connect** to validate

3. **Connect Garmin Watch:**
   - Ensure watch is paired via Garmin Connect app
   - App will auto-detect connected watch
   - Verify PlexRunner app is installed on watch

4. **Browse & Sync:**
   - Browse audiobooks with cover art
   - Tap to select audiobooks
   - Tap **Sync to Watch** button
   - Wait for confirmation

5. **On Watch:**
   - Open Music Player app
   - Navigate to PlexRunner section
   - Audiobooks will appear for playback

## Architecture

```
PlexRunner Companion (Phone)
     ↓
Garmin Connect IQ SDK
     ↓
PlexRunner Watch App
     ↓
Plex Media Server
```

### Key Components

**Screens:**
- `SetupScreen` - Plex configuration
- `LibraryScreen` - Browse & select audiobooks
- `SettingsScreen` - View/edit settings

**Services:**
- `PlexApi` - Plex server communication
- `GarminService` - Watch communication via Connect IQ SDK

**State:**
- `AppContext` - Global app state with React Context API

## Development

### Project Structure

```
companion/
├── src/
│   ├── api/
│   │   └── plex.ts           # Plex API client
│   ├── services/
│   │   └── garmin.ts         # Garmin SDK wrapper
│   ├── screens/
│   │   ├── SetupScreen.tsx   # Configuration
│   │   ├── LibraryScreen.tsx # Main browsing
│   │   └── SettingsScreen.tsx# Settings
│   ├── components/
│   │   ├── Button.tsx        # Reusable button
│   │   └── ErrorAlert.tsx    # Error display
│   ├── context/
│   │   └── AppContext.tsx    # Global state
│   └── types/
│       └── index.ts          # TypeScript types
├── App.tsx                   # Entry point
├── package.json
└── README.md
```

### Tech Stack

- **React Native** - Mobile framework
- **Expo** - Development platform
- **TypeScript** - Type safety
- **React Context API** - State management
- **AsyncStorage** - Persistent storage
- **Garmin Connect IQ SDK** - Watch communication

### Key Dependencies

```json
{
  "react-native": "^0.73",
  "@react-navigation/native": "^6.1",
  "@react-native-async-storage/async-storage": "^1.21",
  "react-native-connect-iq-mobile-sdk": "^0.3.0"
}
```

## How It Works

### Data Flow

1. **User selects audiobooks** in companion app
2. **App sends message** to watch via Garmin SDK:
   ```javascript
   {
     type: "syncList",
     data: ["ratingKey1", "ratingKey2", ...]
   }
   ```

3. **Watch receives message** and stores in Properties:
   ```monkeyc
   Application.Properties.setValue("syncList", syncList);
   ```

4. **Watch SyncDelegate** reads syncList and downloads audiobooks

5. **Watch Music Player** shows audiobooks for playback

### Message Protocol

**Companion → Watch:**
```typescript
interface SyncListMessage {
  type: "syncList";
  data: string[]; // Array of Plex ratingKeys
}
```

## Troubleshooting

### "No Device Connected"

**Solutions:**
1. Ensure watch is paired via Garmin Connect app
2. Keep Garmin Connect app running in background
3. Restart both apps
4. Check Bluetooth is enabled

### "PlexRunner app not found on watch"

**Solution:**
1. Install PlexRunner watch app from Connect IQ Store
2. Or sideload from development build
3. Verify installation in Garmin Connect

### "Failed to connect to Plex server"

**Solutions:**
1. Verify server URL is correct (include port)
2. Check auth token is valid
3. Ensure server is accessible from phone network
4. Test URL in browser: `https://your-server:32400/library/sections?X-Plex-Token=YOUR_TOKEN`

### "Library not found"

**Solution:**
1. Check library name spelling
2. View available libraries in Plex web UI
3. Library type must be "Music"

## Building for Production

### iOS

```bash
# Expo managed build
eas build --platform ios

# Or eject and build with Xcode
npm run eject
open ios/PlexRunnerCompanion.xcworkspace
```

### Android

```bash
# Expo managed build
eas build --platform android

# Or eject and build with Android Studio
npm run eject
cd android && ./gradlew assembleRelease
```

## Testing

### Manual Testing Checklist

- [ ] Setup screen validates Plex connection
- [ ] Library loads audiobooks with cover art
- [ ] Audiobook selection toggles correctly
- [ ] Selected count updates in UI
- [ ] Device detection shows connected watch
- [ ] Sync sends message to watch
- [ ] Watch receives and stores syncList
- [ ] Settings screen displays configuration
- [ ] Reconfigure clears and resets setup

### Testing Without Watch

For development testing without a physical watch:

1. Use Garmin Connect IQ Simulator
2. Mock Garmin SDK responses in `GarminService`
3. Test Plex API integration independently

## Contributing

This is part of the PlexRunner project. See main repository for contribution guidelines.

## License

See main PlexRunner project for license information.

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review design document: `docs/plans/2025-11-11-companion-app-design.md`
3. Check main PlexRunner README for watch app setup

## Version

**v1.0.0** - Initial release (2025-11-11)

---

**Part of PlexRunner** - Phone-free audiobook listening from Plex on Garmin watches
