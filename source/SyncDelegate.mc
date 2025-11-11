using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Media;
using Toybox.System;
using PlexApi;
using PlexConfig;
using AudiobookStorage;

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

        // Get sync list from Application.Properties (set by Garmin Connect)
        mSyncList = Application.Properties.getValue("syncList");
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
            Media.notifySyncComplete(null);
            return;
        }

        // Get next audiobook ratingKey
        var ratingKey = mSyncList[0] as Lang.String;
        System.println("Fetching metadata for audiobook: " + ratingKey);

        // Fetch metadata from Plex
        var url = PlexConfig.getServerUrl() + "/library/metadata/" + ratingKey;
        var params = {"X-Plex-Token" => PlexConfig.getAuthToken()};
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
        // Expected structure: {MediaContainer: {Metadata: [{...}]}}
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
        var author = audiobook["grandparentTitle"]; // Artist/author name
        var duration = audiobook["duration"];

        // Extract parts/chapters
        var mediaParts = audiobook["Media"];
        if (mediaParts == null || !(mediaParts instanceof Lang.Array)) {
            Media.notifySyncComplete("No audio files found");
            return;
        }

        mCurrentChapters = [] as Lang.Array;

        for (var i = 0; i < mediaParts.size(); i++) {
            var media = mediaParts[i] as Lang.Dictionary;
            var parts = media["Part"];
            if (parts != null && (parts instanceof Lang.Array)) {
                for (var j = 0; j < parts.size(); j++) {
                    var part = parts[j] as Lang.Dictionary;
                    var chapter = {
                        :partId => part["id"],
                        :key => part["key"],
                        :duration => part["duration"],
                        :size => part["size"],
                        :title => "Chapter " + (mCurrentChapters.size() + 1)
                    };
                    mCurrentChapters.add(chapter);
                }
            }
        }

        // Store audiobook info
        mCurrentAudiobook = {
            :ratingKey => context[:ratingKey],
            :title => title,
            :author => author,
            :duration => duration,
            :tracks => [] as Lang.Array // Will populate with ContentRef IDs
        };

        mCurrentChapterIndex = 0;
        mTotalItems = mSyncList.size() + mCurrentChapters.size();

        System.println("Found " + mCurrentChapters.size() + " chapters, starting download");

        // Start downloading chapters
        downloadNextChapter();
    }

    // Download next chapter for current audiobook
    private function downloadNextChapter() as Void {
        if (mCurrentChapterIndex >= mCurrentChapters.size()) {
            // All chapters downloaded, save audiobook
            System.println("All chapters downloaded for audiobook");
            AudiobookStorage.saveAudiobook(mCurrentAudiobook);

            // Remove from sync list
            mSyncList.remove(mSyncList[0]);
            Application.Properties.setValue("syncList", mSyncList);

            updateProgress();

            // Move to next audiobook
            syncNextAudiobook();
            return;
        }

        var chapter = mCurrentChapters[mCurrentChapterIndex] as Lang.Dictionary;
        var partKey = chapter[:key] as Lang.String;

        System.println("Downloading chapter " + (mCurrentChapterIndex + 1) + "/" + mCurrentChapters.size());

        // Download audio file
        var url = PlexConfig.getServerUrl() + partKey;
        var params = {"X-Plex-Token" => PlexConfig.getAuthToken()};
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => Media.ENCODING_MP3
        };

        var context = {:chapterIndex => mCurrentChapterIndex};
        var delegate = new RequestDelegate(method(:onChapterDownloaded), context);
        delegate.makeWebRequest(url, params, options);
    }

    // Callback when chapter is downloaded
    function onChapterDownloaded(responseCode as Lang.Number, data as Media.Content or Null, context as Lang.Dictionary) as Void {
        if (responseCode != 200 || data == null) {
            System.println("Failed to download chapter: " + responseCode);
            Media.notifySyncComplete("Failed to download chapter (code " + responseCode + ")");
            return;
        }

        var chapterIndex = context[:chapterIndex] as Lang.Number;
        System.println("Chapter " + (chapterIndex + 1) + " downloaded");

        // Store Content ID
        var chapter = mCurrentChapters[chapterIndex] as Lang.Dictionary;
        var contentRef = data.getContentRef();
        chapter[:refId] = contentRef.getId();
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
