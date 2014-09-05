module chartzone.youtube;

import chartzone.utils;
import chartzone.settings;
import chartzone.utils;
import chartzone.db;

import vibe.vibe;
import std.string;
import std.array : replace;
import std.uri : encode;
import std.stdio;

/**
 * Module provides functions to talk to the youtube data api
 */

private YoutubeCredentials credentials;
private static YoutubeToken youtubeToken;
private ChartzoneSettings chartzoneSettings;

/**
* Module constructor to setup the global variables at startup time - called by main
*/
public void setupYoutubeModule(ChartzoneSettings settings){

    // read the settings file
	chartzoneSettings = settings;

	// get the youtube token from the DB.
	auto db = new ChartzoneDB(chartzoneSettings.dbName);
	auto credObj =  db.youtubeCredentials.find();
    if(credObj.empty()){
    	string line;
    	bool confirmation = false;
    	string _clientId, _clientSecret, _refreshToken, _publicApiKey;
    	writefln("Seems to be the first time you've run this. Prompting for youtube information...");
    	// prompt user for information
    	do{
    		write("Enter the Client ID: ");
    		readf(" %s\n", &_clientId);

	    	write("Enter the Client Secret: ");
	    	readf(" %s\n", &_clientSecret);

	    	write("Enter the Refresh Token: ");
	    	readf(" %s\n", &_refreshToken);

            write("Enter the public API key: ");
            readf(" %s\n", &_publicApiKey);

	    	writef("You entered:\n\tClient ID: %s\n\tClient Secret: %s\n\tRefresh Token: %s\n\tPublic Api Key: %s\nIs this correct? (y/n/quit) ",
	    		_clientId, _clientSecret, _refreshToken, _publicApiKey);

	    	readf(" %s\n", &line);
    		switch(line){
    			case "y": confirmation = true; break;
    			case "n": confirmation = false; break;
    			case "quit": // exit the program
    				import core.stdc.stdlib;
    				exit(1); break;
    			default: break;
    		}
    	} while(confirmation ==false);

    	credentials = YoutubeCredentials(_refreshToken, _clientId, _clientSecret, _publicApiKey);
    	db.youtubeCredentials.insert(credentials);

    } else{
    	credentials.deserializeBson(credObj.front());
    }

	auto data = db.youtube.find().sort(["timestamp" : -1]);
	if(data.empty){
		youtubeToken = getRefreshToken;
		db.youtube.insert(youtubeToken);
		return;
	}
	auto bsonObj = data.front;
	youtubeToken.deserializeBson(bsonObj);
}

/**
 * Function checks if we need to update the current token, and if so, goes and does it
 */
public void checkAndUpdateYoutubeToken(){
	auto db = new ChartzoneDB(chartzoneSettings.dbName);
	if(youtubeToken.isExpired){
        logInfo("Token is expired. Getting a new one: %s", youtubeToken);
		YoutubeToken oldTok = youtubeToken;
		youtubeToken = getRefreshToken;
		/+db.youtube.update(
			[
				"access_token" : Bson(oldTok.access_token),
				"timestamp" : Bson(oldTok.timestamp)
			],
			youtubeToken,
			UpdateFlags.None); +/
			db.update([
				"access_token" : Bson(oldTok.access_token),
				"timestamp" : Bson(oldTok.timestamp)
			], youtubeToken);

	}
}

/**
 * Returns a new YoutubeToken
 */
public YoutubeToken getRefreshToken(){
    string url = "https://accounts.google.com/o/oauth2/token";

    string postBody = "client_id=$CLIENT_ID$&client_secret=$CLIENT_SECRET$&refresh_token=$REFRESH_TOKEN$&grant_type=$GRANT_TYPE$"
            .replaceMap(
                [
                    "$CLIENT_ID$" : credentials.clientID,
                    "$CLIENT_SECRET$" : credentials.clientSecret,
                    "$REFRESH_TOKEN$" : credentials.refreshToken,
                    "$GRANT_TYPE$" : "refresh_token"
                ]
            );

    logInfo("Getting new refresh token with URL: %s and postBody: %s", url, postBody);

    auto response = requestHTTP(url,
        (scope req){
            req.method = HTTPMethod.POST;
            req.contentType = "application/x-www-form-urlencoded";
            req.writeBody(cast(ubyte[])postBody);
        }).bodyReader.readAllUTF8().parseJsonString;

    return YoutubeToken(response["access_token"].get!string, response["expires_in"].get!long, response["token_type"].get!string );
}

/**
 * Update youtube credentials
 */
public void updateYoutubeCredentials(YoutubeCredentials old, YoutubeCredentials newCredentials){
	auto db = new ChartzoneDB(chartzoneSettings.dbName);
    db.update(
        [   "refreshToken" : Bson(old.refreshToken),
            "clientID" : Bson(old.clientID),
            "clientSecret" : Bson(old.clientSecret)
		],
        newCredentials);

    YoutubeCredentials testObj;
    testObj.deserializeBson(db.youtubeCredentials.find().front);
	if(newCredentials == testObj){
		logError("Couldnt update youtube credentials. Quitting.");
		throw new Exception("Couldnt update youtube credentials...");
	}
    credentials = testObj;
}

/**
 * Returns a JSON object containing the result from youtube.
 */
public Json searchFor(string name, string regionCode="ie", string orderBy="relevance", string type="video"){
	logInfo("Searching youtube for: %s", name);

	// construct the url to send
	string url = "https://www.googleapis.com/youtube/v3/search?part=id,snippet&order=$ORDERBY$&q=$SEARCHFOR$&regionCode=$regionCode$&type=$TYPE$&key=$PUBLIC_API_KEY$"
            .replaceMap(
            ["$ORDERBY$" : orderBy,
            "$SEARCHFOR$" : name,
            "$regionCode$" : regionCode,
            "$TYPE$" : type,
            "$PUBLIC_API_KEY$" : credentials.publicApiKey]).
		encode;

	logDebug("Youtube search URL: %s", url);
	auto response = parseJsonString(requestHTTP(url, (scope req){}).bodyReader.readAllUTF8);
    return response;
}

public Json searchFor(SongEntry song, string regionCode="ie", string orderBy="relevance", string type="video"){
        string songname = song.songname;
        string artist;
        if(songname.canFind(",")){
                songname = songname[0..songname.indexOf(",")];
        }
        if(artist.canFind(",")){
                artist = artist[0..artist.indexOf(",")];
        }
        return searchFor(songname ~ " " ~ artist, regionCode, orderBy, type);

}

/**
* Adds the video with id=id to playlist
* According to youtube api doc, a POST to googleapis.com/youtube/v3/playlists
* a playlist will create
*/
public Json addVideoToPlaylist(string playlistId, string videoId){
    //Check token is up to date
    //checkAndUpdateYoutubeToken();
    string url = "https://www.googleapis.com/youtube/v3/playlistItems?part=$PART$&key=$API_KEY$&access_token=$ACCESS_TOKEN$"
    	.replaceMap(["$PART$" : "snippet,status",
                     "$API_KEY$" : credentials.publicApiKey,
                     "$ACCESS_TOKEN$" : youtubeToken.access_token]);

	Json testObj = parseJsonString(q{
		{
			"snippet" : {
				"playlistId" : $PLAYLISTID$,
				"resourceId" : {
					"kind" : "youtube#videoId",
					"videoId" : $VIDEOID
				}
			},
			"status" : {
				"privacyStatus" : "public"
			},
			"kind" : "youtube#playlistItem"
		}
	}.replaceMap([
		"$PLAYLISTID$" : playlistId,
		"$VIDEOID$" : videoId
	]));

	logDebug("addVideoToPlaylist payload: %s", testObj);
    auto response = requestHTTP(url, (scope req){
	        req.method = HTTPMethod.POST;
			req.writeJsonBody(testObj);
        }).bodyReader.readAllUTF8;

    logDebug("addVideoToPlaylist; Response: %s", response.parseJsonString );
    return response.parseJsonString;
}

/**
* Adds videos to playlist
*/
public string createPlaylist(string playlistName){

	logDebug("Creating playlist with name: %s", playlistName);
    checkAndUpdateYoutubeToken();
    string url = "https://www.googleapis.com/youtube/v3/playlists?part=$PART$&access_token=$ACCESS_TOKEN$"
        .replaceMap(["$PART$" : "snippet,status",
                     "$ACCESS_TOKEN$" : youtubeToken.access_token]);

    logDebug("Creating playlist with url: %s", url);
    auto response = requestHTTP(url, (scope req){
            req.method = HTTPMethod.POST;
            req.writeJsonBody(["snippet": ["title" : playlistName], "status" : ["privacyStatus" : "public"]]);
        }).bodyReader.readAllUTF8;

    //Return the new playlists ID as string
    string playListId = response.parseJsonString.id.to!string;
    logInfo("Playlist name, Playlist Id : %s, %s", playlistName, playListId);

    //ERROR CHECKING NEEDS TO BE DONE
    /*if(playListId.length > 0){
        logInfo("JSON RESPONSE WAS : %s", response);
        throw new JsonResponseException("There was an error creatin the playlist");
    }*/

    return playListId;
}

/**
 * Creates a playlist from a ChartEntry object
 * TODO add fix for iterating over the 5 songs incase
 * */
public string createPlaylist(ChartEntry chart){
	string playlistId = createPlaylist(chart.name.getYoutubePlaylistTitle);
	foreach(song; chart.songs){
		if(song.youtubeIds[0] == "unknown-id"){
			logInfo("Creating playlist -> Skipping: %s", song.songname);
			continue;
		}
		logDebug("Creating playlist -> Adding: %s", song.songname);
		playlistId.addVideoToPlaylist(song.youtubeIds[0]);
	}
	return playlistId;

}

