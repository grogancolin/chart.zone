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
    //	debug writefln("Sending ----\n%s\n---- to soundcloud;", url);
	writefln("Search URL: %s", url);
	auto response = parseJsonString(requestHTTP(url, (scope req){}).bodyReader.readAllUTF8);
	debug writefln("---\nGot: %s\nfrom soundcloud\n---;", response);
    //Return the first songs track URL
    return response[0].uri.to!string;
}

public string searchSoundcloud(SongEntry song){
    return searchSoundcloud(song.songname ~ " " ~ song.artist);
}
