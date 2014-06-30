module chartzone.youtube;

import chartzone.db;

import vibe.vibe;
import std.string;
import std.array : replace;
/**
	Module provides functions to talk to the youtube data api
*/
debug import std.stdio;

private enum RefreshToken = "1/v4UeHKbO5ucVxE1jtKjphc3mUK9UGqaegJF2xS6C4Dg";
private enum ClientID = "1018084892284-tbe2rk62ri4jcs8arjlp6escslqlafl8.apps.googleusercontent.com";
private enum ClientSecret = "daz7Em_mx7FsqlBGOnHIwjCO";

private static YoutubeToken youtubeToken;

/**
* Module constructor to setup the youtubeToken at startup time
*/
shared static this(){
	writefln("Setting up youtube module");
	// get the youtube token from the DB.
	auto db = new ChartzoneDB("chartzone", "youtube");

	auto data = db.collection.find().sort(["timestamp" : -1]);
	if(data.empty){
		debug writefln("Nothing in DB, enterying a new one youtube entry in %s.%s", "chartzone", "youtube");
		youtubeToken = getRefreshToken;
		db.collection.insert(youtubeToken);
		return;
	}
	auto bsonObj = data.front;
	writefln("%s", bsonObj);
	youtubeToken.deserializeBson(bsonObj);

	debug writefln("From DB: %s", youtubeToken);
}

/**
 Function checks if we need to update the current token, and if so, goes and does it
 */
public void checkAndUpdateYoutubeToken(){
	// connect to db
	auto db = new ChartzoneDB("chartzone", "youtube");
	writefln("Checking if token expired: %s", youtubeToken);
	if(youtubeToken.isExpired){

		YoutubeToken oldTok = youtubeToken;
		youtubeToken = getRefreshToken;
		db.collection.update(
			[
				"access_token" : Bson(oldTok.access_token), 
				"timestamp" : Bson(oldTok.timestamp)
			], 
			youtubeToken, 
			UpdateFlags.None);
	}
}

/**
 * Returns a JSON object containing the result from youtube.
 */
public Json searchFor(string name, string orderBy="relevance"){
	checkAndUpdateYoutubeToken();
	name.replace(" ", "%20");
	// construct the url to send
	string url = format("https://www.googleapis.com/youtube/v3/search?part=id&type=video&order=%s&q=%s&access_token=%s", 
		orderBy, name, youtubeToken.access_token);
	debug stderr.writefln("Sending: %s", url);
	auto response = requestHTTP(url, (scope req){
		});
	string responseStr = response.bodyReader.readAllUTF8;
	debug stderr.writefln("---\nGot: %s\nfrom youtube\n---;", responseStr);
	return responseStr.parseJsonString;
}

/**
* Returns a new YoutubeToken
*/
public YoutubeToken getRefreshToken(){
    string dataToSend =
        format("client_id=%s&client_secret=%s&refresh_token=%s&grant_type=%s",
                ClientID,
                ClientSecret,
                RefreshToken,
                "refresh_token");

    auto response = requestHTTP("https://accounts.google.com/o/oauth2/token",
        (scope req){
            req.method = HTTPMethod.POST;
            req.contentType = "application/x-www-form-urlencoded";
            req.writeBody(cast(ubyte[])dataToSend);
            }).bodyReader.readAllUTF8().parseJsonString;
    debug writefln("%s", response);
    return YoutubeToken(response["access_token"].get!string, response["expires_in"].get!long, response["token_type"].get!string );
}


/*
    Data structure that holds information on youtube api token
*/
public struct YoutubeToken{
    string access_token;
    ulong timestamp; // timestamp this token was created (in hnsecs, i.e 100 nano seconds)
    ulong expires_in; // milliseconds
    string token_type;

    /**
        Constructs this chart entry
    */
    public this(string access_token, ulong expires_in, string token_type){
		this.access_token = access_token;
        this.token_type = token_type;
        this.expires_in = expires_in;
        this.timestamp = Clock.currStdTime().stdTimeToUnixTime;
    }

    @property bool isExpired(){
        return (this.timestamp + expires_in) > Clock.currStdTime().stdTimeToUnixTime;
    }
}

