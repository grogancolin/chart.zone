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
import std.array;
import std.algorithm;

/**
	Module provides functions to talk to the soundcloud api
*/
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
	auto tmp = File("tmpOut.txt", "w");


	if(response.canFind(`[{"kind":"track"`)){

		auto parsedJson = response.parseJsonString;
		Json max = parsedJson[0]; // guess the current max 
		for(int i=0; i<parsedJson.length; i++){
			if(parsedJson[i].playback_count > max.playback_count){
				max = parsedJson[i];
			}
		}
		return max.uri.to!string;
	}
	return "unknown_id";

}

public string searchSoundcloud(SongEntry song){
    return searchSoundcloud(song.songname ~ " " ~ song.artist);
}
