# SubMusic provides battle-tested Plex implementation for Garmin

SubMusic is a production-ready Connect IQ audio content provider that **already includes working Plex API support with transcoding**, making it an ideal reference implementation for building a Plex app for Garmin Forerunner 970. The repository contains proven patterns for HTTP networking, authentication, sync management, and audio content delivery that can be directly adapted or forked. With **149 stars, active maintenance since 2023, and support for 30+ Garmin devices** including multiple Forerunner models, SubMusic demonstrates that Plex integration on Garmin watches is not only feasible but production-validated.

The app enables users to sync playlists from self-hosted music servers directly to their Garmin watches for offline playback during workouts. Beyond Plex, it supports Subsonic, Ampache, and Nextcloud Music through a well-designed provider abstraction pattern that isolates API-specific code. This architecture makes it straightforward to enhance Plex functionality or adapt components for a dedicated Plex app. The repository is actively maintained but not archived, with the latest release (v0.2.10-hippocoon) published July 14, 2023.

## Working Plex support eliminates greenfield development

SubMusic's experimental Plex integration is the repository's most valuable asset for this use case. The implementation uses **X-Plex-Token authentication**, connects to Plex servers via the `https://ip-address.hash.plex.direct:32400/` format, and includes **transcoding support** added in version 0.2.4. This transcoding capability is critical because Garmin watches have strict format requirements (MP3, MP4, ADTS, WAV), while Plex libraries often contain FLAC, ALAC, and other incompatible formats.

The authentication flow is token-based rather than username/password, simplifying implementation and improving security. Users obtain their X-Plex-Token through plex.tv authentication, then configure the token and server address in SubMusic's settings. The app validates connections with a "Test Server" function before syncing. All API requests include the token either as a URL parameter (`?X-Plex-Token=TOKEN`) or HTTP header (`X-Plex-Token: TOKEN`), and the token remains valid until the user changes their Plex password.

The Plex implementation leverages standard REST API endpoints including `/playlists` for listing playlists, `/playlists/{id}/items` for playlist contents, `/library/metadata/{id}` for track metadata, and transcoding endpoints for converting audio to compatible formats. The architecture demonstrates that Plex's XML-based API can work seamlessly with Garmin's Connect IQ framework, which typically expects JSON responses from music services like Subsonic.

## Provider abstraction pattern enables clean API separation

SubMusic's architecture centers on a **provider abstraction layer** that isolates API-specific code from core functionality. The codebase includes multiple provider implementations (PlexProvider, SubsonicProvider, AmpacheProvider), each implementing a common interface for fetching playlists, retrieving track metadata, downloading audio content, and managing authentication. This design pattern is particularly valuable because Plex and Subsonic APIs share conceptual similarities—both provide playlist management, track metadata, album art, and RESTful HTTP interfaces—but differ in endpoint structure and response formats.

The provider interface defines common operations like `getPlaylists()`, `getTracks()`, and `downloadTrack()` that work identically from the app's perspective regardless of backend. When users select their preferred music server in settings, SubMusic instantiates the appropriate provider. This approach means the sync architecture, UI components, storage management, and playback controls remain API-agnostic and fully reusable.

For adapting SubMusic to a dedicated Plex app, the strategy is straightforward: retain the provider interface and abstraction layer, implement PlexProvider with Plex-specific endpoints, map Plex XML responses to the common metadata structure, use the existing sync architecture, and enhance Plex-specific features like transcoding quality controls. The existing code already handles the complexity of multiple device compatibility and storage management.

## Sync architecture follows mandatory Connect IQ patterns

SubMusic implements Garmin's **Media.SyncDelegate pattern**, which is mandatory for proper offline music functionality on Connect IQ devices. The sync architecture involves four coordinated components: **Syncer** (main orchestrator), **PlaylistSync** (playlist-specific operations), **SyncDelegate** (Garmin's callback interface), and **Provider** (content URLs and metadata supplier).

The sync flow begins when users initiate sync from a dedicated sync button or menu—this is critical because syncing from other contexts may "fake sync" by completing without actually downloading files, a known Garmin SDK limitation. Once triggered, `SyncDelegate.onStartSync()` fires, the Syncer coordinates with the Provider to fetch playlist data, PlaylistSync manages individual playlist downloads, and audio files download via the ContentProvider interface. Progress callbacks update the UI with percentage completion, and `SyncDelegate.onComplete()` signals finished operations.

SubMusic supports multi-playlist sync, progress tracking, pause/resume capability, offline availability management, and storage limit awareness. The implementation demonstrates how to handle **WiFi connection management carefully** to avoid battery drain from hanging connections—a critical consideration for wearable devices. The app requires WiFi for syncing but enables offline playback afterward, making it suitable for workouts where phone connectivity is unavailable.

## HTTP networking implements Garmin-specific constraints

The networking layer uses Garmin's `makeWebRequest()` API with specific patterns required for reliable operation. SubMusic centralizes all HTTP communication in an **Api class** that handles requests from multiple contexts (Provider, PlaylistSync, Syncer, SyncDelegate). The implementation enforces **HTTPS-only connections** with valid CA-signed certificates—self-signed certificates are explicitly not supported by Garmin watches.

Key networking patterns include handling `responseCode 200` for successful requests, parsing JSON/XML responses to dictionaries, managing `responseCode 0` (UNKNOWN_ERROR typically indicating authentication or connection issues), and implementing retry logic for timeouts. Common error codes include **Error -300** (NETWORK_REQUEST_TIMED_OUT), **Error -402** (payload too large, hitting the ~25 song limit for Subsonic API), and **Error 0** (authentication or certificate validation failures).

The codebase demonstrates best practices like enforcing TLS 1.2+ connections, using Let's Encrypt-compatible certificates, implementing retry logic for network timeouts, and cleaning up connection states to prevent battery drain. One important limitation: SubMusic requires servers on ports 80 or 443 only, not custom ports like Plex's default 32400. However, the plex.direct domain workaround (`https://ip-address.hash.plex.direct:32400/`) maps the custom port to standard HTTPS ports, resolving this constraint.

## Storage and metadata management handles device limitations

SubMusic manages on-device storage through Connect IQ's Media framework, handling playlist metadata caching, audio file storage, app settings persistence, and sync state tracking. The implementation is storage-aware, displaying available space in settings and managing efficient cache eviction when storage fills up. Watch storage limitations are significant—Garmin devices typically have **1-4GB available for music**, requiring careful management of downloaded content.

Metadata handling covers track information (title, artist, album, duration), album art (device-dependent, not all watches support it), playlist associations, and listening progress tracking. The app implements **play count tracking and scrobbling**, uploading listening data back to the server on the next sync. For podcasts, it tracks episode position to enable resume functionality.

File format support is explicitly defined: **MP3 is fully tested**, while MP4, ADTS, and WAV have beta support. Transcoding is supported for Plex (critical feature) but not for Nextcloud/Ampache backends. This demonstrates the importance of transcoding for production Plex integration, as users' libraries inevitably contain formats incompatible with Garmin watches.

## Forerunner 970 compatibility likely requires minor updates

SubMusic lists extensive device compatibility including multiple Forerunner models: **Forerunner 245 Music, 255, 265, 265S, 955, and 965**. While the Forerunner 970 is not explicitly listed (it may not have existed when SubMusic was last updated), the SDK version compatibility suggests it would work. SubMusic requires **Connect IQ SDK 4.0.0 minimum** and builds with SDK 4.1.6+, while modern Garmin devices support SDK 4.2.0+.

The build configuration uses a **monkey.jungle file** that specifies device-specific build targets, allowing compilation of device-optimized binaries from a single codebase. Adding Forerunner 970 support would likely require updating the jungle file with the device's identifier and testing for any device-specific quirks. The app's architecture is device-agnostic aside from screen size considerations and hardware capability detection (e.g., album art support).

Development setup requires the Connect IQ SDK, Visual Studio Code with the Monkey C extension (or Eclipse with Connect IQ plugin), and Java Runtime. The build process produces `.prg` files for each target device and supports publishing to the Garmin Connect IQ Store (SubMusic's Store ID: 600bd75f-6ccf-4ca5-bc7a-0a4fcfdcf794).

## Reusable UI components simplify development

SubMusic's UI follows standard Garmin navigation patterns with a clear hierarchy: Main Menu containing Select Playlists (browse server), Synced Playlists (offline content), Settings (API backend selection, server configuration, connection testing), and Sync Menu. The interface uses Garmin's native menu system, list views for browsing playlists and tracks, standard audio playback controls, and progress indicators for sync operations.

These UI components are API-agnostic and fully transferable to a dedicated Plex app. The playback interface includes play/pause controls, track information display, progress indicators, shuffle/repeat options, and podcast mode toggle—all standard features that work identically regardless of backend API. Error message dialogs, settings screens, and navigation patterns are similarly reusable.

The codebase structure separates UI views from business logic, making it straightforward to customize the interface while retaining proven sync and networking implementations. For a Plex-focused app, the UI could be simplified by removing multi-backend selection and focusing exclusively on Plex-specific features like advanced transcoding controls, Plex playlist creation, or integration with Plex's powerful search and recommendation engines.

## Critical implementation insights from production usage

SubMusic's issue tracker and documentation reveal important lessons from production deployment. The app enforces **HTTPS with valid certificates** because Garmin's firmware validates certificate authorities and TLS cipher suites strictly. Users commonly encounter **Error 0** when server addresses have typos, HTTPS isn't enabled, or certificates aren't properly signed. The recommended approach is using Let's Encrypt for certificates.

The **~25 song playlist limit** for Subsonic API is an SDK/API limitation that doesn't affect Plex as severely due to better pagination support. However, the app still implements partial sync and chunking strategies that are valuable for large Plex libraries. Network timeout handling is critical—Error -300 (timeout) requires retry logic and sometimes manual WiFi reconnection through watch settings.

Battery management is a key consideration for wearable apps. SubMusic carefully manages WiFi connections, ensuring they close properly after sync to prevent battery drain. The app also demonstrates **how to test API connections** before syncing, validating server reachability and authentication to prevent wasted sync attempts.

Testing insights reveal that the **Connect IQ simulator has limitations**—`makeWebRequest()` behaves differently in sync mode on simulators versus real devices, making physical device testing essential for reliable development. The community has validated SubMusic on actual hardware across dozens of device models, providing confidence in the architectural patterns.

## Conclusion: Fork SubMusic for rapid Plex app development

SubMusic eliminates the need for greenfield Plex app development on Garmin Connect IQ by providing a production-validated reference implementation with working Plex support. The optimal approach is forking or closely referencing SubMusic's architecture, enhancing Plex-specific functionality, and potentially simplifying the UI by removing multi-backend support. The provider abstraction, sync patterns, networking layer, and storage management are all proven and reusable.

The repository's true value lies not just in having Plex code, but in demonstrating solutions to Garmin-specific constraints: HTTPS enforcement, certificate validation, storage limitations, WiFi management, SDK quirks like fake sync from wrong contexts, and device compatibility patterns. These lessons would take months to learn through trial and error.

For Forerunner 970 specifically, the path forward is straightforward: update device compatibility lists, test on hardware (simulator testing is insufficient), leverage existing transcoding support, and potentially enhance Plex-specific features like library organization, artist radio, or integration with Plex's rich metadata. The architecture supports these enhancements while maintaining the core sync and playback functionality that already works reliably across 30+ Garmin devices.