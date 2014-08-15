module chartzone.youtube;

import chartzone.utils;
import mainMod = chartzone.main;
import chartzone.settings;

import vibe.vibe;
import std.string;
import std.array : replace;
import std.uri : encode;
/**
	Module provides functions to talk to the youtube data api
*/
import std.stdio;

//private enum RefreshToken = "1/v4UeHKbO5ucVxE1jtKjphc3mUK9UGqaegJF2xS6C4Dg";
//private enum ClientID = "1018084892284-tbe2rk62ri4jcs8arjlp6escslqlafl8.apps.googleusercontent.com";
//private enum ClientSecret = "daz7Em_mx7FsqlBGOnHIwjCO";
private YoutubeCredentials credentials;
private static YoutubeToken youtubeToken;

/**
* Module constructor to setup the global variables at startup time
*/
shared static this(){

    // read the settings file
    auto chartzoneSettings = new ChartzoneSettings();
    chartzoneSettings = parseSettingsFile(mainMod.settingsFile);

	// get the youtube token from the DB.
	auto db = new YoutubeDB(chartzoneSettings.dbName, chartzoneSettings.dbCollections["youtube"]);
    auto credDb = new YoutubeDB(chartzoneSettings.dbName, chartzoneSettings.dbCollections["youtubeCredentials"]);
    auto credObj = credDb.collection.find();
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
    	credDb.collection.insert(credentials);

    } else{
    	credentials.deserializeBson(credObj.front());
    }

	auto data = db.collection.find().sort(["timestamp" : -1]);
	if(data.empty){
		youtubeToken = getRefreshToken;
		db.collection.insert(youtubeToken);
		return;
	}
	auto bsonObj = data.front;
	youtubeToken.deserializeBson(bsonObj);
}

/**
 * Function checks if we need to update the current token, and if so, goes and does it
 */
public void checkAndUpdateYoutubeToken(){
	// connect to db
	auto db = new YoutubeDB("chartzone", "youtube");
	//writefln("Checking if token is expired: %s", youtubeToken.isExpired);
	if(youtubeToken.isExpired){
        debug writefln("Token is expired. Getting a new one: %s", youtubeToken);
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

    writefln("Getting new refresh token with URL: %s and postBody: %s", url, postBody);
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
    auto db = new YoutubeDB("chartzone", "youtubestatic");
    db.collection.update(
        [   "refreshToken" : Bson(old.refreshToken),
            "clientID" : Bson(old.clientID),
            "clientSecret" : Bson(old.clientSecret)],
            newCredentials, UpdateFlags.None);

    YoutubeCredentials testObj;
    testObj.deserializeBson(db.collection.find().front);
    assert(newCredentials == testObj, "Error: Couldnt update new credentials correctly.");
    credentials = testObj;
}

/**
 * Returns a JSON object containing the result from youtube.
 */
public string searchFor(string name){

    //These can be added as params later if needed
    string regionCode="ie";
    string orderBy="relevance";
    string type="video";

//    logInfo("In youtube.d search for");

	// construct the url to send
	string url = "https://www.googleapis.com/youtube/v3/search?part=id&order=$ORDERBY$&q=$SEARCHFOR$&regionCode=$regionCode$&type=$TYPE$&key=$PUBLIC_API_KEY$"
            .replaceMap(
            ["$ORDERBY$" : orderBy,
            "$SEARCHFOR$" : name,
            "$regionCode$" : regionCode,
            "$TYPE$" : type,
            "$PUBLIC_API_KEY$" : credentials.publicApiKey]).
		encode;

	auto response = parseJsonString(requestHTTP(url, (scope req){}).bodyReader.readAllUTF8);

	//return response.parseJsonString;
    //^^^^^Above can be used later when/if we find a better way of picking the correct song
    //Untill the just return the top song in the lists ID
    return response.items[0].id.videoId.to!string;
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


    Json obj = Json.emptyObject;
    obj.snippet = Json.emptyObject;
    obj.snippet.playlistId = playlistId;
    obj.snippet.resourceId = Json.emptyObject;
    obj.snippet.resourceId.kind = "youtube#video";
    obj.snippet.resourceId.videoId = videoId;
    obj.status = Json.emptyObject;
    obj.status.privacyStatus = "public";
    obj.kind = "youtube#playlistItem";

    auto response = requestHTTP(url, (scope req){
        req.method = HTTPMethod.POST;
        req.writeJsonBody(obj);
        }).bodyReader.readAllUTF8;
    logInfo("%s", response.parseJsonString );
    return response.parseJsonString;
}

/**
* Adds videos to playlist
*/
public string createPlaylist(string playlistName){

    checkAndUpdateYoutubeToken();
    string url = "https://www.googleapis.com/youtube/v3/playlists?part=$PART$&access_token=$ACCESS_TOKEN$"
        .replaceMap(["$PART$" : "snippet,status",
                     "$ACCESS_TOKEN$" : youtubeToken.access_token]);

    writefln("Creating playlist with url: %s", url);
    auto response = requestHTTP(url, (scope req){
            req.method = HTTPMethod.POST;
            req.writeJsonBody(["snippet": ["title" : playlistName], "status" : ["privacyStatus" : "public"]]);
        }).bodyReader.readAllUTF8;

    //Return the new playlists ID as string
    string playListId = response.parseJsonString.id.to!string;
    logInfo("%s", playListId);

    //ERROR CHECKING NEEDS TO BE DONE
    /*if(playListId.length > 0){
        logInfo("JSON RESPONSE WAS : %s", response);
        throw new JsonResponseException("There was an error creatin the playlist");
    }*/

    return playListId;
}
/*
 *  Data structure that holds information on youtube api token
 */
public struct YoutubeToken{
    string access_token;
    ulong timestamp; // timestamp this token was created (in hnsecs, i.e 100 nano seconds)
    ulong expires_in; // milliseconds
    string token_type;

    /**
     *  Constructs this chart entry
     */
    public this(string access_token, ulong expires_in, string token_type){
		this.access_token = access_token;
        this.token_type = token_type;
        this.expires_in = expires_in;
        this.timestamp = Clock.currStdTime().stdTimeToUnixTime;
    }

    @property bool isExpired(){
	long currTime = Clock.currStdTime().stdTimeToUnixTime();
	if(currTime < (this.timestamp + this.expires_in)){
		return false;
	}
	return true;
//        return (this.timestamp + expires_in) < Clock.currStdTime().stdTimeToUnixTime;
    }
}

/**
 * Data structure that holds long term youtube credentials
 */
public struct YoutubeCredentials{
    string refreshToken;    // 1/FLynZRsiKstzpO3m7aZ8EueSXw9hnNvtWTk0BiNvuOY
    string clientID;        // 1056916856143-7p19rpdd9ktf8phghf7ol10thbjuuaug.apps.googleusercontent.com
    string clientSecret;    // 5DnsSEMr-rn44Kh5sY8nYW-W
    string publicApiKey;    // AIzaSyBVIHtXsGgZi5epY7dunDHgX1fZKTgQ2Uw
}

/**
 * Class handles connections to the youtube mongo DB
 */
public class YoutubeDB{
private:
    MongoClient _client;
    MongoDatabase _db;
    MongoCollection _collection;
public:
    public this(string dbstr, string collstr){
        _client = connectMongoDB("127.0.0.1");
        _db = client.getDatabase(dbstr);
        _collection = db[collstr];
    }

    /*
    Getters for the db interface.
    No setters as these shouldnt need to be changed once set
    */
    public @property auto collection(){
        return _collection;
    }
    public @property auto db(){
        return _db;
    }
    public @property auto client(){
        return _client;
    }
}
