module chartzone.youtube;

import chartzone.utils;

import vibe.vibe;
import std.string;
import std.array : replace;
import std.uri : encode;
/**
	Module provides functions to talk to the youtube data api
*/
debug import std.stdio;

//private enum RefreshToken = "1/v4UeHKbO5ucVxE1jtKjphc3mUK9UGqaegJF2xS6C4Dg";
//private enum ClientID = "1018084892284-tbe2rk62ri4jcs8arjlp6escslqlafl8.apps.googleusercontent.com";
//private enum ClientSecret = "daz7Em_mx7FsqlBGOnHIwjCO";
private YoutubeCredentials credentials;
private static YoutubeToken youtubeToken;

/**
* Module constructor to setup the global variables at startup time
*/
shared static this(){

	// get the youtube token from the DB.
	auto db = new YoutubeDB("chartzone", "youtube");
    auto credDb = new YoutubeDB("chartzone", "youtubestatic");
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
 * Function checks if we need to update the current token, and if so, goes and does it
 */
public void checkAndUpdateYoutubeToken(){
	// connect to db
	auto db = new YoutubeDB("chartzone", "youtube");
	writefln("Checking if token is expired: %s", youtubeToken.isExpired);
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
public Json searchFor(string name, string orderBy="relevance"){
	checkAndUpdateYoutubeToken();
	
	// construct the url to send
	string url = "https://www.googleapis.com/youtube/v3/search?part=id&type=video&order=$ORDERBY$&q=$SEARCHFOR$&key=$PUBLIC_API_KEY$"
            .replaceMap(
            ["$ORDERBY$" : orderBy,
            "$SEARCHFOR$" : name,
            "$PUBLIC_API_KEY$" : credentials.publicApiKey]).
		encode;
    //	debug writefln("Sending ----\n%s\n---- to youtube;", url);
	writefln("Search URL: %s", url);
	auto response = requestHTTP(url, (scope req){}).bodyReader.readAllUTF8;
	debug writefln("---\nGot: %s\nfrom youtube\n---;", response);
	return response.parseJsonString;
}

/**
* Adds the video with id=id to playlist
* According to youtube api doc, a POST to googleapis.com/youtube/v3/playlists
* a playlist will create
*/
public Json addVideoToPlaylist(string[] videoIds){
    checkAndUpdateYoutubeToken();
    string url = "https://www.googleapis.com/youtube/v3/playlists?part=$PART$"
    	.replaceMap(["$PART$" : "snippet,status"]);

    auto response = requestHTTP(url, (scope req){

        }).bodyReader.readAllUTF8;
    return response.parseJsonString;
}

/**
* Adds videos to playlist
*/
public Json createPlaylist(string playlistName){
    checkAndUpdateYoutubeToken();
    string url = "https://www.googleapis.com/youtube/v3/playlists?part=$PART$&access_token=$ACCESS_TOKEN$"
        .replaceMap(["$PART$" : "snippet,status",
            "$ACCESS_TOKEN$" : youtubeToken.access_token]);

    string postBody = "snippet.title=$SNIPPET_TITLE$"
    	.replaceMap(["$SNIPPET_TITLE$" : playlistName]);

    writefln("Creating playlist with url: %s and postBody: %s", url, postBody);
    auto response = requestHTTP(url, (scope req){
            req.method = HTTPMethod.POST;
            req.writeBody(cast(ubyte[])postBody);
        }).bodyReader.readAllUTF8;
    return response.parseJsonString;
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
