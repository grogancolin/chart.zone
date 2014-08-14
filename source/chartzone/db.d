/**
Module to interface with the DB.
*/
module chartzone.db;

import std.stdio;

import chartzone.datafetchers;

import vibe.vibe;
/**
	Handles the connections to chartzoneDB on mongo
*/
public class ChartzoneDB{
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

/*
	Adds a chart entry to the database
	// Call with db.add(chartEntry);
*/
public void add(ChartzoneDB db, ChartEntry entry){
	db.collection.insert(entry);
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
public void update(ChartzoneDB db, ChartEntry oldentry, ChartEntry newentry){
	// should update the entry with oldID to be the new entry
	db.collection.update(["name" : Bson(oldentry.name), "date" : Bson(oldentry.date)], newentry, UpdateFlags.None);
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
public void update(ChartzoneDB db, string oldName, ulong oldTimestamp, ChartEntry newentry){
	// should update the entry with oldID to be the new entry
	db.collection.update(["name" : Bson(oldName), "date" : Bson(oldTimestamp)], newentry, UpdateFlags.None);
}


/**
 Gets a ChartEntry[] containing all the ChartEntries in the DB
*/
public ChartEntry[] getAllCharts(ChartzoneDB db){
	ChartEntry[] charts;
	auto cursor = db.collection.find().sort(["date" : -1]); // get all the chart entries
	foreach(doc; cursor){
		ChartEntry chart;
		chart.deserializeBson(doc);
		charts ~= chart;
	}
	return charts;
}

public ChartEntry[] getLatestCharts(ChartzoneDB db){

	ChartEntry[] charts;
    foreach(type; chartTypes){
		try{
			charts ~= db.getLatestChart(type);
		} catch(NoEntryForChartException e){
			logInfo(e.msg);
			// no entry for that chart. Moving on
			continue;
		}
    }
    if(charts.length == 0)
    	throw new DBSearchException("Error finding charts");
    else
		return charts;
}


public ChartEntry getLatestChart(ChartzoneDB db, string chartName){
	ChartEntry chart;
	auto cursor = db.collection.find(["name" : chartName]).sort(["date" : -1]);
	if(cursor.empty) 
		throw new NoEntryForChartException("Nothing for chart %s was found in DB".format(chartName));
	deserializeBson(chart, cursor.front);
	return chart;
}


/**
	Data structure that holds a SongEntry in the DB
*/
public struct SongEntry {
	string songname;
	string artist;
	string youtubeid;
	uint position;
	string[] genres;
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
	string country;
	long date;
	SongEntry[] songs;

	/**
		Constructs the chart entry using the current system date/time as the date
	*/
	public this(string name, SongEntry[] songs){
		import std.datetime;
		this(name, Clock.currStdTime(), songs);
	}

	/**
		Constructs the chart entry using the entered values
	*/
	public this(string name, long date, SongEntry[] songs){
		this.name = name;
		this.songs = songs;
		this.date = date;
	}
	/**
		Constructs the chart entry using the entered values
	*/
	public this(string name, long date, string country, SongEntry[] songs){
		this.name = name;
		this.songs = songs;
		this.country = country;
		this.date = date;
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