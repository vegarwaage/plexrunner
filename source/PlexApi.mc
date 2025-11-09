using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

// ABOUTME: Plex API HTTP communication module for PIN-based authentication
// ABOUTME: Handles requests to plex.tv with proper headers and JSON response parsing

module PlexApi {

    // Shared callback storage (module-level state)
    var _pinSuccessCallback = null;
    var _pinErrorCallback = null;
    var _pinCheckSuccessCallback = null;
    var _pinCheckErrorCallback = null;
    var _authSuccessCallback = null;
    var _authErrorCallback = null;

    // Request PIN for authentication
    // Callback signature: onSuccess(responseCode, data), onError(responseCode, error)
    function requestPin(onSuccess, onError) {
        _pinSuccessCallback = onSuccess;
        _pinErrorCallback = onError;

        var url = "https://plex.tv/api/v2/pins?strong=true";

        var headers = {
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
            null,
            options,
            new Lang.Method(PlexApi, :handlePinResponse)
        );
    }

    // Handle PIN request response
    function handlePinResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        System.println("PIN Response Code: " + responseCode);

        if (responseCode == 200 || responseCode == 201) {
            if (data != null) {
                System.println("PIN received successfully");
                if (_pinSuccessCallback != null) {
                    _pinSuccessCallback.invoke(responseCode, data);
                }
            } else {
                var error = "PIN response data is null";
                System.println(error);
                if (_pinErrorCallback != null) {
                    _pinErrorCallback.invoke(responseCode, error);
                }
            }
        } else {
            var error = "Failed to get PIN. Response code: " + responseCode;
            System.println(error);
            if (_pinErrorCallback != null) {
                _pinErrorCallback.invoke(responseCode, error);
            }
        }
    }

    // Check PIN status for auth token
    // Callback signature: onSuccess(responseCode, data), onError(responseCode, error)
    function checkPinStatus(pinId, onSuccess, onError) {
        if (pinId == null) {
            if (onError != null) {
                onError.invoke(400, "PIN ID is null");
            }
            return;
        }

        _pinCheckSuccessCallback = onSuccess;
        _pinCheckErrorCallback = onError;

        var url = "https://plex.tv/api/v2/pins/" + pinId;

        var headers = {
            "X-Plex-Product" => "PlexRunner",
            "X-Plex-Version" => "0.1.0",
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
            new Lang.Method(PlexApi, :handlePinCheckResponse)
        );
    }

    // Handle PIN check response
    function handlePinCheckResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        System.println("PIN Check Response Code: " + responseCode);

        if (responseCode == 200) {
            if (data != null) {
                if (_pinCheckSuccessCallback != null) {
                    _pinCheckSuccessCallback.invoke(responseCode, data);
                }
            } else {
                var error = "PIN check response data is null";
                System.println(error);
                if (_pinCheckErrorCallback != null) {
                    _pinCheckErrorCallback.invoke(responseCode, error);
                }
            }
        } else {
            var error = "Failed to check PIN. Response code: " + responseCode;
            System.println(error);
            if (_pinCheckErrorCallback != null) {
                _pinCheckErrorCallback.invoke(responseCode, error);
            }
        }
    }

    // Make authenticated request to Plex server
    // Callback signature: onSuccess(responseCode, data), onError(responseCode, error)
    function makeAuthenticatedRequest(path, onSuccess, onError) {
        var token = PlexConfig.getAuthToken();
        if (token == null) {
            if (onError != null) {
                onError.invoke(401, "Not authenticated");
            }
            return;
        }

        _authSuccessCallback = onSuccess;
        _authErrorCallback = onError;

        var url = PlexConfig.getServerUrl() + path;

        var headers = {
            "X-Plex-Token" => token,
            "X-Plex-Client-Identifier" => PlexConfig.getClientId(),
            "X-Plex-Product" => "PlexRunner",
            "X-Plex-Version" => "0.1.0",
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
            new Lang.Method(PlexApi, :handleAuthenticatedResponse)
        );
    }

    // Handle authenticated request response
    function handleAuthenticatedResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        System.println("Authenticated Request Response Code: " + responseCode);

        if (responseCode == 200) {
            if (data != null) {
                if (_authSuccessCallback != null) {
                    _authSuccessCallback.invoke(responseCode, data);
                }
            } else {
                var error = "Authenticated response data is null";
                System.println(error);
                if (_authErrorCallback != null) {
                    _authErrorCallback.invoke(responseCode, error);
                }
            }
        } else {
            var error = "Request failed. Response code: " + responseCode;
            System.println(error);
            if (_authErrorCallback != null) {
                _authErrorCallback.invoke(responseCode, error);
            }
        }
    }
}
