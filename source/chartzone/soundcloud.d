module chartzone.soundcloud;

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
	Module provides functions to talk to the soundcloud api
*/
import std.stdio;

/**
 * Returns a JSON object containing the result from soundcloud.
 */
public string searchSoundcloud(string query){

    string clientId = "4346c8125f4f5c40ad666bacd8e96498";


	// construct the url to send
	string url = "http://api.soundcloud.com/tracks.json?client_id=$CLIENT_ID$&q=$QUERY$&limit=50"
            .replaceMap(
            ["$CLIENT_ID$" : clientId,
             "$QUERY$"     : query])
            .encode;
			
	auto response = requestHTTP(url, (scope req){}).bodyReader.readAllUTF8;
    //Return the first songs track URL
	logDebug("Soundloud request: %s -> %s", url, response);

	string shouldStartWith = `[{"kind":"track"`;
	if(response.startsWith(shouldStartWith)){
		return parseJsonString(response)[0].uri.to!string;
	}
	return "unknown_id";

}

public string searchSoundcloud(SongEntry song){
    return searchSoundcloud(song.songname ~ " " ~ song.artist);
}
