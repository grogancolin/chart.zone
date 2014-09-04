/**
Module to interface with the DB.
*/
module chartzone.db;

import std.stdio;

//import chartzone.main : settingsFile;
import chartzone.datafetchers;
import chartzone.settings;

import vibe.vibe;

ChartzoneSettings settings;

void setupDBModule(ChartzoneSettings theSettings){
	settings = theSettings;
}

/**
	Handles the connections to chartzoneDB on mongo
*/
public class ChartzoneDB{
private:
	MongoClient _client;
	MongoDatabase _db;
	MongoCollection 
        _charts_coll,
        _youtube_coll,
        _youtubeCredentials_coll,
        _messages_coll
        ;
public:
	public this(string dbstr){
        auto allCols = settings.dbCollections;
		_client = connectMongoDB("127.0.0.1");
		_db = client.getDatabase(dbstr);
        _charts_coll = db[allCols["charts"]];
        _youtube_coll = db[allCols["youtube"]];
        _youtubeCredentials_coll = db[allCols["youtubeCredentials"]];
        _messages_coll = db[allCols["messages"]];
	}

	/*
	Getters for the db interface.
	No setters as these shouldnt need to be changed once set
	*/
	public @property auto db(){
		return _db;
	}
	public @property auto client() {
		return _client;
	}
    public @property auto charts()
    {
        return _charts_coll;
    }

    public @property auto youtube() {
        return _youtube_coll;
    }

    public @property auto youtubeCredentials() {
        return _youtubeCredentials_coll;
    }

    public @property auto messages() {
        return _messages_coll;
    }
}


public void add(Type)(ChartzoneDB db, Type entry){
    static if(Type.stringof == "ChartEntry"){
        db.charts.insert(entry);
    } else static if (Type.stringof =="MessageEntry"){
        db.messages.insert(entry);
    } else static if(Type.stringof == "YoutubeToken"){
        db.youtube.insert(entry);
    } else static if(Type.stringof == "YoutubeCredentials"){
        db.youtubeCredentials.insert(entry);
    } else{
        static assert(false, "Error: " ~ Type.stringof ~ " is not supported");
    }
}

/**
	Updates the chartentry with ID = oldID with the new chart entry

	Sample code to use
	// get the latest chart
	auto bbcTop40Chart = db.getLatestChart("BBC Top 40");
	bbcTop40Chart.songs ~= SongEntry(
			"ele[1].innerHTML",
			"ele[0].innerHTML",
			"NEW UTOOB ID",
			140,
			["BBC Top 40", "pop"]
			);

	db.update(bbcTop40Chart, bbcTop40Chart);
	TODO: NEED TO TEST
*/
public void update(Type)(ChartzoneDB db, Type oldentry, Type newentry){
	// should update the entry with oldID to be the new entry
    static if(Type.stringof == "ChartEntry"){
        db.charts.update(oldentry, newentry, UpdateFlags.None);
    } else if(Type.stringof =="MessageEntry"){
        db.messages.update(oldentry, newentry, UpdateFlags.None);
    } else if(Type.stringof == "YoutubeEntry"){
        db.youtube.update(oldentry, newentry, UpdateFlags.None);
    } else if(Type.stringof == "YoutubeCredentials"){
        db.youtubeCredentials.update(oldentry, newentry, UpdateFlags.None);
    } else{
        static assert(false, "Error: " ~ Type.stringof ~ " is not supported");
    }

}
public void update(Type)(ChartzoneDB db, Json selector, Type newentry){
	// should update the entry with oldID to be the new entry
    static if(Type.stringof == "ChartEntry"){
        db.charts.update(selector, newentry, UpdateFlags.None);
    } else if(Type.stringof =="MessageEntry"){
        db.messages.update(selector, newentry, UpdateFlags.None);
    } else if(Type.stringof == "YoutubeEntry"){
        db.youtube.update(selector, newentry, UpdateFlags.None);
    } else if(Type.stringof == "YoutubeCredentials"){
        db.youtubeCredentials.update(selector, newentry, UpdateFlags.None);
    } else{
        static assert(false, "Error: " ~ Type.stringof ~ " is not supported");
    }
}
/**
	Updates the chartentry with ID = oldID with the new chart entry

	Sample code to use
	// get the latest chart
	auto bbcTop40Chart = db.getLatestChart("BBC Top 40");
	bbcTop40Chart.songs ~= SongEntry(
			"ele[1].innerHTML",
			"ele[0].innerHTML",
			"NEW UTOOB ID",
			140,
			["BBC Top 40", "pop"]
			);

	db.update(bbcTop40Chart.name, bbcTop40Chart.date, bbcTop40Chart);
	TODO: NEED TO TEST
*/

/**
 Gets a ChartEntry[] containing all the ChartEntries in the DB
*/
public ChartEntry[] getAllCharts(ChartzoneDB db){
	logDebug("Getting all charts...");
	ChartEntry[] charts;
	auto cursor = db._charts_coll.find().sort(["date" : -1]); // get all the chart entries
	foreach(doc; cursor){
		ChartEntry chart;
		chart.deserializeBson(doc);
		charts ~= chart;
	}
	logDebug("Returning %s charts", charts.length);
	return charts;
}

public ChartEntry[] getLatestCharts(ChartzoneDB db){
	logDebug("Getting latest charts...");
	ChartEntry[] charts;
    foreach(type; chartTypes){
		try{
			charts ~= db.getLatestChart(type);
		} catch(NoEntryForChartException e){
			logInfo("Caught exception looking for chart: " ~ type ~ ". Moving on....");
			logDebug(e.msg);
			// no entry for that chart. Moving on
			continue;
		}
    }
    if(charts.length == 0){
		logError("No charts in DB");
    	throw new DBSearchException("Error finding charts");
	}
    else{
		logDebug("Returning %s charts", charts.length);
		return charts;
	}
}


public ChartEntry getLatestChart(ChartzoneDB db, string chartName){
	logDebug("Getting latest chart: %s", chartName);
	ChartEntry chart;
	auto cursor = db._charts_coll.find(["name" : chartName]).sort(["date" : -1]);
	if(cursor.empty){
		logError("Chart %s not in DB", chartName);
		throw new NoEntryForChartException("Nothing for chart %s was found in DB".format(chartName));
	}
	deserializeBson(chart, cursor.front);
	logDebug("Returning chart", chartName);
	return chart;
}


/**
	Data structure that holds a SongEntry in the DB
*/
public struct SongEntry {
	string songname;
	string artist;
	string[] youtubeIds;
	string[] youtubeImages;
	uint position;
	string[] genres;
	string[] soundcloudUrls;
	string[] soundcloudImages;

	@property setYoutubeIds(Json obj){
		foreach(item; obj.items){
			try{
				this.youtubeIds ~= item.id.videoId.to!string;
			}
			catch(Exception e){
				this.youtubeIds ~= "unknown-id";
			}
		}
	}

	@property setYoutubeIdsEmpty(){
		this.youtubeIds ~= "unknown-id";
	}

	@property setYoutubeImages(Json obj){
		foreach(item; obj.items){
			try{
				this.youtubeImages ~= item.snippet.thumbnails["default"].url.to!string;
			}
			catch(Exception e){
				this.youtubeImages ~= "unknown-url";
			}
		}
	}

	@property setYoutubeImagesEmpty(){
		this.youtubeImages ~= "unknown-url";
	}

	@property setSoundcloudUrls(Json[] objs){
		for(uint i = 0; i<objs.length; i++){
			try{
				this.soundcloudUrls ~= objs[i].uri.to!string;
			}
			catch(Exception e){
				this.soundcloudUrls ~= "unknown-url";
			}
		}
	}

	@property setSoundcloudUrlsEmpty(){
		this.soundcloudUrls ~= "unknown-url";
	}

	@property setSoundcloudImages(Json[] objs){
		if(objs.length)
		for(uint i = 0; i<objs.length; i++){
			try{
				if(objs[i].artwork_url.to!string != "null")
					this.soundcloudImages ~= objs[i].artwork_url.to!string;
				else
					this.soundcloudImages ~= "unknown-url";
			}
			catch(Exception e){
				this.soundcloudImages ~= "unknown-url";
			}
		}
	}

	@property setSoundcloudImagesEmpty(){
		this.soundcloudImages ~= "unknown-url";
	}

}

/**
	Data structure that holds a GenreEntry in the DB
*/
public struct GenreEntry{
	string genre;
}

/**
	Data structure that holds information on a chart in the DB
*/
public struct ChartEntry {
	string name;
	string country="global";
	long date;
	string playListId;
	SongEntry[] songs;

	/**
		Constructs the chart entry using the current system date/time as the date
	*/
	public this(string name, string country, string playListId, SongEntry[] songs){
		import std.datetime;
		this.name = name;
		this.country = country;
		this.date = Clock.currStdTime();
		this.songs = songs;
		this.playListId = playListId;
	}
}

/**
 * Data structure that holds message information from a user in DB
 * */
public struct MessageEntry {
	string name;
	string email;
	long date;
	string message;

	public this(string name, string email, string message){
		this.name = name;
		this.email = email;
		this.message = message;
		this.date = Clock.currStdTime();
	}
}

public class DBSearchException : Exception{
	this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
		super(message, file, line, next);
	}
}

public class NoEntryForChartException : Exception{
	this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
		super(message, file, line, next);
	}
}
