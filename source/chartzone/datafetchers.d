/**
	Module that contains functions to go to websites and collect chart information
*/

module chartzone.datafetchers;

import vibe.vibe;
import arsd.dom;

import chartzone.db : ChartEntry,GenreEntry,SongEntry;
import chartzone.youtube;
import chartzone.utils;

import std.regex;
import std.stdio;
import std.range;
import std.uri;
import std.algorithm;
import std.utf;

/+
  The code below sets up the module.
 +/

/**
 * A hash of ChartNames to functionPointers
 * */
public ChartEntry function()[string] chartGetters;
/// Used for identifying all valid charts. Is set to the keys of chartGetters.
string[] chartTypes;

string mapFuncNamesToAA(string funcId){
        auto funNames = [__traits(allMembers, chartzone.datafetchers)]
            .filter!(a => a.startsWith(funcId))
            .map!(a => "\"" ~ a[funcId.length..$] ~ "\":&" ~ a[0..$])
            .joiner(",");
        string toRet;
        foreach(f; funNames){
            toRet ~= f;
        }
        return toRet;
}


shared static this(){
    mixin("chartGetters = [" ~ mapFuncNamesToAA("getChart_") ~ "];");
    chartTypes = chartGetters.keys;
	logInfo("After setting up datafetchers.d module. Available ChartGetter function names: %s", chartTypes);
}


/**
	Exception for Chartzone data fetchers.
*/
public class ChartFetcherException : Exception{
	this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
		super(message, file, line, next);
	}
}

/+ All Chart Getter functions from here on.
    NOTE: All ChartGetter functions should have the identity:
        ChartEntry getChart_XYZ();
    where XYZ is the name of the chart.
+/


/**
	Goes to the BBC radio1 chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.
*/
public ChartEntry getChart_BBCTop40(){
	logInfo("In datafetchers.d getBBCTOP40");
	// read from BBC
	string url = "http://www.bbc.co.uk/radio1/chart/singles";
	string bbcTop40 = getDataFromURL(url);

	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		logInfo("Invalid info from %s", url);
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from " ~ url);
	}
	if(artistListing.length != trackListing.length){
		logInfo("Invalid info from %s", url);
		throw new ChartFetcherException("Error parsing information from " ~ url);
	}

	SongEntry[] songs;
	string nameToSearch;
	string videoId;
	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){
	
		//Add song to playlist
		//addVideoToPlaylist(playListId, videoId);
		songs ~= SongEntry(
			ele[1].innerHTML.htmlEntitiesDecode,
			ele[0].innerHTML.htmlEntitiesDecode,
			"unknown-id",
			i++,
			["BBCTop40", "pop"]
			);
	}

	return ChartEntry(
			"BBCTop40", "uk", "none",  songs
		);

}

/**
	Goes to the BBC radio1 dance chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.
*/
public ChartEntry getChart_BBCTop40Dance(){
	// read from BBC
	string bbcTop40 = getDataFromURL("http://www.bbc.co.uk/radio1/chart/dancesingles");



	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from http://www.bbc.co.uk/radio1/chart/dancesingles");
	}
	if(artistListing.length != trackListing.length){
		throw new ChartFetcherException("Error parsing information from http://www.bbc.co.uk/radio1/chart/dancesingles");
	}



	SongEntry[] songs;
	string nameToSearch;
	string videoId;

	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){

		songs ~= SongEntry(
			ele[1].innerHTML.htmlEntitiesDecode,
			ele[0].innerHTML.htmlEntitiesDecode,
			"unknown-id",
			i++,
			["BBCTop40Dance", "Dance"]
			);
	}
	return ChartEntry(
		"BBCTop40Dance", "uk", "none",  songs
		);
}


/**
	Gets the top 100 off billboard hot 100, and parses it to generate a ChartEntry object.

	Sample string that it parses
	/+
	<div class="listing chart_listing">
		<article class="song_review no_category chart_albumTrack_detail no_divider" id="node-1">
			<a id="rank_1"></a>
			<header>
				<span class="chart_position position-up position-greatest-gains">1</span>
				<h1>Fancy        </h1>
				<p class="chart_info">
					<a title="Iggy Azalea Featuring Charli XCX" href="/artist/5694588/iggy-azalea">Iggy Azalea Featuring Charli XCX</a>        <br />
		</p> . . . etc etc
     +/
*/
public ChartEntry getChart_BillboardTop100(){

	string[] urls;
	urls ~= "http://www.billboard.com/charts/hot-100";
	foreach(i; 1..10){ // create the URLs we're going to use
		urls ~= format("%s?page=%s", urls[0], i);
	}

	//Create Playlist and get playlist Id
	string playListId = "temp"; //createPlaylist("Billboard Top 100".getChartTitleDate());

	SongEntry[] songs;
	string nameToSearch;
	string videoId;

	foreach(url; urls){
		string billboardStr = getDataFromURL(url);

		Document htmlObj = new Document();
		htmlObj.parse(billboardStr);
		auto chartListing = htmlObj.getElementsBySelector(`div[class="listing chart_listing"]`);
		assert(chartListing.length==1,
			"Error parsing response from Billboard 100. Error: couldnt find <div class=\"listing chart_listing\">");

		foreach(songEntry; chartListing[0].getElementsByTagName(`article`)){
			string position = songEntry
				.getElementsByTagName(`a`)[0] // the first <a is the position
				.getAttribute("id")
				.strip()	//remove any pre and post whitespace
				.replace("rank_", "");

			string artist = songEntry
				.getElementsByTagName(`a`)[1] // the second <a> is the artist
				.getAttribute("title")
				.strip();

			string songTitle = songEntry
				.getElementsByTagName(`h1`)[0] // the first h1 is the song title
				.innerHTML()
				.chomp();

			// append a new song object to songs[]
			songs ~= SongEntry(
					songTitle.htmlEntitiesDecode,
					artist.htmlEntitiesDecode,
					"unknown-id",
					position.to!uint,
				["BillboardTop100", "pop"]
				);
		}
	}

	return ChartEntry("BillboardTop100", "usa", "none",  songs);

}

/**
	Gets the iTunes Top 100 and puts it into a chart entry object
*/

public ChartEntry getChart_ItunesTop100(){

    string iTunesTop100 = getDataFromURL("http://www.apple.com/itunes/charts/songs/");

    //Replace all img tags as some are badly formed on Apple site
    auto imgRegex = ctRegex!(r"(<img[^>]+\>)","igm");
    iTunesTop100 = replaceAll(iTunesTop100, imgRegex, "");

    Document htmlObj = new Document();
	htmlObj.parse(iTunesTop100);
	auto chartListing = htmlObj.getElementsByTagName(`ul`);
	assert(chartListing.length >= 1,
			"Error parsing response from iTunes Top 100. Error: couldnt find at least one ul tag");
	       
	SongEntry[] songs;
	string nameToSearch;
	string videoId;
    uint i = 0;
    //second ul is the list
    foreach(songEntry; chartListing[3].getElementsByTagName(`li`)){
    	string songTitle = "", artist = "";
    	songTitle = songEntry.getElementsByTagName(`h3`)[0].getElementsByTagName(`a`)[0].innerText();
    	artist = songEntry.getElementsByTagName(`h4`)[0].getElementsByTagName(`a`)[0].innerText();

    	if(songTitle != "" && artist != ""){
            songs ~= SongEntry(
					songTitle.htmlEntitiesDecode,
					artist.htmlEntitiesDecode,
					"unknown-id",
					i++,
					["ItunesTop100", "pop"]
				);
         }
    }
	return ChartEntry("ItunesTop100", "global", "none",  songs);

}

public string getDataFromURL(string url){
	return requestHTTP(url,
			(scope req){}
		).bodyReader.readAllUTF8();
}


