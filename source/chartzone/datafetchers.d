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
			ele[1].innerHTML.htmlEntitiesDecode.removeExtraSpaces,
			getArtistName(ele[0]),
			[],//Youtube ids
			[],//Youtube img urls
			i++,
			["BBCTop40", "Pop"],
			[],//soundcloud ids
			[]//soundcloud image urls
			);
	}

	return ChartEntry(
			"BBCTop40", "uk", "none",  songs
		);

}

public ChartEntry getChart_BBCTop40Indie() {
	// read from BBC
	string url = "http://www.bbc.co.uk/radio1/chart/indiesingles";
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
		ele[1].innerHTML.htmlEntitiesDecode.removeExtraSpaces,
		getArtistName(ele[0]),
		[],//Youtube ids
		[],//Youtube img urls
		i++,
		["BBCTop40Indie", "Indie"],
		[],//soundcloud ids
		[]//soundcloud image urls
		);
	}

	return ChartEntry(
		"BBCTop40Indie", "uk", "none",  songs
		);

}

/**
	Goes to the BBC radio1 dance chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.
*/
public ChartEntry getChart_BBCTop40Dance(){
	string url = "http://www.bbc.co.uk/radio1/chart/dancesingles";
	// read from BBC
	string bbcTop40 = getDataFromURL(url);

	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from "~ url);
	}
	if(artistListing.length != trackListing.length){
		throw new ChartFetcherException("Error parsing information from http://www.bbc.co.uk/radio1/chart/dancesingles");
	}



	SongEntry[] songs;

	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){

		songs ~= SongEntry(
			ele[1].innerHTML.htmlEntitiesDecode.removeExtraSpaces,
			getArtistName(ele[0]),
			[],//Youtube ids
			[],//Youtube img urls
			i++,
			["BBCTop40Dance", "Dance"],
			[],//soundcloud ids
			[]//soundcloud image urls
			);
	}
	return ChartEntry(
		"BBCTop40Dance", "uk", "none",  songs
		);
}

public ChartEntry getChart_BBCTop40Rock(){
	string url = "http://www.bbc.co.uk/radio1/chart/rocksingles";
	// read from BBC
	string bbcTop40 = getDataFromURL(url);

	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from " ~ url);
	}
	if(artistListing.length != trackListing.length){
		throw new ChartFetcherException("Error parsing information from " ~ url);
	}

	SongEntry[] songs;

	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){

		songs ~= SongEntry(
		ele[1].innerHTML.htmlEntitiesDecode.removeExtraSpaces,
		getArtistName(ele[0]),
		[],//Youtube ids
		[],//Youtube img urls
		i++,
		["BBCTop40Rock", "Rock"],
		[],//soundcloud ids
		[]//soundcloud image urls
		);
	}
	return ChartEntry(
		"BBCTop40Rock", "uk", "none",  songs
		);
}



public ChartEntry getChart_BillboardTop25Rock(){
	string[] urls;
	urls ~= "http://www.billboard.com/charts/rock-songs";
	foreach(i; 1..3){ // create the URLs we're going to use
		urls ~= format("%s?page=%s", urls[0], i);
	}

	SongEntry[] songs;

	foreach(url; urls){

		string billboardStr = getDataFromURL(url);

		Document htmlObj = new Document();
		htmlObj.parse(billboardStr);
		auto chartListing = htmlObj.getElementsBySelector(`div[class="listing chart_listing"]`);
		if(chartListing.length != 1)
			throw new ChartFetcherException("Error parsing response from BillboardTop25Rock. Error: couldnt find <div class=\"listing chart_listing\">");

		foreach(songEntry; chartListing[0].getElementsByTagName(`article`)){
			string position = songEntry
				.getElementsByTagName(`a`)[0] // the first <a is the position
				.getAttribute("id")
				.strip()//remove any pre and post whitespace
				.replace("rank_", "");


			string artist = songEntry
				.getElementsByTagName(`a`)[1] // the second <a> is the artist
				.getAttribute("title")
				.strip();

			//Sometimes the artist name isn't in an a link so do this instead
			if(artist == ""){
				artist = songEntry
					.getElementsByTagName(`p`)[0]
					.innerText // the first p but it may include some
					.strip();
					logInfo("ARTIST NAME: %s", artist);
			}

			string songTitle = songEntry
				.getElementsByTagName(`h1`)[0] // the first h1 is the song title
				.innerHTML()
				.chomp();

			// append a new song object to songs[]
			songs ~= SongEntry(
				songTitle.htmlEntitiesDecode.removeExtraSpaces,
				artist.htmlEntitiesDecode.removeExtraSpaces,
				[],//Youtube ids
				[],//Youtube img urls
				position.to!uint,
				["BillboardTop25Rock", "Rock"],
				[],//soundcloud ids
				[]//soundcloud image urls
			);
		}
	}
	return ChartEntry("BillboardTop25Rock", "usa", "none",  songs);
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

	SongEntry[] songs;

	foreach(url; urls){
		string billboardStr = getDataFromURL(url);

		Document htmlObj = new Document();
		htmlObj.parse(billboardStr);
		auto chartListing = htmlObj.getElementsBySelector(`div[class="listing chart_listing"]`);
		if(chartListing.length != 1)
			throw new ChartFetcherException("Error parsing response from BillboardTop100. Error: couldnt find <div class=\"listing chart_listing\">");

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

			//Sometimes the artist name isn't in an a link so do this instead
			if(artist == ""){
				artist = songEntry
					.getElementsByTagName(`p`)[0]
					.innerText // the first p but it may include some
					.strip();
					logInfo("ARTIST NAME: %s", artist);
			}

			string songTitle = songEntry
				.getElementsByTagName(`h1`)[0] // the first h1 is the song title
				.innerHTML()
				.chomp();

			// append a new song object to songs[]
			songs ~= SongEntry(
					songTitle.htmlEntitiesDecode.removeExtraSpaces,
					artist.htmlEntitiesDecode.removeExtraSpaces,
					[],//Youtube ids
					[],//Youtube img urls
					position.to!uint,
				["BillboardTop100", "Pop"],
				[],//soundcloud ids
				[]//soundcloud image urls
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
	if(chartListing.length == 0)
		throw new ChartFetcherException("Error parsing response from iTunesTop100. Error: couldnt find at least one ul tag");

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
					songTitle.htmlEntitiesDecode.removeExtraSpaces,
					artist.htmlEntitiesDecode.removeExtraSpaces,
					[],//Youtube ids
					[],//Youtube img urls
					i++,
					["ItunesTop100", "Pop"],
					[],//soundcloud ids
					[]//soundcloud image urls
				);
         }
    }
	return ChartEntry("ItunesTop100", "global", "none",  songs);

}


/**
	Gets the Irish Top 100 singles chart and puts it into a chart entry object
*/

public ChartEntry getChart_IrishTop100(){
	//If you get an error check this out!!!
	//This might change not sure the ASP site thing wasn't working
    //string irishTop100 = cast(string) getDataFromURL("http://www.chart-track.co.uk/index.jsp?c=p/musicvideo/music/latest/index_test.jsp&ct=240001").filter!(a=> a < 128).array;
    ubyte[] data = requestHTTP("http://www.chart-track.co.uk/index.jsp?c=p/musicvideo/music/latest/index_test.jsp&ct=240001",
			(scope req){}
		).bodyReader.readAll().filter!(a => a < 128).array;

    string irishTop100 = cast(string)data;
    Document htmlObj = new Document();
	htmlObj.parse(irishTop100.htmlEntitiesDecode);
	auto chartListing = htmlObj.getElementsByTagName(`table`);
	if(chartListing.length < 1)
			throw new ChartFetcherException("Error parsing response from Irish Top 100. Error: couldnt find at least one tbody tag");

	SongEntry[] songs;
    uint i = 1;
    //Skip the first iteration as that just has column headers
    bool isFirst = true;
    foreach(songEntry; chartListing[3].getElementsByTagName(`tr`)){
    	if(isFirst){
    		isFirst = false;
    		continue;
    	}
    	string songTitle = "", artist = "";
    	songTitle = songEntry.getElementsByTagName(`td`)[5].innerText();
    	artist = songEntry.getElementsByTagName(`td`)[6].innerText();

    	if(songTitle != "" && artist != ""){
            songs ~= SongEntry(
					songTitle.htmlEntitiesDecode.removeExtraSpaces,
					artist.htmlEntitiesDecode.removeExtraSpaces,
					[],//Youtube ids
					[],//Youtube img urls
					i++,
					["IrishTop100", "pop"],
					[],//soundcloud ids
					[]//soundcloud image urls
				);
         }
    }
	return ChartEntry("IrishTop100", "ireland", "none",  songs);

}

/* Utilities for data scraping */

/**
 * Gets the web page from url
 */
public string getDataFromURL(string url){
	return requestHTTP(url,
			(scope req){}
		).bodyReader.readAllUTF8();
}

//Sometime there is no <a> tag so need to get artist name from just the div
/**
 * Strips out an <a> tag in some charts
 * */
private string getArtistName(Element artistHtml){
	
	auto artistNames = artistHtml.getElementsByTagName(`a`);
	
	return artistNames.length > 0 ? 
	artistNames[0].innerHTML.htmlEntitiesDecode.removeExtraSpaces.chomp.strip :
	artistHtml.innerHTML.htmlEntitiesDecode.removeExtraSpaces;
}