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
public Json[] searchSoundcloud(string query){

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
		/*
		//Bubble sort and then take the top 5
		bool loop = true;
		while (loop) {
			loop = false;
			for (uint i=0; i<parsedJson.length-1; i++) {
				if(parsedJson[i].playback_count > parsedJson[i+1].playback_count) {
					Json temp = parsedJson[i];
					parsedJson[i] = parsedJson[i+1];
					parsedJson[i+1] = temp;
					loop = true;
				}
			}
		}
		*/
		if(parsedJson.length < 5)
			return parsedJson[0..parsedJson.length-1];
		else
			return parsedJson[0..4];
	}

	//Return an empty array with object that contains unknown_url fields
	Json[] emptyResArr;
	emptyResArr ~= Json.emptyObject;
	emptyResArr[0].uri = "unknown_url";
	emptyResArr[0].artwork_url = "unknown_url";
	return emptyResArr;

}

public Json[] searchSoundcloud(SongEntry song){
    return searchSoundcloud(song.songname ~ " " ~ song.artist);
}
