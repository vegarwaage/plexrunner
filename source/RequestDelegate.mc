using Toybox.Communications;
using Toybox.Lang;
using Toybox.PersistedContent;

// ABOUTME: RequestDelegate injects context argument into web request callback
// ABOUTME: Allows passing context data through async HTTP requests

class RequestDelegate {

    hidden var mCallback;
    hidden var mContext;

    function initialize(callback, context) {
        mCallback = callback;
        mContext = context;
    }

    // Perform web request with callback
    function makeWebRequest(url, params, options) {
        Communications.makeWebRequest(url, params, options, self.method(:onWebResponse));
    }

    // Forward response with context
    function onWebResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null) as Void {
        mCallback.invoke(responseCode, data, mContext);
    }
}
