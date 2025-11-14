using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Media;
using Toybox.System;
using PlexApi;
using PlexConfig;
using AudiobookStorage;
using PositionSync;

// ABOUTME: SyncDelegate handles audiobook downloads from Plex server
// ABOUTME: Triggered by Garmin Connect when user selects audiobooks to sync

class SyncDelegate extends Communications.SyncDelegate {

    // List of audiobook ratingKeys to sync (from Garmin Connect)
    private var mSyncList;
    // Total items to sync (audiobooks + chapters)
    private var mTotalItems;
    // Items synced so far
    private var mItemsSynced;
    // Current audiobook being synced
    private var mCurrentAudiobook;
    // Chapters for current audiobook
    private var mCurrentChapters;
    // Current chapter index
    private var mCurrentChapterIndex;

    function initialize() {
        SyncDelegate.initialize();

        // Get sync list from Application.Storage
        mSyncList = Application.Storage.getValue("syncList");
        if (mSyncList == null || !(mSyncList instanceof Lang.Array)) {
            mSyncList = [] as Lang.Array;
        }

        mItemsSynced = 0;
        mTotalItems = 0;
        mCurrentAudiobook = null;
        mCurrentChapters = [] as Lang.Array;
        mCurrentChapterIndex = 0;
    }

    // Called when sync starts
    function onStartSync() as Void {
        System.println("Starting sync with " + mSyncList.size() + " audiobooks");

        if (mSyncList.size() == 0) {
            Media.notifySyncComplete(null);
            return;
        }

        // Start syncing first audiobook
        syncNextAudiobook();
    }

    // Check if sync is needed
    function isSyncNeeded() as Lang.Boolean {
        return mSyncList.size() > 0;
    }

    // Called when user cancels sync
    function onStopSync() as Void {
        System.println("Sync cancelled by user");
        Communications.cancelAllRequests();
        Media.notifySyncComplete("Sync cancelled");
    }

    // Fetch metadata for next audiobook in sync list
    private function syncNextAudiobook() as Void {
        if (mSyncList.size() == 0) {
            System.println("Sync complete!");

            // Trigger opportunistic position sync after audiobook sync completes
            if (PlexConfig.isAuthenticated()) {
                System.println("Syncing positions to Plex after successful audiobook sync");
                PositionSync.syncAllPositions();
            }

            Media.notifySyncComplete(null);
            return;
        }

        // Get next audiobook ratingKey
        var ratingKey = mSyncList[0] as Lang.String;
        System.println("Fetching metadata for audiobook: " + ratingKey);

        // Fetch metadata from Plex
        var serverUrl = PlexConfig.getServerUrl();
        var authToken = PlexConfig.getAuthToken();
        System.println("DEBUG: Server URL: " + serverUrl);
        System.println("DEBUG: Auth token length: " + authToken.length());

        var url = serverUrl + "/library/metadata/" + ratingKey;
        System.println("DEBUG: Full URL: " + url);
        var params = {"X-Plex-Token" => authToken};
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Accept" => "application/json"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var context = {:ratingKey => ratingKey};
        var delegate = new RequestDelegate(method(:onAudiobookMetadata), context);
        delegate.makeWebRequest(url, params, options);
    }

    // Callback when audiobook metadata is fetched
    function onAudiobookMetadata(responseCode as Lang.Number, data as Lang.Dictionary or Null, context as Lang.Dictionary) as Void {
        if (responseCode != 200 || data == null) {
            System.println("Failed to fetch metadata: " + responseCode);
            Media.notifySyncComplete("Failed to fetch audiobook metadata (code " + responseCode + ")");
            return;
        }

        System.println("Metadata received for: " + context[:ratingKey]);

        // Parse audiobook metadata
        var container = data["MediaContainer"];
        if (container == null) {
            Media.notifySyncComplete("Invalid metadata response");
            return;
        }

        var metadata = container["Metadata"];
        if (metadata == null || !(metadata instanceof Lang.Array) || metadata.size() == 0) {
            Media.notifySyncComplete("No audiobook found");
            return;
        }

        var audiobook = metadata[0] as Lang.Dictionary;

        // Extract audiobook info
        var title = audiobook["title"];
        var author = audiobook["parentTitle"]; // Parent is the artist/author

        // Store audiobook metadata for later use
        mCurrentAudiobook = {
            :ratingKey => context[:ratingKey],
            :title => title,
            :author => author
        };

        // Audiobooks have children (tracks), fetch them
        var childrenKey = audiobook["key"];
        if (childrenKey == null) {
            Media.notifySyncComplete("No children key found");
            return;
        }

        System.println("Fetching children for audiobook: " + childrenKey);

        // Fetch children (tracks/chapters)
        var url = PlexConfig.getServerUrl() + childrenKey;
        var params = {"X-Plex-Token" => PlexConfig.getAuthToken()};
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Accept" => "application/json"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var childrenContext = {:ratingKey => context[:ratingKey]};
        var delegate = new RequestDelegate(method(:onAudiobookChildren), childrenContext);
        delegate.makeWebRequest(url, params, options);
    }

    // Callback when audiobook children (tracks) are fetched
    function onAudiobookChildren(responseCode as Lang.Number, data as Lang.Dictionary or Null, context as Lang.Dictionary) as Void {
        if (responseCode != 200 || data == null) {
            System.println("Failed to fetch children: " + responseCode);
            Media.notifySyncComplete("Failed to fetch audiobook tracks (code " + responseCode + ")");
            return;
        }

        System.println("Children received for: " + context[:ratingKey]);

        // Parse children (tracks)
        var container = data["MediaContainer"];
        if (container == null) {
            Media.notifySyncComplete("Invalid children response");
            return;
        }

        var tracks = container["Metadata"];
        if (tracks == null || !(tracks instanceof Lang.Array) || tracks.size() == 0) {
            Media.notifySyncComplete("No audio files found");
            return;
        }

        mCurrentChapters = [] as Lang.Array;

        // Process each track (handles both .m4b files and .mp3 files)
        for (var i = 0; i < tracks.size(); i++) {
            var track = tracks[i] as Lang.Dictionary;

            // Each track has Media → Part structure
            var mediaParts = track["Media"];
            if (mediaParts == null || !(mediaParts instanceof Lang.Array)) {
                continue; // Skip tracks without media
            }

            for (var j = 0; j < mediaParts.size(); j++) {
                var media = mediaParts[j] as Lang.Dictionary;
                var parts = media["Part"];
                if (parts != null && (parts instanceof Lang.Array)) {
                    for (var k = 0; k < parts.size(); k++) {
                        var part = parts[k] as Lang.Dictionary;
                        var fileFormat = part["container"]; // mp3, m4a, m4b, etc.
                        var chapter = {
                        :partId => part["id"],
                        :key => part["key"],
                        :duration => part["duration"],
                        :size => part["size"],
                        :format => fileFormat,
                        :title => "Chapter " + (mCurrentChapters.size() + 1)
                    };
                    mCurrentChapters.add(chapter);
                    }
                }
            }
        }

        // Add tracks array to existing audiobook metadata
        mCurrentAudiobook[:tracks] = [] as Lang.Array; // Will populate with ContentRef IDs

        mCurrentChapterIndex = 0;
        mTotalItems = mSyncList.size() + mCurrentChapters.size();

        System.println("Found " + mCurrentChapters.size() + " chapters, starting download");

        // Start downloading chapters
        downloadNextChapter();
    }

    // Convert container format to Media encoding constant
    private function getMediaEncoding(container as Lang.String or Null) as Media.Encoding {
        if (container == null) {
            return Media.ENCODING_MP3; // Default to MP3
        }

        if (container.equals("mp3")) {
            return Media.ENCODING_MP3;
        } else if (container.equals("m4a") || container.equals("m4b") || container.equals("mp4")) {
            return Media.ENCODING_M4A; // M4B/M4A are MP4 containers for audiobooks
        } else if (container.equals("wav")) {
            return Media.ENCODING_WAV;
        }

        // Default to MP3 for unknown formats
        System.println("Unknown container format: " + container + ", defaulting to MP3");
        return Media.ENCODING_MP3;
    }

    // Download next chapter for current audiobook
    private function downloadNextChapter() as Void {
        if (mCurrentChapterIndex >= mCurrentChapters.size()) {
            // All chapters downloaded, save audiobook
            System.println("All chapters downloaded for audiobook");
            AudiobookStorage.saveAudiobook(mCurrentAudiobook);

            // Remove from sync list
            mSyncList.remove(mSyncList[0]);
            Application.Storage.setValue("syncList", mSyncList);

            updateProgress();

            // Move to next audiobook
            syncNextAudiobook();
            return;
        }

        var chapter = mCurrentChapters[mCurrentChapterIndex] as Lang.Dictionary;
        var partKey = chapter[:key] as Lang.String;
        var fileFormat = chapter[:format]; // Get detected format

        System.println("Downloading chapter " + (mCurrentChapterIndex + 1) + "/" + mCurrentChapters.size());
        System.println("File format: " + fileFormat);

        // Download audio file with correct encoding
        var url = PlexConfig.getServerUrl() + partKey;
        System.println("Download URL: " + url);

        var encoding = getMediaEncoding(fileFormat);
        System.println("Using encoding: " + encoding);

        var params = {"X-Plex-Token" => PlexConfig.getAuthToken()};
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => encoding
        };

        var context = {:chapterIndex => mCurrentChapterIndex};
        var delegate = new RequestDelegate(method(:onChapterDownloaded), context);

        try {
            delegate.makeWebRequest(url, params, options);
        } catch (ex) {
            System.println("Exception initiating download: " + ex.getErrorMessage());
            Media.notifySyncComplete("Download error: " + ex.getErrorMessage());
        }
    }

    // Callback when chapter is downloaded
    function onChapterDownloaded(responseCode as Lang.Number, data as Media.Content or Null, context as Lang.Dictionary) as Void {
        var chapterIndex = context[:chapterIndex] as Lang.Number;

        if (responseCode != 200) {
            System.println("Download failed for chapter " + (chapterIndex + 1) + ": HTTP " + responseCode);
            Media.notifySyncComplete("Download failed: HTTP " + responseCode);
            return;
        }

        if (data == null) {
            System.println("Download failed for chapter " + (chapterIndex + 1) + ": No content received");
            Media.notifySyncComplete("Download failed: No content");
            return;
        }

        System.println("Chapter " + (chapterIndex + 1) + " downloaded successfully");

        // Store Content ID
        var chapter = mCurrentChapters[chapterIndex] as Lang.Dictionary;
        var contentRef = data.getContentRef();

        if (contentRef == null) {
            System.println("Error: No content reference for chapter " + (chapterIndex + 1));
            Media.notifySyncComplete("Download failed: No content reference");
            return;
        }

        var refId = contentRef.getId();
        if (refId == null) {
            System.println("Error: No content ID for chapter " + (chapterIndex + 1));
            Media.notifySyncComplete("Download failed: No content ID");
            return;
        }

        chapter[:refId] = refId;
        mCurrentChapters[chapterIndex] = chapter;

        // Add to audiobook tracks
        var tracks = mCurrentAudiobook[:tracks] as Lang.Array;
        tracks.add(chapter);
        mCurrentAudiobook[:tracks] = tracks;

        mCurrentChapterIndex++;
        mItemsSynced++;

        updateProgress();

        // Download next chapter
        downloadNextChapter();
    }

    // Update sync progress
    private function updateProgress() as Void {
        if (mTotalItems == 0) {
            return;
        }

        var progress = (mItemsSynced.toFloat() / mTotalItems.toFloat()) * 100;
        Media.notifySyncProgress(progress.toNumber());
        System.println("Sync progress: " + progress.toNumber() + "%");
    }
}
