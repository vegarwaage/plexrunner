# PlexRunner Audiobook MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a functional Plex audiobook player for Garmin Forerunner 970 that authenticates with Plex, browses audiobooks, downloads them over WiFi, and integrates with the native media player.

**Architecture:** Audio Content Provider app using PIN-based OAuth for authentication, Plex Music library API for browsing, manual WiFi sync for downloads, continuous position tracking synced back to Plex, and integration with Garmin's native media player for playback.

**Tech Stack:** Monkey C, Connect IQ SDK 8.3.0, Plex API (XML/JSON), Garmin Media.AudioContentProviderApp

---

## Prerequisites

Before starting implementation, verify environment setup:

### Required Tools
- Connect IQ SDK 8.3.0+ installed via SDK Manager
- Visual Studio Code with Monkey C extension
- Java Runtime Environment 8+
- Garmin Forerunner 970 physical device for testing
- Plex Media Server with audiobook library configured

### Verification Steps

```bash
# Check SDK installation
which monkeyc

# Check simulator
which connectiq

# Expected: Paths to both executables
```

---

## Phase 1: Project Structure & Build System

### Task 1: Create Connect IQ Project Structure

**Files:**
- Create: `manifest.xml`
- Create: `monkey.jungle`
- Create: `source/PlexRunnerApp.mc`
- Create: `resources/strings/strings.xml`
- Create: `resources/drawables/drawables.xml`

**Step 1: Create manifest.xml**

Create `manifest.xml` in project root:

```xml
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application entry="PlexRunnerApp" id="YOUR_APP_ID_HERE" launcherIcon="@Drawables.LauncherIcon" minSdkVersion="5.2.0" name="@Strings.AppName" type="audio-content-provider-app" version="0.1.0">
        <iq:products>
            <iq:product id="forerunner970"/>
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="Communications"/>
            <iq:uses-permission id="Storage"/>
        </iq:permissions>
        <iq:languages>
            <iq:language>eng</iq:language>
        </iq:languages>
    </iq:application>
</iq:manifest>
```

**Note:** Replace `YOUR_APP_ID_HERE` with a unique UUID (generate at https://www.uuidgenerator.net/)

**Step 2: Create monkey.jungle build configuration**

Create `monkey.jungle`:

```
project.manifest = manifest.xml

forerunner970.resourcePath = resources
forerunner970.sourcePath = source
```

**Step 3: Create basic app entry point**

Create `source/PlexRunnerApp.mc`:

```monkeyc
using Toybox.Application;
using Toybox.WatchUi;

// ABOUTME: PlexRunner main application entry point and lifecycle management
// ABOUTME: Initializes audio content provider and handles app state

class PlexRunnerApp extends Application.AudioContentProviderApp {

    function initialize() {
        AudioContentProviderApp.initialize();
    }

    function onStart(state) {
        AudioContentProviderApp.onStart(state);
    }

    function onStop(state) {
        AudioContentProviderApp.onStop(state);
    }

    function getInitialView() {
        return [new MainMenuView(), new MainMenuDelegate()];
    }
}
```

**Step 4: Create resource strings**

Create `resources/strings/strings.xml`:

```xml
<strings>
    <string id="AppName">PlexRunner</string>
    <string id="MainMenuTitle">PlexRunner</string>
</strings>
```

**Step 5: Create placeholder drawable**

Create `resources/drawables/drawables.xml`:

```xml
<drawables>
    <bitmap id="LauncherIcon" filename="launcher_icon.png"/>
</drawables>
```

**Step 6: Create launcher icon (temporary placeholder)**

Create a simple 80x80px PNG icon at `resources/drawables/launcher_icon.png`. For now, use a solid color square or download a temporary icon.

**Step 7: Verify project compiles**

```bash
cd /Users/selwa/Developer/plexrunner/.worktrees/audiobook-mvp
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds, creates `bin/PlexRunner.prg`

**Note:** If `developer_key.der` doesn't exist, generate it:
```bash
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
```

**Step 8: Commit**

```bash
git add manifest.xml monkey.jungle source/ resources/
git commit -m "feat: initialize Connect IQ project structure

- Add manifest with audiobook content provider type
- Configure build for Forerunner 970
- Create app entry point with AudioContentProviderApp
- Add basic resources (strings, launcher icon)
- Verify compilation succeeds

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Create Main Menu View

**Files:**
- Create: `source/views/MainMenuView.mc`
- Create: `source/views/MainMenuDelegate.mc`
- Modify: `source/PlexRunnerApp.mc`

**Step 1: Create MainMenuView**

Create `source/views/MainMenuView.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;

// ABOUTME: Main menu view displaying primary navigation options
// ABOUTME: Shows Continue Reading, Collections, All Audiobooks, Downloaded, Sync

class MainMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("PlexRunner");
    }

    function onShow() {
        buildMenu();
    }

    function buildMenu() {
        // Clear existing menu items
        Menu2.deleteAllMenuItems();

        // Add menu items
        Menu2.addItem(new WatchUi.MenuItem(
            "Continue Reading",
            null,
            :continueReading,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "All Audiobooks",
            null,
            :allAudiobooks,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Downloaded",
            null,
            :downloaded,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Sync Now",
            null,
            :syncNow,
            {}
        ));

        Menu2.addItem(new WatchUi.MenuItem(
            "Settings",
            null,
            :settings,
            {}
        ));
    }
}
```

**Step 2: Create MainMenuDelegate**

Create `source/views/MainMenuDelegate.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Main menu input delegate handling menu item selection
// ABOUTME: Routes to appropriate view based on user selection

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :continueReading) {
            System.println("Continue Reading selected");
            // TODO: Show continue reading view
        } else if (id == :allAudiobooks) {
            System.println("All Audiobooks selected");
            // TODO: Show all audiobooks view
        } else if (id == :downloaded) {
            System.println("Downloaded selected");
            // TODO: Show downloaded audiobooks view
        } else if (id == :syncNow) {
            System.println("Sync Now selected");
            // TODO: Start sync process
        } else if (id == :settings) {
            System.println("Settings selected");
            // TODO: Show settings view
        }
    }

    function onBack() {
        // Exit app when back pressed from main menu
        System.exit();
    }
}
```

**Step 3: Update app to use menu views**

Modify `source/PlexRunnerApp.mc`:

```monkeyc
using Toybox.Application;
using Toybox.WatchUi;

// ABOUTME: PlexRunner main application entry point and lifecycle management
// ABOUTME: Initializes audio content provider and handles app state

(:glance)
class PlexRunnerApp extends Application.AudioContentProviderApp {

    function initialize() {
        AudioContentProviderApp.initialize();
    }

    function onStart(state) {
        AudioContentProviderApp.onStart(state);
    }

    function onStop(state) {
        AudioContentProviderApp.onStop(state);
    }

    function getInitialView() {
        return [new MainMenuView(), new MainMenuDelegate()];
    }
}
```

**Step 4: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 5: Test in simulator**

```bash
connectiq
```

Then load `bin/PlexRunner.prg` in the simulator, select Forerunner 970 device, and verify:
- App launches showing "PlexRunner" title
- Menu displays 5 items
- Selecting items prints to console
- Back button exits app

**Step 6: Commit**

```bash
git add source/views/
git commit -m "feat: add main menu view with navigation

- Create Menu2-based main menu
- Add menu items: Continue Reading, All Audiobooks, Downloaded, Sync, Settings
- Implement menu delegate with selection handling
- Add console logging for menu selections
- Verify menu displays and responds to input

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 2: Authentication & Settings

### Task 3: Create Settings Storage

**Files:**
- Create: `source/PlexConfig.mc`

**Step 1: Create PlexConfig storage module**

Create `source/PlexConfig.mc`:

```monkeyc
using Toybox.Application.Storage;
using Toybox.System;

// ABOUTME: Persistent configuration storage for Plex credentials and settings
// ABOUTME: Manages auth tokens, server URL, and user preferences

module PlexConfig {

    const KEY_AUTH_TOKEN = "auth_token";
    const KEY_SERVER_URL = "server_url";
    const KEY_CLIENT_ID = "client_id";

    // Get authentication token
    function getAuthToken() {
        return Storage.getValue(KEY_AUTH_TOKEN);
    }

    // Set authentication token
    function setAuthToken(token) {
        Storage.setValue(KEY_AUTH_TOKEN, token);
    }

    // Get Plex server URL
    function getServerUrl() {
        var url = Storage.getValue(KEY_SERVER_URL);
        if (url == null) {
            return "http://localhost:32400";  // Default
        }
        return url;
    }

    // Set Plex server URL
    function setServerUrl(url) {
        Storage.setValue(KEY_SERVER_URL, url);
    }

    // Get client identifier (generate once)
    function getClientId() {
        var id = Storage.getValue(KEY_CLIENT_ID);
        if (id == null) {
            // Generate unique client ID
            id = generateClientId();
            Storage.setValue(KEY_CLIENT_ID, id);
        }
        return id;
    }

    // Generate unique client identifier
    function generateClientId() {
        var timestamp = System.getTimer();
        var deviceId = System.getDeviceSettings().uniqueIdentifier;
        return "plexrunner_" + deviceId + "_" + timestamp;
    }

    // Check if authenticated
    function isAuthenticated() {
        var token = getAuthToken();
        return token != null && token.length() > 0;
    }

    // Clear all stored data
    function clear() {
        Storage.deleteValue(KEY_AUTH_TOKEN);
        Storage.deleteValue(KEY_SERVER_URL);
        // Keep client ID - it should persist
    }
}
```

**Step 2: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 3: Commit**

```bash
git add source/PlexConfig.mc
git commit -m "feat: add persistent configuration storage

- Create PlexConfig module for settings management
- Store auth token, server URL, client ID
- Generate unique client identifier per device
- Add authentication status check
- Use Application.Storage for persistence

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Create Settings View

**Files:**
- Create: `source/views/SettingsView.mc`
- Create: `source/views/SettingsDelegate.mc`
- Modify: `source/views/MainMenuDelegate.mc`

**Step 1: Create SettingsView**

Create `source/views/SettingsView.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;

// ABOUTME: Settings view for Plex server configuration
// ABOUTME: Displays server URL, auth status, and configuration options

class SettingsView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");
    }

    function onShow() {
        buildMenu();
    }

    function buildMenu() {
        Menu2.deleteAllMenuItems();

        // Show authentication status
        var authStatus = PlexConfig.isAuthenticated() ? "Connected" : "Not Connected";
        Menu2.addItem(new WatchUi.MenuItem(
            "Plex Status",
            authStatus,
            :status,
            {}
        ));

        // Show server URL
        var serverUrl = PlexConfig.getServerUrl();
        Menu2.addItem(new WatchUi.MenuItem(
            "Server",
            serverUrl,
            :server,
            {}
        ));

        // Authenticate option
        Menu2.addItem(new WatchUi.MenuItem(
            "Authenticate",
            null,
            :authenticate,
            {}
        ));

        // Clear data option
        Menu2.addItem(new WatchUi.MenuItem(
            "Clear Data",
            null,
            :clearData,
            {}
        ));
    }
}
```

**Step 2: Create SettingsDelegate**

Create `source/views/SettingsDelegate.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Settings menu input delegate
// ABOUTME: Handles authentication, server config, and data clearing

class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :status) {
            System.println("Status: " + (PlexConfig.isAuthenticated() ? "Authenticated" : "Not authenticated"));
        } else if (id == :server) {
            System.println("Server: " + PlexConfig.getServerUrl());
        } else if (id == :authenticate) {
            System.println("Starting authentication...");
            // TODO: Start PIN-based OAuth flow
        } else if (id == :clearData) {
            PlexConfig.clear();
            System.println("Data cleared");
            // Refresh menu to show updated status
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
```

**Step 3: Update MainMenuDelegate to show settings**

Modify `source/views/MainMenuDelegate.mc`, replace the settings case:

```monkeyc
        } else if (id == :settings) {
            WatchUi.pushView(new SettingsView(), new SettingsDelegate(), WatchUi.SLIDE_LEFT);
        }
```

**Step 4: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 5: Test in simulator**

1. Launch app in simulator
2. Select "Settings" from main menu
3. Verify settings menu appears with 4 items
4. Select "Clear Data" - verify data clears and menu refreshes
5. Press back - verify returns to main menu

**Step 6: Commit**

```bash
git add source/views/SettingsView.mc source/views/SettingsDelegate.mc source/views/MainMenuDelegate.mc
git commit -m "feat: add settings view with Plex configuration

- Create settings menu showing auth status and server URL
- Display current configuration from PlexConfig
- Add clear data functionality
- Integrate settings into main menu navigation
- Verify settings view navigation and data clearing

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Implement PIN-Based Authentication UI

**Files:**
- Create: `source/auth/AuthView.mc`
- Create: `source/auth/AuthDelegate.mc`
- Modify: `source/views/SettingsDelegate.mc`

**Step 1: Create AuthView to display PIN**

Create `source/auth/AuthView.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// ABOUTME: Authentication view displaying PIN code for plex.tv/link
// ABOUTME: Shows instructions and PIN for user to enter on web browser

class AuthView extends WatchUi.View {

    private var _pin;
    private var _expiresAt;

    function initialize(pin, expiresAt) {
        View.initialize();
        _pin = pin;
        _expiresAt = expiresAt;
    }

    function onLayout(dc) {
        // No layout file needed
    }

    function onShow() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;

        // Title
        dc.drawText(
            width / 2,
            height / 4,
            font,
            "Go to plex.tv/link",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // PIN code (large)
        dc.drawText(
            width / 2,
            height / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            _pin != null ? _pin : "----",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Instructions
        dc.drawText(
            width / 2,
            height * 3 / 4,
            Graphics.FONT_SMALL,
            "Enter this code",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() {
    }
}
```

**Step 2: Create AuthDelegate**

Create `source/auth/AuthDelegate.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.System;

// ABOUTME: Authentication delegate handling PIN auth flow
// ABOUTME: Manages polling for token after PIN entry

class AuthDelegate extends WatchUi.BehaviorDelegate {

    private var _pinId;
    private var _polling;

    function initialize(pinId) {
        BehaviorDelegate.initialize();
        _pinId = pinId;
        _polling = false;
    }

    function onSelect() {
        // Start polling for token
        if (!_polling) {
            _polling = true;
            System.println("Starting token polling for PIN ID: " + _pinId);
            // TODO: Implement token polling
        }
        return true;
    }

    function onBack() {
        // Cancel authentication
        System.println("Authentication cancelled");
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
```

**Step 3: Update SettingsDelegate to show auth view**

Modify `source/views/SettingsDelegate.mc`, replace authenticate case:

```monkeyc
        } else if (id == :authenticate) {
            // Show PIN authentication view
            // For now, use test PIN until we implement API call
            var testPin = "1234";
            var testPinId = "test_pin_id";
            var expiresAt = System.getTimer() + (15 * 60 * 1000); // 15 minutes

            WatchUi.pushView(
                new AuthView(testPin, expiresAt),
                new AuthDelegate(testPinId),
                WatchUi.SLIDE_LEFT
            );
        }
```

**Step 4: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 5: Test in simulator**

1. Launch app → Settings → Authenticate
2. Verify auth view shows "Go to plex.tv/link"
3. Verify PIN "1234" displays prominently
4. Verify "Enter this code" instruction shows
5. Press back - verify returns to settings

**Step 6: Commit**

```bash
git add source/auth/
git commit -m "feat: add PIN-based authentication UI

- Create AuthView displaying plex.tv/link instructions
- Show 4-digit PIN code prominently on watch
- Add AuthDelegate for handling auth flow
- Integrate auth view into settings menu
- Use test PIN for now (API integration next)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 3: Plex API Communication

### Task 6: Create HTTP Communication Module

**Files:**
- Create: `source/api/PlexApi.mc`
- Create: `source/api/ApiCallback.mc`

**Step 1: Create ApiCallback interface**

Create `source/api/ApiCallback.mc`:

```monkeyc
// ABOUTME: Callback interface for asynchronous API responses
// ABOUTME: Defines success and error handlers for HTTP requests

module ApiCallback {

    // Success callback with response data
    typedef SuccessCallback as Method(responseCode as Number, data as Object or String or Null) as Void;

    // Error callback with error info
    typedef ErrorCallback as Method(responseCode as Number, error as String) as Void;
}
```

**Step 2: Create PlexApi HTTP module**

Create `source/api/PlexApi.mc`:

```monkeyc
using Toybox.Communications;
using Toybox.System;

// ABOUTME: Plex API HTTP communication module
// ABOUTME: Handles authenticated requests to Plex server with proper headers

module PlexApi {

    // Request PIN for authentication
    function requestPin(onSuccess, onError) {
        var url = "https://plex.tv/api/v2/pins";
        var params = {
            "strong" => true
        };
        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
            "X-Plex-Product" => "PlexRunner",
            "X-Plex-Version" => "0.1.0",
            "X-Plex-Client-Identifier" => PlexConfig.getClientId(),
            "X-Plex-Platform" => "Garmin",
            "X-Plex-Device" => "Forerunner 970",
            "Accept" => "application/json"
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(
            url,
            params,
            options,
            method(:handlePinResponse).bindWith({
                :onSuccess => onSuccess,
                :onError => onError
            })
        );
    }

    // Handle PIN request response
    function handlePinResponse(responseCode, data, context) {
        System.println("PIN Response Code: " + responseCode);

        if (responseCode == 200 || responseCode == 201) {
            System.println("PIN Response Data: " + data);
            context[:onSuccess].invoke(responseCode, data);
        } else {
            var error = "Failed to get PIN. Response code: " + responseCode;
            System.println(error);
            context[:onError].invoke(responseCode, error);
        }
    }

    // Check PIN for auth token
    function checkPin(pinId, onSuccess, onError) {
        var url = "https://plex.tv/api/v2/pins/" + pinId;
        var headers = {
            "X-Plex-Client-Identifier" => PlexConfig.getClientId(),
            "Accept" => "application/json"
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(
            url,
            null,
            options,
            method(:handlePinCheckResponse).bindWith({
                :onSuccess => onSuccess,
                :onError => onError
            })
        );
    }

    // Handle PIN check response
    function handlePinCheckResponse(responseCode, data, context) {
        System.println("PIN Check Response Code: " + responseCode);

        if (responseCode == 200) {
            System.println("PIN Check Data: " + data);
            context[:onSuccess].invoke(responseCode, data);
        } else {
            var error = "Failed to check PIN. Response code: " + responseCode;
            System.println(error);
            context[:onError].invoke(responseCode, error);
        }
    }

    // Make authenticated request to Plex server
    function makeAuthenticatedRequest(path, onSuccess, onError) {
        var token = PlexConfig.getAuthToken();
        if (token == null) {
            onError.invoke(401, "Not authenticated");
            return;
        }

        var url = PlexConfig.getServerUrl() + path;
        var headers = {
            "X-Plex-Token" => token,
            "X-Plex-Client-Identifier" => PlexConfig.getClientId(),
            "X-Plex-Product" => "PlexRunner",
            "X-Plex-Platform" => "Garmin",
            "X-Plex-Device" => "Forerunner 970",
            "Accept" => "application/json"
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(
            url,
            null,
            options,
            method(:handleAuthenticatedResponse).bindWith({
                :onSuccess => onSuccess,
                :onError => onError
            })
        );
    }

    // Handle authenticated request response
    function handleAuthenticatedResponse(responseCode, data, context) {
        System.println("Authenticated Request Response Code: " + responseCode);

        if (responseCode == 200) {
            context[:onSuccess].invoke(responseCode, data);
        } else {
            var error = "Request failed. Response code: " + responseCode;
            System.println(error);
            context[:onError].invoke(responseCode, error);
        }
    }
}
```

**Step 3: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 4: Commit**

```bash
git add source/api/
git commit -m "feat: add Plex API HTTP communication module

- Create PlexApi module for HTTP requests
- Implement requestPin for PIN-based OAuth
- Implement checkPin for token polling
- Add makeAuthenticatedRequest for Plex API calls
- Include proper Plex headers (client ID, platform, etc)
- Add callback-based async response handling

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: Integrate Real PIN Authentication

**Files:**
- Modify: `source/auth/AuthView.mc`
- Modify: `source/auth/AuthDelegate.mc`
- Modify: `source/views/SettingsDelegate.mc`

**Step 1: Update SettingsDelegate to request real PIN**

Modify `source/views/SettingsDelegate.mc`, replace authenticate case:

```monkeyc
        } else if (id == :authenticate) {
            System.println("Requesting PIN from Plex...");

            PlexApi.requestPin(
                method(:onPinSuccess),
                method(:onPinError)
            );
        }
    }

    function onPinSuccess(responseCode, data) {
        System.println("PIN request successful");

        // Extract PIN and ID from response
        var pin = data["code"];
        var pinId = data["id"].toString();
        var expiresAt = System.getTimer() + (15 * 60 * 1000); // 15 minutes

        System.println("PIN: " + pin + ", ID: " + pinId);

        // Show auth view with real PIN
        WatchUi.pushView(
            new AuthView(pin, expiresAt),
            new AuthDelegate(pinId),
            WatchUi.SLIDE_LEFT
        );
    }

    function onPinError(responseCode, error) {
        System.println("PIN request failed: " + error);
        // TODO: Show error to user
    }
```

**Step 2: Update AuthDelegate to poll for token**

Modify `source/auth/AuthDelegate.mc`:

```monkeyc
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;

// ABOUTME: Authentication delegate handling PIN auth flow
// ABOUTME: Manages polling for token after PIN entry

class AuthDelegate extends WatchUi.BehaviorDelegate {

    private var _pinId;
    private var _polling;
    private var _pollTimer;

    function initialize(pinId) {
        BehaviorDelegate.initialize();
        _pinId = pinId;
        _polling = false;
        _pollTimer = null;
    }

    function onSelect() {
        // Start polling for token
        if (!_polling) {
            _polling = true;
            System.println("Starting token polling for PIN ID: " + _pinId);
            startPolling();
        }
        return true;
    }

    function startPolling() {
        // Poll every 3 seconds
        _pollTimer = new Timer.Timer();
        _pollTimer.start(method(:checkForToken), 3000, true);
    }

    function checkForToken() {
        System.println("Polling for token...");

        PlexApi.checkPin(
            _pinId,
            method(:onTokenSuccess),
            method(:onTokenError)
        );
    }

    function onTokenSuccess(responseCode, data) {
        var authToken = data["authToken"];

        if (authToken != null && authToken.length() > 0) {
            System.println("Token received!");

            // Stop polling
            if (_pollTimer != null) {
                _pollTimer.stop();
            }
            _polling = false;

            // Save token
            PlexConfig.setAuthToken(authToken);

            // Return to settings (show success)
            WatchUi.popView(WatchUi.SLIDE_RIGHT);

            System.println("Authentication complete");
        } else {
            System.println("Token not yet available, continuing to poll...");
        }
    }

    function onTokenError(responseCode, error) {
        System.println("Token check failed: " + error);
        // Continue polling unless it's a fatal error
        if (responseCode == 404) {
            // PIN not found - stop polling
            if (_pollTimer != null) {
                _pollTimer.stop();
            }
            _polling = false;
        }
    }

    function onBack() {
        // Cancel authentication
        System.println("Authentication cancelled");

        if (_pollTimer != null) {
            _pollTimer.stop();
        }

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
```

**Step 3: Update AuthView to show polling status**

Modify `source/auth/AuthView.mc`, add status field:

```monkeyc
    private var _pin;
    private var _expiresAt;
    private var _polling;

    function initialize(pin, expiresAt) {
        View.initialize();
        _pin = pin;
        _expiresAt = expiresAt;
        _polling = false;
    }

    function setPolling(polling) {
        _polling = polling;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;

        // Title
        dc.drawText(
            width / 2,
            height / 4 - 20,
            Graphics.FONT_SMALL,
            "Go to plex.tv/link",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // PIN code (large)
        dc.drawText(
            width / 2,
            height / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            _pin != null ? _pin : "----",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Instructions / Status
        var statusText = _polling ? "Waiting..." : "Press SELECT to start";
        dc.drawText(
            width / 2,
            height * 3 / 4,
            Graphics.FONT_SMALL,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
```

**Step 4: Verify compilation**

```bash
monkeyc -d forerunner970 -f monkey.jungle -o bin/PlexRunner.prg -y developer_key.der
```

Expected: Compilation succeeds

**Step 5: Test on device (simulator may not support network requests)**

Deploy to Forerunner 970:
1. Connect watch via USB
2. Copy `bin/PlexRunner.prg` to watch
3. Settings → Authenticate
4. Verify real PIN displays
5. Open browser → plex.tv/link → Enter PIN
6. Verify watch polls and saves token
7. Check Settings → Status shows "Connected"

**Step 6: Commit**

```bash
git add source/auth/ source/views/SettingsDelegate.mc
git commit -m "feat: integrate real PIN-based authentication

- Request PIN from plex.tv API
- Display real PIN code on watch
- Poll for auth token every 3 seconds after user presses SELECT
- Save token to PlexConfig on successful auth
- Update auth view with polling status
- Cancel polling on back button

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 4: Audiobook Library Browsing

**Note:** Due to length constraints, the remaining tasks follow the same pattern. Here's the structure for the remaining implementation:

### Task 8: Fetch Audiobook Library from Plex
- Create library browsing API calls
- Parse Plex XML/JSON responses
- Extract audiobook metadata (author, title, duration, file size)

### Task 9: Create Audiobook List View
- Display list of available audiobooks
- Show title, author, duration
- Handle selection to show book details

### Task 10: Create Audiobook Detail View
- Show full book information
- Display download status
- Add download/delete buttons

## Phase 5: Download & Sync

### Task 11: Implement Download Manager
- Queue audiobooks for download
- Track download progress
- Handle WiFi connectivity requirements

### Task 12: Download Audio Files
- Request audio from Plex with transcoding
- Save to watch storage
- Update download status

### Task 13: Create Sync View
- Show sync progress
- Display current download
- Allow cancellation

## Phase 6: Position Tracking

### Task 14: Implement Position Tracker
- Save playback position every 30 seconds
- Store position locally
- Handle multi-file vs single-file books

### Task 15: Sync Position to Plex
- Upload position during sync
- Use Plex timeline API
- Handle sync conflicts

## Phase 7: Playback Integration

### Task 16: Implement ContentProvider
- Create AudioContentProviderApp interface
- Return downloaded audiobooks to player
- Provide track metadata

### Task 17: Implement Playback Callbacks
- Handle position updates
- Track current chapter
- Save position on events

### Task 18: Test End-to-End
- Complete flow: auth → browse → download → play
- Verify position saves and syncs
- Test on physical device

---

## Testing Strategy

**For each task:**
1. Compile after every change
2. Test in simulator where possible
3. Deploy to physical device for:
   - Network requests
   - Audio download
   - Actual playback
   - Battery/storage impact

**Integration testing:**
- Full authentication flow
- Browse → Download → Play workflow
- Position tracking across app restarts
- Sync after playback

---

## Deployment Checklist

Before releasing to Garmin Connect IQ Store:

1. ☐ Generate production developer key
2. ☐ Update manifest with production IDs
3. ☐ Test on multiple Garmin devices (if expanding beyond Forerunner 970)
4. ☐ Verify memory usage within limits
5. ☐ Test battery consumption during typical usage
6. ☐ Write store listing (description, screenshots)
7. ☐ Submit for Garmin review

---

## Notes for Implementation

**Monkey C Gotchas:**
- No string interpolation - use concatenation with `+`
- Limited debugging - rely on `System.println()` extensively
- Simulator limitations - network and audio require real device
- Memory constraints - watch memory usage, avoid large objects

**Common Issues:**
- Network timeouts - implement retry logic
- Storage limits - check available space before downloads
- Token expiration - handle 401 responses gracefully
- XML parsing - Plex returns XML by default, request JSON with headers

**Best Practices:**
- Commit frequently (after each working change)
- Test on device early and often
- Log everything for debugging
- Handle errors gracefully with user-friendly messages
