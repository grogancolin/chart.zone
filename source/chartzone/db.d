/**
Module to interface with the DB.
*/
module chartzone.db;

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
	Updates the chartentry with ID = oldID with the new chartentry
	TODO: NEED TO TEST
*/
public void update(ChartzoneDB db, string oldID, ChartEntry newentry){
	// should update the entry with oldID to be the new entry
	db.collection.update(["ObjectID" : oldID], newentry, UpdateFlags.None); 
}

/**
	Data structure that holds a SongEntry in the DB
*/
public struct SongEntry {
	string songname;
	string artist;
	string youtubeid;
	uint position;
	GenreEntry[] genres;
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
	string date;
	SongEntry[] songs;

	/**
		Constructs the chart entry using the current system date/time as the date
	*/
	public this(string name, SongEntry[] songs){
		import std.datetime;
		this(name, Clock.currTime().toSimpleString(), songs);
	}

	/**
		Constructs the chart entry using the entered values
	*/
	public this(string name, string date, SongEntry[] songs){
		this.name = name;
		this.songs = songs;
		this.date = date;
	}
}